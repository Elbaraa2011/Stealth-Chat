import 'models.dart';

/// One message in a stealth DM conversation.
///
/// Stored in the `dm_messages` table; the public `fromUsername` / `toUsername`
/// columns make queries cheap and let the UI show the recipient without a join
/// on every row.
///
/// A row carries either text in [body], an attachment in [mediaUrl], or both.
/// [mediaType] is `image` or `voice`; [durationMs] is only set for voice notes.
class DmMessage {
  DmMessage({
    required this.id,
    required this.fromUsername,
    required this.toUsername,
    required this.body,
    required this.sentAt,
    this.read = false,
    this.mediaUrl,
    this.mediaType,
    this.durationMs,
  });

  final String id;
  final String fromUsername;
  final String toUsername;
  final String body;
  final DateTime sentAt;
  final bool read;

  /// Public URL of the attachment in the `dm-media` bucket, if any.
  final String? mediaUrl;

  /// `image` or `voice`; null for a text-only message.
  final String? mediaType;

  /// Length of a voice note in milliseconds.
  final int? durationMs;

  bool get hasMedia => (mediaUrl ?? '').isNotEmpty;

  bool get isImage => hasMedia && mediaType == 'image';

  bool get isVoice => hasMedia && mediaType == 'voice';

  Duration get voiceLength => Duration(milliseconds: durationMs ?? 0);

  factory DmMessage.fromMap(Map<String, dynamic> map) {
    final String? url = (map['media_url'] as String?)?.trim();
    return DmMessage(
      id: map['id'] as String,
      fromUsername: (map['from_username'] as String?) ?? '',
      toUsername: (map['to_username'] as String?) ?? '',
      body: (map['body'] as String?) ?? '',
      sentAt: DateTime.tryParse((map['created_at'] as String?) ?? '')
              ?.toLocal() ??
          DateTime.now(),
      read: (map['read'] as bool?) ?? false,
      mediaUrl: (url == null || url.isEmpty) ? null : url,
      mediaType: (map['media_type'] as String?) ??
          ((url == null || url.isEmpty) ? null : 'image'),
      durationMs: (map['duration_ms'] as num?)?.toInt(),
    );
  }

  StealthUser? _fromUser;
  StealthUser? get fromUser => _fromUser;
}

/// `mm:ss` for a voice note length.
String formatDuration(Duration duration) {
  final int totalSeconds = duration.inSeconds;
  final int minutes = totalSeconds ~/ 60;
  final String seconds = (totalSeconds % 60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}
