import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../widgets/auth_layout.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key, this.authService});
  final AuthService? authService;

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  bool _hidePassword = true;
  bool _hideConfirmation = true;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _username.dispose();
    _email.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting || !_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await (widget.authService ?? AuthService()).signUp(
        username: _username.text,
        email: _email.text,
        password: _password.text,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on SignUpException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Something went wrong. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return PopScope(
      canPop: !_submitting,
      child: AuthLayout(
        signUp: true,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _username,
                enabled: !_submitting,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.newUsername],
                autocorrect: false,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  hintText: 'Choose your player name',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
                validator: (value) {
                  final length = value?.trim().length ?? 0;
                  return length < 3 || length > 30
                      ? 'Use between 3 and 30 characters'
                      : null;
                },
              ),
              const SizedBox(height: 10),
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
                autocorrect: false,
                enableSuggestions: false,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.newPassword],
                decoration: InputDecoration(
                  labelText: 'Password',
                  hintText: 'At least 8 characters',
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(
                    tooltip: _hidePassword ? 'Show password' : 'Hide password',
                    onPressed: _submitting
                        ? null
                        : () => setState(() => _hidePassword = !_hidePassword),
                    icon: Icon(
                      _hidePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                ),
                validator: (value) => (value?.length ?? 0) < 8
                    ? 'Use at least 8 characters'
                    : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _confirmPassword,
                enabled: !_submitting,
                obscureText: _hideConfirmation,
                autocorrect: false,
                enableSuggestions: false,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.newPassword],
                onFieldSubmitted: (_) => _submit(),
                decoration: InputDecoration(
                  labelText: 'Confirm password',
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(
                    tooltip: _hideConfirmation
                        ? 'Show confirmation password'
                        : 'Hide confirmation password',
                    onPressed: _submitting
                        ? null
                        : () => setState(
                            () => _hideConfirmation = !_hideConfirmation,
                          ),
                    icon: Icon(
                      _hideConfirmation
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                ),
                validator: (value) => value == null || value.isEmpty
                    ? 'Confirm your password'
                    : value != _password.text
                    ? 'Passwords do not match'
                    : null,
              ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Semantics(
                  liveRegion: true,
                  child: Text(_error!, style: TextStyle(color: colors.error)),
                ),
              ],
              const SizedBox(height: 14),
              RewardButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          semanticsLabel: 'Creating account',
                        ),
                      )
                    : const Text(
                        'Sign Up',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
              ),
              const SizedBox(height: 10),
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    'Already have an account?',
                    style: const TextStyle(color: Color(0xFFD5C4BA)),
                  ),
                  TextButton(
                    onPressed: _submitting
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: const Text('Sign in'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
