import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import 'dm_message.dart';
import 'models.dart';
import 'supabase_client.dart';
import 'users_service.dart';

/// Sends and reads stealth DMs between registered users.
///
/// Every send writes a `dm_messages` row; every read goes through here, so
/// marking a thread read happens in one place. Row level security on the table
/// means a user can only ever see messages they sent or received.
class MessagesService {
  MessagesService._();
  static final MessagesService instance = MessagesService._();

  final SupabaseClient _supabase = SupabaseClient.instance;

  /// Send a message to [targetUsername].
  ///
  /// The row needs text, an attachment, or both. [mediaType] is `image` or
  /// `voice` and [durationMs] is the length of a voice note.
  Future<DmMessage> sendDm({
    required String targetUsername,
    String body = '',
    String? mediaUrl,
    String? mediaType,
    int? durationMs,
    StealthUser? from,
  }) async {
    final String text = body.trim();
    if (text.isEmpty && (mediaUrl ?? '').isEmpty) {
      throw ArgumentError('Message needs text or an attachment');
    }
    if (!_supabase.isConfigured) {
      throw StateError('Supabase is not configured yet');
    }

    final String me = _supabase.userId ??
        (throw StateError('Sign in before sending messages'));
    final StealthUser sender = from ?? _me();

    final String handle = normalizeUsername(targetUsername);
    final StealthUser? recipient =
        await UsersService.instance.findByUsername(handle);
    if (recipient == null) {
      throw StateError('No stealth user is registered as @$handle');
    }
    if (recipient.id == me) {
      throw StateError('You cannot message yourself');
    }

    final Map<String, dynamic> row = await _supabase
        .from('dm_messages')
        .insert(<String, dynamic>{
          'from_id': me,
          'from_username': sender.username,
          'to_id': recipient.id,
          'to_username': recipient.username,
          'body': text,
          if ((mediaUrl ?? '').isNotEmpty) 'media_url': mediaUrl,
          if ((mediaType ?? '').isNotEmpty) 'media_type': mediaType,
          if (durationMs != null) 'duration_ms': durationMs,
        })
        .select()
        .single();

    return DmMessage.fromMap(row);
  }

  /// The full thread with [otherUsername], oldest first.
  Future<List<DmMessage>> threadWith(String otherUsername) async {
    final String handle = normalizeUsername(otherUsername);
    if (!_supabase.isConfigured || !_supabase.isSignedIn) {
      return const <DmMessage>[];
    }
    final String me = _supabase.userId ?? '';

    final List<Map<String, dynamic>> rows = await _supabase
        .from('dm_messages')
        .select()
        .or('and(from_id.eq.$me,to_username.eq.$handle),'
            'and(to_id.eq.$me,from_username.eq.$handle)')
        .order('created_at', ascending: true)
        .limit(500);

    return rows.map(DmMessage.fromMap).toList();
  }

  /// Every thread the signed-in user has messages in, most recent first.
  ///
  /// Peer profiles are resolved from `public.users` so the list shows real
  /// display names instead of raw handles.
  Future<List<DmConversation>> conversations() async {
    if (!_supabase.isConfigured || !_supabase.isSignedIn) {
      return const <DmConversation>[];
    }
    final String me = _supabase.userId ?? '';

    final List<Map<String, dynamic>> rows = await _supabase
        .from('dm_messages')
        .select()
        .or('from_id.eq.$me,to_id.eq.$me')
        .order('created_at', ascending: false)
        .limit(300);

    final Map<String, DmConversation> byPeer = <String, DmConversation>{};
    final Map<String, int> unread = <String, int>{};

    for (final Map<String, dynamic> row in rows) {
      final String fromId = row['from_id'] as String;
      final String toId = row['to_id'] as String;
      final bool mine = fromId == me;
      final String peerId = mine ? toId : fromId;
      final String peerHandle =
          ((mine ? row['to_username'] : row['from_username']) as String? ?? '');

      if (!mine && (row['read'] as bool? ?? false) == false) {
        unread[peerId] = (unread[peerId] ?? 0) + 1;
      }
      // Rows are newest first, so the first one seen per peer is the latest.
      byPeer.putIfAbsent(
        peerId,
        () => DmConversation(
          otherUser: StealthUser(
            id: peerId,
            username: peerHandle,
            displayName: peerHandle,
            registeredAt: DateTime.now(),
          ),
          latestMessage: DmMessage.fromMap(row),
          unreadCount: 0,
          age: '',
        ),
      );
    }

    final Map<String, StealthUser> profiles =
        await _profilesFor(byPeer.keys.toList());

    final List<DmConversation> out = byPeer.values.map((DmConversation c) {
      final StealthUser peer = profiles[c.otherUser.id] ?? c.otherUser;
      return DmConversation(
        otherUser: peer,
        latestMessage: c.latestMessage,
        unreadCount: unread[c.otherUser.id] ?? 0,
        age: formatAge(c.latestMessage.sentAt),
      );
    }).toList();

    out.sort((DmConversation a, DmConversation b) =>
        b.latestMessage.sentAt.compareTo(a.latestMessage.sentAt));
    return out;
  }

