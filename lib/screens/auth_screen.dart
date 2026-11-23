import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../backend/auth_service.dart';
import '../backend/models.dart';
import '../backend/permission_service.dart';
import '../backend/supabase_client.dart';
import '../main.dart' show AppConfig;
import '../state/app_state.dart';
import '../theme/ig_theme.dart';
import 'main_tab_scaffold.dart';

/// Instagram authorization card — the layout from
/// `Instagram Authorization (1).svg`.
///
/// Login and sign-up are the same card: two 44px fields at 16px side padding,
/// the blue submit button, and a text link underneath that flips the mode. The
/// card is built natively (rather than painting the SVG) so the fields are
/// editable and the button is tappable; spacing, radii, colours and type come
/// straight from the SVG.
class InstagramAuthScreen extends StatefulWidget {
  const InstagramAuthScreen({super.key});

  @override
  State<InstagramAuthScreen> createState() => _InstagramAuthScreenState();
}

enum _AuthMode { login, signup }

class _InstagramAuthScreenState extends State<InstagramAuthScreen> {
  final TextEditingController _identifier = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _username = TextEditingController();
  final TextEditingController _password = TextEditingController();

  _AuthMode _mode = _AuthMode.login;
  bool _busy = false;
  bool _obscure = true;
  String? _error;

  bool get _configured => SupabaseClient.instance.isConfigured;

