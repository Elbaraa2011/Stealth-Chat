import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import 'models.dart';
import 'supabase_client.dart';

/// Looks up other stealth users by username so the DM screen can add them.
///
/// This is the "add other users using username" path: type a handle into the
/// DM search box, [findByUsername] resolves it to a real [StealthUser] row.
class UsersService {
  UsersService._();
  static final UsersService instance = UsersService._();

  final SupabaseClient _supabase = SupabaseClient.instance;

  /// Return the user registered under [handle], or null if nobody has it.
  Future<StealthUser?> findByUsername(String handle) async {
    final String normalized = normalizeUsername(handle);
    if (normalized.isEmpty || !_supabase.isConfigured) return null;

    final Map<String, dynamic>? row = await _supabase
        .from('users')
        .select()
        .ilike('username', normalized)
        .maybeSingle();
    if (row == null) return null;
    return StealthUser.fromMap(row);
  }

  /// Whether [handle] is already claimed.
  Future<bool> usernameExists(String handle) async {
    final String normalized = normalizeUsername(handle);
    if (normalized.isEmpty || !_supabase.isConfigured) return false;
    final List<Map<String, dynamic>> rows = await _supabase
        .from('users')
        .select('id')
        .ilike('username', normalized)
        .limit(1);
    return rows.isNotEmpty;
  }

  /// Prefix search for the "add user" picker.
  Future<List<StealthUser>> searchUsernames(String query, {int limit = 20}) async {
    final String normalized = normalizeUsername(query);
    if (!_supabase.isConfigured) return const <StealthUser>[];
    final String me = _supabase.userId ?? '';

    dynamic request = _supabase.from('users').select();
    if (normalized.isNotEmpty) {
      request = request.ilike('username', '$normalized%');
    }
    final List<Map<String, dynamic>> rows =
        await request.order('username', ascending: true).limit(limit);

    return rows
        .where((Map<String, dynamic> row) => row['id'] != me)
        .map(StealthUser.fromMap)
        .toList();
  }

  /// Claim [handle] for the signed-in user (used when changing the username).
  Future<StealthUser> claimUsername(String handle) async {
    final String normalized = normalizeUsername(handle);
    if (!isValidUsername(normalized)) {
      throw const FormatException(
        'Usernames are 3-24 characters, letters, numbers, dot or underscore',
      );
    }
    final String? id = _supabase.userId;
    if (id == null) throw StateError('Not signed in');
    if (await usernameExists(normalized)) {
      throw StateError('That username is already taken');
    }

    try {
      final Map<String, dynamic> row = await _supabase
          .from('users')
          .update(<String, dynamic>{'username': normalized})
          .eq('id', id)
          .select()
          .single();
      return StealthUser.fromMap(row);
    } on sb.PostgrestException catch (error) {
      throw StateError(error.message);
    }
  }
}

/// Lower-case, trim and strip one leading `@`.
String normalizeUsername(String raw) {
  String value = raw.trim().toLowerCase();
  while (value.startsWith('@')) {
    value = value.substring(1);
  }
  return value;
}

final RegExp _usernamePattern = RegExp(r'^[a-z0-9._]{3,24}$');

bool isValidUsername(String handle) => _usernamePattern.hasMatch(handle);
