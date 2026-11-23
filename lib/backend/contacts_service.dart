import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import 'models.dart';
import 'supabase_client.dart';

/// The signed-in user's friend list — the people the Messages tab shows.
///
/// Each row in `dm_contacts` is one direction of the relationship: when you add
/// @someone they appear in your list, and they can add you back to see you in
/// theirs. Nothing here is mocked; every name comes from `public.users`.
class ContactsService {
  ContactsService._();
  static final ContactsService instance = ContactsService._();

  final SupabaseClient _supabase = SupabaseClient.instance;

  /// Everyone the signed-in user added, newest first.
  Future<List<StealthUser>> myContacts() async {
    if (!_supabase.isConfigured || !_supabase.isSignedIn) {
      return const <StealthUser>[];
    }
    final String me = _supabase.userId!;

    final List<Map<String, dynamic>> rows = await _supabase
        .from('dm_contacts')
        .select('contact_id')
        .eq('owner_id', me)
        .order('created_at', ascending: false);
    if (rows.isEmpty) return const <StealthUser>[];

    final List<String> ids = rows
        .map((Map<String, dynamic> row) => row['contact_id'] as String)
        .toList();

    final List<Map<String, dynamic>> profiles = await _supabase
        .from('users')
        .select()
        .inFilter('id', ids);
    final Map<String, StealthUser> byId = <String, StealthUser>{
      for (final Map<String, dynamic> row in profiles)
        row['id'] as String: StealthUser.fromMap(row),
    };

    return <StealthUser>[
      for (final String id in ids)
        if (byId[id] != null) byId[id]!,
    ];
  }

  /// Ids of the users already in [myContacts], for filtering search results.
  Future<Set<String>> contactIds() async {
    if (!_supabase.isConfigured || !_supabase.isSignedIn) return <String>{};
    final List<Map<String, dynamic>> rows = await _supabase
        .from('dm_contacts')
        .select('contact_id')
        .eq('owner_id', _supabase.userId!);
    return rows
        .map((Map<String, dynamic> row) => row['contact_id'] as String)
        .toSet();
  }

  /// Add [user] to the friend list. Adding twice is a no-op.
  Future<void> add(StealthUser user) async {
    final String? me = _supabase.userId;
    if (me == null) throw StateError('Sign in before adding friends');
    if (user.id == me) throw StateError('You cannot add yourself');

    try {
      await _supabase.from('dm_contacts').upsert(
        <String, dynamic>{'owner_id': me, 'contact_id': user.id},
        onConflict: 'owner_id,contact_id',
        ignoreDuplicates: true,
      );
    } on sb.PostgrestException catch (error) {
      throw StateError(error.message);
    }
  }

  /// Drop [user] from the friend list. The message history is left intact.
  Future<void> remove(StealthUser user) async {
    final String? me = _supabase.userId;
    if (me == null) return;
    await _supabase
        .from('dm_contacts')
        .delete()
        .eq('owner_id', me)
        .eq('contact_id', user.id);
  }
}
