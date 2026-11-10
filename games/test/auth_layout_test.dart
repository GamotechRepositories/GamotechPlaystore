import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:games/main.dart';

void main() {
  for (final size in [
    const Size(320, 568),
    const Size(393, 852),
    const Size(844, 390),
  ]) {
    testWidgets(
      'Both auth forms stay reachable with validation and keyboard at $size',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetViewInsets);
        await tester.pumpWidget(const MyApp());
        await tester.pumpAndSettle();
        Future<void> expectVisible(Finder finder, double bottom) async {
          await tester.ensureVisible(finder);
          await tester.pumpAndSettle();
          final rect = tester.getRect(finder);
          expect(rect.top, greaterThanOrEqualTo(0));
          expect(rect.bottom, lessThanOrEqualTo(bottom + 1));
        }

        expect(find.text('Welcome Back!'), findsOneWidget);
        expect(find.text('Google'), findsOneWidget);
        expect(find.text('Apple'), findsOneWidget);
        await expectVisible(find.text('Sign Up'), size.height);
        await tester.tap(find.text('Sign Up'));
        await tester.pumpAndSettle();
        expect(find.text('Create Account'), findsOneWidget);
        await expectVisible(find.text('Sign Up'), size.height);
        expect(
          tester.getSize(find.byType(FilledButton)).height,
          greaterThanOrEqualTo(48),
        );
        await expectVisible(find.text('Sign in'), size.height);
        await expectVisible(find.text('Sign Up'), size.height);
        await tester.tap(find.text('Sign Up'));
        await tester.pumpAndSettle();
        await expectVisible(find.text('Sign Up'), size.height);
        expect(tester.takeException(), isNull);
        final keyboardHeight = size.height > 500 ? 280.0 : 160.0;
        tester.view.viewInsets = FakeViewPadding(bottom: keyboardHeight);
        await tester.pumpAndSettle();
        await expectVisible(find.text('Sign Up'), size.height - keyboardHeight);
        await expectVisible(find.text('Sign in'), size.height - keyboardHeight);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
