import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../backend/auth_service.dart';
import '../backend/models.dart';
import '../backend/supabase_client.dart';
import '../state/app_state.dart';
import '../theme/ig_theme.dart';
import 'auth_screen.dart';
import 'main_tab_scaffold.dart';

/// First thing the user sees. Shows the Instagram-style camera glyph + Meta
/// wordmark on a near-black background while the app figures out whether the
/// user is signed in.
///
/// If there is a Supabase session, route straight to the feed. If not, show the
/// Instagram authorization card so the user can sign in / sign up.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _checking = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tryResolve();
  }

  Future<void> _tryResolve() async {
    // Wait for Supabase to finish initializing if it hasn't already.
    if (!SupabaseClient.instance.isConfigured) {
      // configure() is called from main() / the shell before the splash is
      // pushed; if it isn't, the auth card will show the missing-keys warning.
    }

    if (AuthService.instance.isSignedIn) {
      // Restore the profile row for the restored session before the feed opens,
      // so anything that reads AppState.me sees the real handle.
      final StealthUser? profile = await AuthService.instance.syncProfile();
      if (profile != null) AppState.instance.setMe(profile);
      await _goToFeed();
      return;
    }

    if (!mounted) return;
    setState(() {
      _checking = false;
      _error = AuthService.instance.isConfigured
          ? null
          : 'Add your Supabase URL and anon key to .env first';
    });

    // The splash is only a loader: hand off to the authorization card.
    await Future<void>.delayed(const Duration(milliseconds: 650));
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const InstagramAuthScreen()),
    );
  }

  Future<void> _goToFeed() async {
    AppState.instance.selectTab(0);
    if (!mounted) return;
    setState(() => _checking = false);
    await Future<void>.delayed(const Duration(milliseconds: 220));
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const MainTabScaffold()),
    );
  }

  Widget _statusWidget() {
    if (_checking) return const _BootCounter();
    if (_error != null) return _ErrorCard(message: _error!);
    return const _SignInHint();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: IgTheme.dark(),
      home: Scaffold(
        backgroundColor: const Color(0xFF111111),
        body: SafeArea(
          child: Column(
            children: <Widget>[
              const Spacer(flex: 7),
              const _SvgInstagramLogo(),
              const Spacer(flex: 5),
              _statusWidget(),
              const SizedBox(height: 14),
            ],
          ),
        ),
      ),
    );
  }
}

class _SvgInstagramLogo extends StatelessWidget {
  const _SvgInstagramLogo();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SvgPicture.asset(
        'assets/splash/instagram_camera_glyph.svg',
        width: 112,
        height: 112,
        fit: BoxFit.contain,
      ),
    );
  }
}


class _BootCounter extends StatelessWidget {
  const _BootCounter();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 10),
      child: Column(
        children: <Widget>[
          const SizedBox(
            width: 36,
            height: 36,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              color: Color(0xFFB3B3B3),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Signing you in…',
            style: IgText.body(size: 13, color: IgColors.textTertiary),
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF262626),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF363636), width: 1),
      ),
      child: Row(
        children: <Widget>[
          const Icon(
            Icons.warning_amber_rounded,
            size: 16,
            color: Color(0xFFE1306C),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: IgText.body(size: 12, color: IgColors.textTertiary),
            ),
          ),
        ],
      ),
    );
  }
}

class _SignInHint extends StatelessWidget {
  const _SignInHint();


  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF262626),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF363636), width: 1),
      ),
      child: Row(
        children: <Widget>[
          const Icon(
            Icons.login_outlined,
            size: 16,
            color: Color(0xFF833AB4),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Sign in with Instagram to use Stealth Chat',
              style: IgText.body(size: 12, color: IgColors.textTertiary),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const InstagramAuthScreen(),
                ),
              );
            },
            child: const Padding(
              padding: EdgeInsets.only(left: 4, right: 4),
              child: Text(
                'Sign in',
                style: TextStyle(
                  color: Color(0xFFE1306C),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
