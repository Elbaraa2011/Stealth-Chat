import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'backend/supabase_client.dart';
import 'screens/splash_screen.dart';
import 'state/app_state.dart';
import 'theme/ig_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Read the Supabase keys from the bundled config (or .env on desktop).
  final Map<String, String> env = await readAppEnv();
  final String url = env['SUPABASE_URL'] ?? '';
  final String anonKey = env['SUPABASE_ANON_KEY'] ?? '';
  AppConfig.supabaseUrl = url;
  AppConfig.supabaseAnonKey = anonKey;

  // Configure the client before the splash so the first auth check is already
  // wired when the user lands on the Instagram authorization card.
  if (url.isNotEmpty && anonKey.isNotEmpty) {
    await SupabaseClient.instance.configure(url: url, anonKey: anonKey);
  }

  runApp(const StealthChatApp());
}

/// Keys for the Supabase project.
///
/// Values come from the shell environment when running on desktop
/// (`SUPABASE_URL` / `SUPABASE_ANON_KEY`), or from compile-time defines:
///
/// ```
/// flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
/// ```
///
/// Without either the app still opens; the authorization card shows the
/// missing-keys warning instead of trying to sign in.
class AppConfig {
  static String supabaseUrl = '';
  static String supabaseAnonKey = '';

  static bool get isReady =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}

Future<Map<String, String>> readAppEnv() async {
  // Lowest priority first: bundled config and .env, then shell environment,
  // then --dart-define, so an explicit flag always wins.
  final Map<String, String> out = <String, String>{
    ...await _readBundledEnv(),
    ..._readDotEnv(),
  };

  // Only a *set* variable overrides what the file provided. Assigning the
  // empty fallback here would erase the bundled keys on every phone build,
  // where the shell environment has neither variable.
  for (final String name in const <String>[
    'SUPABASE_URL',
    'SUPABASE_ANON_KEY',
  ]) {
    final String? value = Platform.environment[name];
    if (value != null && value.trim().isNotEmpty) out[name] = value.trim();
  }

  const String defineUrl = String.fromEnvironment('SUPABASE_URL');
  const String defineKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  if (defineUrl.isNotEmpty) out['SUPABASE_URL'] = defineUrl;
  if (defineKey.isNotEmpty) out['SUPABASE_ANON_KEY'] = defineKey;

  if ((out['SUPABASE_URL'] ?? '').isEmpty) out.remove('SUPABASE_URL');
  if ((out['SUPABASE_ANON_KEY'] ?? '').isEmpty) {
    out.remove('SUPABASE_ANON_KEY');
  }
  return out;
}

/// `assets/env.json` — the copy of `.env` that ships inside the app.
///
/// On a phone there is no project directory to read `.env` from, so the keys
/// travel as an asset. Android's packaging drops dotfiles, which is why this is
/// a plain `env.json` rather than `.env` itself.
Future<Map<String, String>> _readBundledEnv() async {
  try {
    final String raw = await rootBundle.loadString('assets/env.json');
    final Object? decoded = jsonDecode(raw);
    if (decoded is! Map) return <String, String>{};
    return <String, String>{
      for (final MapEntry<dynamic, dynamic> entry in decoded.entries)
        if (entry.value is String) entry.key.toString(): entry.value as String,
    };
  } on Object {
    // Missing or malformed: fall through to the other sources.
    return <String, String>{};
  }
}

/// Minimal `KEY=value` reader for the project-root `.env`.
///
/// Mobile builds do not ship this file, so callers pass the keys through
/// `--dart-define` there instead.
/// Minimal `KEY=value` reader for the project-root `.env`.
///
/// Mobile builds do not ship this file, so callers pass the keys through
/// `--dart-define` there instead.
Map<String, String> _readDotEnv() {
  const Map<String, String> empty = <String, String>{};

  // FIXED: Prevent mobile platforms from trying to read local system paths synchronously
  if (Platform.isAndroid || Platform.isIOS) {
    return empty;
  }

  try {
    final File file = File('.env');
    if (!file.existsSync()) return empty;
    final Map<String, String> values = <String, String>{};
    for (final String rawLine in file.readAsLinesSync()) {
      final String line = rawLine.trim();
      if (line.isEmpty || line.startsWith('#') || !line.contains('=')) {
        continue;
      }
      final int split = line.indexOf('=');
      values[line.substring(0, split).trim()] = line
          .substring(split + 1)
          .trim()
          .replaceAll(RegExp(r'^"|"$'), '');
    }
    return values;
  } on Object {
    return empty;
  }
}


/// Decoy shell. Watches the app lifecycle and, on any loss of foreground
/// focus, destroys the covert session and rebuilds the app from scratch so
/// the user lands back on the public photo feed.
class StealthChatApp extends StatefulWidget {
  const StealthChatApp({super.key});

  @override
  State<StealthChatApp> createState() => _StealthChatAppState();
}

class _StealthChatAppState extends State<StealthChatApp>
    with WidgetsBindingObserver {
  /// Bumped on every panic. It is the MaterialApp's key, so a new value
  /// disposes the entire element tree — navigator, route stack, every covert
  /// widget and its state — and builds a fresh decoy from scratch. This is
  /// stronger than popping routes, because nothing can outlive the rebuild.
  int _sessionEpoch = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // An in-app camera, gallery or recorder we opened also reports
    // inactive/paused; that is not the user leaving, so the covert session
    // must survive it instead of dropping back to the decoy.
    if (AppState.instance.panicSuspended) return;
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.hidden) {
      _panicReset();
    }
  }

  /// Drop focus and rebuild onto the decoy feed.
  void _panicReset() {
    FocusManager.instance.primaryFocus?.unfocus();
    AppState.instance.selectTab(0);
    if (!mounted) return;
    setState(() => _sessionEpoch++);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      key: ValueKey<int>(_sessionEpoch),
      debugShowCheckedModeBanner: false,
      title: 'Instagram',
      theme: IgTheme.dark(),
      home: const SplashScreen(),
    );
  }
}
