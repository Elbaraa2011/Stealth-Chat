import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import 'models.dart';
import 'supabase_client.dart';
import 'users_service.dart';

/// Single auth facade the rest of the app talks to.
///
/// Login and sign-up share one screen and one profile row: whichever path the
/// user takes, [_upsertLocalUser] mirrors the auth user into `public.users` so
/// the DM layer always has a handle to send to.
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final SupabaseClient _supabase = SupabaseClient.instance;

  bool get isConfigured => _supabase.isConfigured;

  bool get isSignedIn => _supabase.isSignedIn;

  StealthUser? get currentUser {
    final sb.User? user = _supabase.currentUser;
    if (user == null) return null;
    final Map<String, dynamic> meta = user.userMetadata ?? <String, dynamic>{};
    final String fallbackHandle =
        'user_${user.id.replaceAll('-', '').substring(0, 8)}';
    return StealthUser(
      id: user.id,
      username: (meta['username'] as String?) ?? fallbackHandle,
      displayName: (meta['display_name'] as String?) ??
          (meta['full_name'] as String?) ??
          user.email?.split('@').first ??
          'User',
      avatar: (meta['avatar_url'] as String?) ?? '',
      registeredAt:
          DateTime.tryParse(user.createdAt)?.toLocal() ?? DateTime.now(),
    );
  }

  /// Sign in from the authorization card.
  ///
  /// [identifier] accepts either an email or a username — a username is
  /// resolved to its account email first.
  Future<StealthUser> signIn({
    required String identifier,
    required String password,
  }) async {
    if (!isConfigured) {
      throw StateError('Supabase is not configured yet');
    }
    final String trimmed = identifier.trim();
    String email = trimmed;
    if (!trimmed.contains('@')) {
      final String? resolved =
          await _supabase.emailForUsername(trimmed.toLowerCase());
      if (resolved == null) {
        throw const AuthFailure('No account uses that username');
      }
      email = resolved;
    }

    try {
      await _supabase.signInWithPassword(email: email, password: password);
    } on sb.AuthException catch (error) {
      throw AuthFailure(_messageFor(error));
    }
    return _upsertLocalUser();
  }

  /// Create an account from the authorization card.
  Future<StealthUser> signUp({
    required String email,
    required String password,
    required String username,
    String displayName = '',
  }) async {
    if (!isConfigured) {
      throw StateError('Supabase is not configured yet');
    }
    final String handle = normalizeUsername(username);
    if (!isValidUsername(handle)) {
      throw const AuthFailure(
        'Usernames are 3-24 characters, letters, numbers, dot or underscore',
      );
    }
    final bool taken = await UsersService.instance.usernameExists(handle);
    if (taken) {
      throw const AuthFailure('That username is already taken');
    }

    try {
      await _supabase.signUpWithPassword(
        email: email.trim(),
        password: password,
        username: handle,
        displayName: displayName.trim().isEmpty ? handle : displayName.trim(),
      );
    } on sb.AuthException catch (error) {
      throw AuthFailure(_messageFor(error));
    }

    if (!_supabase.isSignedIn) {
      // Project has "Confirm email" on: the account exists but there is no
      // session until the link is clicked.
      throw const AuthFailure(
        'Check your inbox to confirm the account, then log in',
      );
    }
    return _upsertLocalUser();
  }

  /// OAuth entry point for when an external provider is switched on in the
  /// Supabase dashboard.
  Future<void> signInWithProvider(sb.OAuthProvider provider) async {
    if (!isConfigured) {
      throw StateError('Supabase is not configured yet');
    }
    await _supabase.signInWithOAuth(provider);
  }

  /// Sign out and drop the session, returning the app to the splash.
  Future<void> signOut() async {
    if (!isConfigured) return;
    await _supabase.signOut();
  }

  /// Pull the `users` row for the signed-in account.
  ///
  /// Returns null when the row is missing (older account, or the trigger was
  /// added after the account was created).
  Future<StealthUser?> syncProfile() async {
    final sb.User? user = _supabase.currentUser;
    if (user == null || !isConfigured) return null;
    final Map<String, dynamic>? row = await _supabase
        .from('users')
        .select()
        .eq('id', user.id)
        .maybeSingle();
    if (row == null) return null;
    return StealthUser.fromMap(row);
  }

  /// Write / refresh the profile row for the signed-in auth user.
  Future<StealthUser> _upsertLocalUser() async {
    final sb.User? user = _supabase.currentUser;
    if (user == null) {
      throw const AuthFailure('Signed in but no session was returned');
    }
    final Map<String, dynamic> meta = user.userMetadata ?? <String, dynamic>{};
    final StealthUser fallback = currentUser!;

    final Map<String, dynamic> row = <String, dynamic>{
      'id': user.id,
      'username': (meta['username'] as String?) ?? fallback.username,
      'display_name': (meta['name'] as String?) ??
          fallback.displayName,
      'email': user.email,
      'avatar': (meta['avatar_url'] as String?) ?? '',
    };

    try {
      final Map<String, dynamic> saved = await _supabase
          .from('users')
          .upsert(row, onConflict: 'id')
          .select()
          .single();
      return StealthUser.fromMap(saved);
    } on Object {
      // Trigger may not be installed yet (or RLS blocked the write): fall back
      // to the auth metadata so the UI still has a usable identity.
      return fallback;
    }
  }

  static String _messageFor(sb.AuthException error) {
    switch (error.message.toLowerCase()) {
      case final String message when message.contains('invalid login'):
        return 'Wrong username or password';
      case final String message when message.contains('email not confirmed'):
        return 'Confirm your email first';
      case final String message when message.contains('already registered'):
        return 'That email already has an account';
      default:
        return error.message;
    }
  }
}

/// A login / sign-up failure with a message meant for the card.
class AuthFailure implements Exception {
  const AuthFailure(this.message);
  final String message;
  @override
  String toString() => message;
}
