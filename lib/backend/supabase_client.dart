import 'package:supabase_flutter/supabase_flutter.dart' as sb;

/// Deep link the browser returns to after Instagram OAuth.
///
/// Must be added to Supabase -> Authentication -> URL Configuration ->
/// Redirect URLs, and to the native intent filters in android/ios when the
/// Instagram provider is switched on.
const String kAuthRedirectUrl = 'io.supabase.stealthchat://login-callback';

/// Single wired Supabase client for the whole app.
///
/// Everything the backend layer touches (auth, `users`, `dm_messages`) goes
/// through here so there is exactly one place that knows the project URL and
/// anon key. Nothing is hard-coded: [configure] is fed from the environment
/// (see `main.dart`) so the keys never land in the repo.
class SupabaseClient {
  SupabaseClient._();

  static final SupabaseClient instance = SupabaseClient._();

  bool _initialized = false;

  /// True once [configure] has run and the SDK is live.
  bool get isConfigured => _initialized;

  /// The live SDK client. Throws if the app never configured Supabase.
  sb.SupabaseClient get client {
    if (!_initialized) {
      throw StateError(
        'Supabase is not configured. Set SUPABASE_URL and SUPABASE_ANON_KEY '
        'in .env (or pass --dart-define) and restart the app.',
      );
    }
    return sb.Supabase.instance.client;
  }

  sb.GoTrueClient get auth => client.auth;

  sb.Session? get session => isConfigured ? client.auth.currentSession : null;

  sb.User? get currentUser => isConfigured ? client.auth.currentUser : null;

  bool get isSignedIn => currentUser != null;

  /// The signed-in user's id (`auth.uid()`), or null.
  String? get userId => currentUser?.id;

  /// `from(table)` shortcut used by the services.
  sb.PostgrestQueryBuilder from(String table) => client.from(table);

  /// Boot the SDK once. Safe to call repeatedly.
  Future<void> configure({
    required String url,
    required String anonKey,
  }) async {
    if (_initialized) return;
    if (url.isEmpty || anonKey.isEmpty) {
      throw ArgumentError('Supabase url and anon key are both required');
    }
    await sb.Supabase.initialize(
      url: url,
      // ignore: deprecated_member_use
      anonKey: anonKey,
      debug: false,
    );
    _initialized = true;
  }

  // ------------------------------------------------------------------ auth

  /// Sign in with the email/password pair behind the login card.
  Future<sb.AuthResponse> signInWithPassword({
    required String email,
    required String password,
  }) {
    return auth.signInWithPassword(email: email, password: password);
  }

  /// Create an account and stash the handle in auth metadata so the
  /// `handle_new_user` trigger can seed the `users` row.
  Future<sb.AuthResponse> signUpWithPassword({
    required String email,
    required String password,
    required String username,
    required String displayName,
  }) {
    return auth.signUp(
      email: email,
      password: password,
      data: <String, dynamic>{
        'username': username,
        'display_name': displayName,
      },
    );
  }

  /// Generic OAuth entry point.
  ///
  /// supabase_flutter has no built-in Instagram provider, so the app signs in
  /// with the account email + password the card collects. When a provider is
  /// wired later, pass it here (OAuthProvider.google, ...facebook, ...) with
  /// [kAuthRedirectUrl] registered under Authentication -> URL Configuration.
  Future<bool> signInWithOAuth(sb.OAuthProvider provider) {
    return auth.signInWithOAuth(
      provider,
      redirectTo: kAuthRedirectUrl,
      authScreenLaunchMode: sb.LaunchMode.externalApplication,
    );
  }

  Future<void> signOut() => auth.signOut();

  /// Email behind a username, resolved server-side (security definer function)
  /// so no email is readable through the normal select path.
  Future<String?> emailForUsername(String username) async {
    final dynamic result = await client.rpc(
      'login_email_for',
      params: <String, dynamic>{'handle': username.trim().toLowerCase()},
    );
    if (result is String && result.isNotEmpty) return result;
    return null;
  }
}
