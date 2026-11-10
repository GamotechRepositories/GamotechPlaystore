import 'package:flutter/material.dart';
import 'signup_screen.dart';
import '../widgets/auth_layout.dart';
import 'home_screen.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.authService});
  final AuthService? authService;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _hidePassword = true;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _notice(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _login() async {
    if (_submitting || !_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final session = await (widget.authService ?? AuthService()).signIn(
        email: _email.text,
        password: _password.text,
      );
      if (!mounted) return;
      _password.clear();
      await Navigator.of(context).push<void>(
        MaterialPageRoute(builder: (_) => HomeScreen(session: session)),
      );
    } on AuthException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Something went wrong. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _openSignUp() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => SignUpScreen(authService: widget.authService),
      ),
    );
    if (mounted && created == true) {
      _notice('Account created! Sign in with your new credentials.');
    }
  }

  Widget _socialButton(String name, Widget icon) {
    return OutlinedButton(
      onPressed: _submitting
          ? null
          : () => _notice('$name sign-in is not connected yet.'),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ExcludeSemantics(child: icon),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              name,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    const muted = Color(0xFFD5C4BA);
    return AuthLayout(
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _email,
              enabled: !_submitting,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              autocorrect: false,
              decoration: const InputDecoration(
                labelText: 'Email address',
                hintText: 'you@example.com',
                prefixIcon: Icon(Icons.mail_outline_rounded),
              ),
              validator: (value) =>
                  RegExp(
                    r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                  ).hasMatch(value?.trim() ?? '')
                  ? null
                  : 'Enter a valid email address',
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _password,
              enabled: !_submitting,
              obscureText: _hidePassword,
              enableSuggestions: false,
              autocorrect: false,
              autofillHints: const [AutofillHints.password],
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _login(),
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  tooltip: _hidePassword ? 'Show password' : 'Hide password',
                  onPressed: () =>
                      setState(() => _hidePassword = !_hidePassword),
                  icon: Icon(
                    _hidePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
              validator: (value) => (value == null || value.isEmpty)
                  ? 'Enter your password'
                  : null,
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () =>
                    _notice('Password recovery is not available yet.'),
                child: const Text('Forgot password?'),
              ),
            ),
            const SizedBox(height: 8),
            if (_error != null) ...[
              Semantics(
                liveRegion: true,
                child: Text(_error!, style: TextStyle(color: colors.error)),
              ),
              const SizedBox(height: 10),
            ],
            RewardButton(
              onPressed: _submitting ? null : _login,
              child: _submitting
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        semanticsLabel: 'Signing in',
                      ),
                    )
                  : const Text(
                      'Sign in',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                const Expanded(child: Divider()),
                Flexible(
                  flex: 3,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      'or continue with',
                      style: const TextStyle(color: muted, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _socialButton(
                    'Google',
                    Image.asset(
                      'assets/images/google.png',
                      width: 20,
                      height: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _socialButton(
                    'Apple',
                    const Icon(Icons.apple, color: Colors.white, size: 22),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text("Don’t have an account?", style: TextStyle(color: muted)),
                TextButton(
                  onPressed: _submitting ? null : _openSignUp,
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFFFAB19),
                  ),
                  child: const Text('Sign Up'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
