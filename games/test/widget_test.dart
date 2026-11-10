import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:games/main.dart';

void main() {
  testWidgets('Login validates input and toggles password visibility', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    expect(find.text('Sign Up'), findsOneWidget);
    await tester.ensureVisible(find.text('Sign in'));
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a valid email address'), findsOneWidget);
    expect(find.text('Enter your password'), findsOneWidget);
    await tester.ensureVisible(find.byTooltip('Show password'));
    await tester.tap(find.byTooltip('Show password'));
    await tester.pump();
    final password = tester.widget<TextField>(find.byType(TextField).last);
    expect(password.obscureText, isFalse);
  });

  testWidgets('Login fits a small phone with enlarged text', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(1.5)),
          child: MyApp(),
        ),
      ),
    );
    await tester.ensureVisible(find.text('Google'));
    expect(tester.takeException(), isNull);
  });
}