  @override
  void dispose() {
    _identifier.dispose();
    _email.dispose();
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  void _switchMode() {
    setState(() {
      _mode = _mode == _AuthMode.login ? _AuthMode.signup : _AuthMode.login;
      _error = null;
    });
  }

  Future<void> _submit() async {
    if (_busy) return;
    if (!_configured) {
      setState(() {
        _error = AppConfig.isReady
            ? 'Could not reach the backend. Try again.'
            : 'This build has no Supabase keys — set them in .env and rebuild';
      });
      return;
    }

    final String identifier = _identifier.text.trim();
    final String password = _password.text;

    if (identifier.isEmpty || password.isEmpty) {
      setState(() => _error = 'Fill in both fields');
      return;
    }
    if (_mode == _AuthMode.signup &&
        (_email.text.trim().isEmpty || _username.text.trim().isEmpty)) {
      setState(() => _error = 'Email and username are required');
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final StealthUser user = _mode == _AuthMode.login
          ? await AuthService.instance.signIn(
              identifier: identifier,
              password: password,
            )
          : await AuthService.instance.signUp(
              email: _email.text.trim(),
              password: password,
              username: _username.text.trim(),
            );
      AppState.instance.setMe(user);
      AppState.instance.selectTab(0);
      // Camera, microphone and photo access are asked for once, here, rather
      // than the first time the user opens the camera or records a note.
      await PermissionService.requestChatPermissions();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const MainTabScaffold()),
        (Route<void> route) => false,
      );
    } on AuthFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = failure.message;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = 'Could not sign in: $error';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            const Spacer(flex: 2),
            Expanded(
              flex: 11,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    SvgPicture.asset(
                      'assets/splash/instagram_camera_glyph.svg',
                      width: 62,
                      height: 62,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Instagram',
                      style: TextStyle(
                        fontFamily: 'Billabong',
                        fontSize: 42,
                        height: 1.1,
                        color: IgColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 22),
                    if (_mode == _AuthMode.signup) ...<Widget>[
                      _field(
                        controller: _email,
                        hint: 'Email address',
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const <String>[AutofillHints.email],
                      ),
                      const SizedBox(height: 12),
                      _field(
                        controller: _username,
                        hint: 'Username',
                        prefix: '@',
                        autocorrect: false,
                        autofillHints: const <String>[AutofillHints.newUsername],
                      ),
                      const SizedBox(height: 12),
                      _field(
                        controller: _password,
                        hint: 'Password',
                        obscure: true,
                        keyboardType: TextInputType.visiblePassword,
                        autofillHints: const <String>[AutofillHints.newPassword],
                      ),
                    ] else ...<Widget>[
                      _field(
                        controller: _identifier,
                        hint: 'Phone number, username or email',
                        autocorrect: false,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const <String>[AutofillHints.username],
                      ),
                      const SizedBox(height: 12),
                      _field(
                        controller: _password,
                        hint: 'Password',
                        obscure: true,
                        keyboardType: TextInputType.visiblePassword,
                        autofillHints: const <String>[AutofillHints.password],
                        onSubmitted: (_) => _submit(),
                      ),
                    ],
                    if (_error != null) ...<Widget>[
                      const SizedBox(height: 12),
                      _errorRow(_error!),
                    ],
                    const SizedBox(height: 18),
                    _submitButton(),
                    const SizedBox(height: 20),
                    if (_mode == _AuthMode.login) ...<Widget>[
                      Text(
                        'Forgot password?',
                        style: IgText.semibold(
                          size: 13,
                          color: IgColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 26),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Text(
                            "Don't have an account? ",
                            style: IgText.body(
                              size: 13,
                              color: IgColors.textSecondary,
                            ),
                          ),
                          GestureDetector(
                            onTap: _switchMode,
                            child: Text(
                              'Sign up.',
                              style: IgText.semibold(
                                size: 13,
                                color: IgColors.blue,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ] else ...<Widget>[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Text(
                            'Have an account? ',
                            style: IgText.body(
                              size: 13,
                              color: IgColors.textSecondary,
                            ),
                          ),
                          GestureDetector(
                            onTap: _switchMode,
                            child: Text(
                              'Log in.',
                              style: IgText.semibold(
                                size: 13,
                                color: IgColors.blue,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 14),
              child: Column(
                children: <Widget>[
                  Text(
                    'Meta',
                    style: TextStyle(
                      fontFamily: 'Billabong',
                      fontSize: 17,
                      color: IgColors.textTertiary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'The owner of this account can see your activity. '
                    'By continuing you agree to the Terms and Privacy Policy.',
                    textAlign: TextAlign.center,
                    style: IgText.body(
                      size: 10.5,
                      color: IgColors.textTertiary,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String hint,
    String? prefix,
    bool obscure = false,
    bool autocorrect = true,
    TextInputType? keyboardType,
    Iterable<String>? autofillHints,
    ValueChanged<String>? onSubmitted,
  }) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 0.5),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      alignment: Alignment.centerLeft,
      child: Row(
        children: <Widget>[
          if (prefix != null)
            Text(
              prefix,
              style: IgText.body(size: 14, color: IgColors.textTertiary),
            ),
          Expanded(
            child: TextField(
              controller: controller,
              obscureText: obscure,
              autocorrect: autocorrect,
              enableSuggestions: autocorrect,
              keyboardType: keyboardType,
              autofillHints: autofillHints,
              onSubmitted: onSubmitted,
              cursorColor: IgColors.textPrimary,
              style: IgText.body(size: 14),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: hint,
                hintStyle: IgText.body(size: 14, color: IgColors.textTertiary),
                suffixIconConstraints:
                    const BoxConstraints(minWidth: 0, minHeight: 0),
                suffixIcon: obscure
                    ? GestureDetector(
                        onTap: () => setState(() => _obscure = !_obscure),
                        child: Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Icon(
                            _obscure
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            size: 17,
                            color: IgColors.textTertiary,
                          ),
                        ),
                      )
                    : null,
              ),
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _submitButton() {
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: Material(
        color: IgColors.blue,
        borderRadius: BorderRadius.circular(5),
        child: InkWell(
          borderRadius: BorderRadius.circular(5),
          onTap: _busy ? null : _submit,
          child: Center(
            child: _busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    _mode == _AuthMode.login ? 'Log in' : 'Sign up',
                    style: IgText.semibold(size: 14, color: Colors.white),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _errorRow(String message) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Icon(
          Icons.error_outline,
          size: 15,
          color: Color(0xFFE1306C),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            message,
            style: IgText.body(size: 12, color: const Color(0xFFE1306C)),
          ),
        ),
      ],
    );
  }
}
