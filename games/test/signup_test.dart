import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:games/main.dart';
import 'package:games/screens/signup_screen.dart';
import 'package:games/services/auth_service.dart';

class TestAuthService extends AuthService {
  TestAuthService({this.failure});
  final String? failure;
  int calls = 0;

  @override
  Future<void> signUp({
    required String username,
    required String email,
    required String password,
  }) async {
    calls++;
    if (failure != null) throw SignUpException(failure!);
  }
}

Future<void> fillForm(
  WidgetTester tester, {
  String confirmation = 'password123',
}) async {
  final fields = find.byType(TextFormField);
  for (final entry in [
    'player1',
    'player@example.com',
    'password123',
    confirmation,
  ].asMap().entries) {
    await tester.ensureVisible(fields.at(entry.key));
    await tester.enterText(fields.at(entry.key), entry.value);
  }
  await tester.ensureVisible(find.text('Sign Up'));
  await tester.tap(find.text('Sign Up'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Login opens signup and returns to login', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.ensureVisible(find.text('Sign Up'));
    await tester.tap(find.text('Sign Up'));
    await tester.pumpAndSettle();
    expect(find.text('Create Account'), findsOneWidget);
    await tester.ensureVisible(find.text('Sign in').last);
    await tester.tap(find.text('Sign in').last);
    await tester.pumpAndSettle();
    expect(find.text('Sign Up'), findsOneWidget);
  });

  testWidgets('Mismatched passwords prevent submission', (tester) async {
    final service = TestAuthService();
    await tester.pumpWidget(
      MaterialApp(home: SignUpScreen(authService: service)),
    );
    await fillForm(tester, confirmation: 'different');
    expect(find.text('Passwords do not match'), findsOneWidget);
    expect(service.calls, 0);
  });

  testWidgets('Duplicate error stays visible and form allows retry', (
    tester,
  ) async {
    final service = TestAuthService(
      failure: 'Email or username already exists',
    );
    await tester.pumpWidget(
      MaterialApp(home: SignUpScreen(authService: service)),
    );
    await fillForm(tester);
    expect(find.text('Email or username already exists'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNotNull,
    );
    expect(service.calls, 1);
  });

  testWidgets('Successful signup returns success to the previous screen', (
    tester,
  ) async {
    final service = TestAuthService();
    bool? created;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return TextButton(
              onPressed: () async {
                created = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (_) => SignUpScreen(authService: service),
                  ),
                );
              },
              child: const Text('Open signup'),
            );
          },
        ),
      ),
    );
    await tester.tap(find.text('Open signup'));
    await tester.pumpAndSettle();
    await fillForm(tester);
    expect(created, true);
    expect(find.text('Open signup'), findsOneWidget);
  });

  testWidgets('Signup fits small screens with enlarged text', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
          child: SignUpScreen(authService: TestAuthService()),
        ),
      ),
    );
    await tester.ensureVisible(find.text('Sign Up'));
    expect(tester.takeException(), isNull);
  });
}
