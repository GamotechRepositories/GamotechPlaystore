import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:games/screens/login_screen.dart';
import 'package:games/services/auth_service.dart';

class FlowAuthService extends AuthService {
  String? failure;
  int registrations = 0;
  String? registeredEmail;

  @override
  Future<void> signUp({
    required String username,
    required String email,
    required String password,
  }) async {
    registrations++;
    registeredEmail = email;
  }

  @override
  Future<AuthSession> signIn({
    required String email,
    required String password,
  }) async {
    if (failure != null) throw AuthException(failure!);
    return AuthSession(token: 'test-token', username: 'player1', email: email);
  }
}

void main() {
  testWidgets('Sign up, sign in, and sign out form one connected flow', (
    tester,
  ) async {
    final service = FlowAuthService();
    await tester.pumpWidget(
      MaterialApp(home: LoginScreen(authService: service)),
    );
    await tester.ensureVisible(find.text('Sign Up'));
    await tester.tap(find.text('Sign Up'));
    await tester.pumpAndSettle();
    final fields = find.byType(TextFormField);
    for (final entry in [
      'player1',
      'player@example.com',
      'password123',
      'password123',
    ].asMap().entries) {
      await tester.ensureVisible(fields.at(entry.key));
      await tester.enterText(fields.at(entry.key), entry.value);
    }
    await tester.ensureVisible(find.text('Sign Up'));
    await tester.tap(find.text('Sign Up'));
    await tester.pumpAndSettle();
    expect(service.registrations, 1);
    expect(find.text('Sign Up'), findsOneWidget);
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'player@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'password123');
    await tester.ensureVisible(find.text('Sign in'));
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();
    expect(find.text('player1'), findsOneWidget);
    await tester.tap(find.byTooltip('Profile'));
    await tester.pumpAndSettle();
    expect(find.text('player@example.com'), findsOneWidget);
    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();
    expect(find.text('Sign Up'), findsOneWidget);
    expect(
      tester
          .widget<TextFormField>(find.byType(TextFormField).at(1))
          .controller!
          .text,
      isEmpty,
    );
  });

  testWidgets('Failed sign in displays error and permits retry', (
    tester,
  ) async {
    final service = FlowAuthService()..failure = 'Invalid email or password';
    await tester.pumpWidget(
      MaterialApp(home: LoginScreen(authService: service)),
    );
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'player@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'wrong-password');
    await tester.ensureVisible(find.text('Sign in'));
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();
    expect(find.text('Invalid email or password'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNotNull,
    );
    service.failure = null;
    await tester.ensureVisible(find.text('Sign in'));
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();
    expect(find.text('player1'), findsOneWidget);
  });
}