  Future<Map<String, StealthUser>> _profilesFor(List<String> ids) async {
    if (ids.isEmpty) return const <String, StealthUser>{};
    try {
      final List<Map<String, dynamic>> rows = await _supabase
          .from('users')
          .select()
          .inFilter('id', ids);
      return <String, StealthUser>{
        for (final Map<String, dynamic> row in rows)
          row['id'] as String: StealthUser.fromMap(row),
      };
    } on sb.PostgrestException {
      return const <String, StealthUser>{};
    }
  }

  /// Mark every message [otherUsername] sent me as read.
  Future<void> markRead({
    required String otherUsername,
    String? me,
  }) async {
    if (!_supabase.isConfigured) return;
    final String myId = me ?? _supabase.userId ?? '';
    final String handle = normalizeUsername(otherUsername);
    if (myId.isEmpty || handle.isEmpty) return;

    try {
      await _supabase
          .from('dm_messages')
          .update(<String, dynamic>{'read': true})
          .eq('to_id', myId)
          .eq('from_username', handle)
          .eq('read', false);
    } on sb.PostgrestException {
      // Nothing to mark read, or offline: not worth surfacing to the chat UI.
    }
  }

  StealthUser _me() {
    final StealthUser? user = _currentUserFallback();
    if (user != null) return user;
    throw StateError('Sign in before sending messages');
  }

  StealthUser? _currentUserFallback() {
    final sb.User? user = _supabase.currentUser;
    if (user == null) return null;
    final Map<String, dynamic> meta = user.userMetadata ?? <String, dynamic>{};
    return StealthUser(
      id: user.id,
      username: (meta['username'] as String?) ?? '',
      displayName: (meta['display_name'] as String?) ?? '',
      registeredAt: DateTime.now(),
    );
  }
}

/// One conversation thread for the DM list.
class DmConversation {
  const DmConversation({
    required this.otherUser,
    required this.latestMessage,
    required this.unreadCount,
    required this.age,
  });

  final StealthUser otherUser;
  final DmMessage latestMessage;
  final int unreadCount;
  final String age;
}

/// Short relative age for the thread list ("2m", "4h", "3d").
String formatAge(DateTime time) {
  final Duration delta = DateTime.now().difference(time);
  if (delta.inMinutes < 1) return 'now';
  if (delta.inMinutes < 60) return '${delta.inMinutes}m';
  if (delta.inHours < 24) return '${delta.inHours}h';
  if (delta.inDays < 7) return '${delta.inDays}d';
  return '${(delta.inDays / 7).floor()}w';
}

/// One-line preview for a thread row, including attachments.
String previewFor(DmMessage? message) {
  if (message == null) return 'Start a chat';
  if (message.isVoice) {
    return 'Voice message · ${formatDuration(message.voiceLength)}';
  }
  if (message.isImage) {
    return message.body.isEmpty ? 'Photo' : 'Photo · ${message.body}';
  }
  return message.body;
}
