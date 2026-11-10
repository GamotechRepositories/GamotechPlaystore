import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:games/main.dart';
import 'package:games/screens/login_screen.dart';
import 'package:games/screens/onboarding_screen.dart';
import 'package:games/services/onboarding_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FailingOnboardingService extends OnboardingService {
  @override
  Future<void> complete() async => throw StateError('Storage unavailable');
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Finder control(int slide, String label) => find.descendant(
    of: find.byKey(PageStorageKey('onboarding-slide-$slide')),
    matching: find.byKey(ValueKey(label)),
  );

  Future<void> nextSlide(WidgetTester tester, {int from = 0}) async {
    await tester.ensureVisible(control(from, 'Next'));
    await tester.tap(control(from, 'Next'));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'Get Started completes first-launch onboarding and persists across launches',
    (tester) async {
      const service = OnboardingService();
      expect(await service.isCompleted(), isFalse);
      await tester.pumpWidget(
        MyApp(showOnboarding: !await service.isCompleted()),
      );
      await tester.pumpAndSettle();
      expect(find.byType(OnboardingScreen), findsOneWidget);
      expect(find.byType(LoginScreen), findsNothing);
      final assets = tester
          .widgetList<Image>(find.byType(Image))
          .map((image) => (image.image as AssetImage).assetName);
      expect(
        assets,
        containsAll([
          'assets/images/Crimson Gold Lightwave Wallpaper.png',
          'assets/images/card.png',
        ]),
      );
      expect(find.text('Play Your\nFavourite Games'), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);
      await nextSlide(tester);
      expect(await service.isCompleted(), isFalse);
      expect(find.text('Play with\nFriends Online'), findsOneWidget);
      final friendsImage = tester.widget<Image>(
        find.byWidgetPredicate(
          (widget) =>
              widget is Image &&
              widget.image is AssetImage &&
              (widget.image as AssetImage).assetName ==
                  'assets/images/frd.png',
        ),
      );
      expect(friendsImage.semanticLabel, contains('Friends'));
      await nextSlide(tester, from: 1);
      expect(await service.isCompleted(), isFalse);
      expect(find.text('Join Tournaments\n& Win Big'), findsOneWidget);
      final cupImage = tester.widget<Image>(
        find.byWidgetPredicate(
          (widget) =>
              widget is Image &&
              widget.image is AssetImage &&
              (widget.image as AssetImage).assetName == 'assets/images/cup.png',
        ),
      );
      expect(cupImage.semanticLabel, contains('trophy'));
      final actionControl = control(2, 'Get Started');
      await tester.ensureVisible(actionControl);
      await tester.tap(actionControl);
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(OnboardingScreen), findsNothing);
      expect(await service.isCompleted(), isTrue);
      expect(
        Navigator.of(tester.element(find.byType(LoginScreen))).canPop(),
        isFalse,
      );

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(
        MyApp(showOnboarding: !await const OnboardingService().isCompleted()),
      );
      await tester.pumpAndSettle();
      expect(find.byType(OnboardingScreen), findsNothing);
      expect(find.byType(LoginScreen), findsOneWidget);
    },
  );

  testWidgets('failed completion stays on onboarding and permits retry', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: OnboardingScreen(service: FailingOnboardingService())),
    );
    await tester.pumpAndSettle();
    await nextSlide(tester);
    await nextSlide(tester, from: 1);
    await tester.ensureVisible(control(2, 'Get Started'));
    await tester.tap(control(2, 'Get Started'));
    await tester.pumpAndSettle();
    expect(find.text('Unable to save. Please try again.'), findsOneWidget);
    expect(find.byType(OnboardingScreen), findsOneWidget);
    expect(await const OnboardingService().isCompleted(), isFalse);
    expect(
      tester
          .widget<TextButton>(find.byKey(const ValueKey('Get Started')))
          .onPressed,
      isNotNull,
    );
  });

  testWidgets(
    'swipes between slides and uses page indicators without completing onboarding',
    (tester) async {
      await tester.pumpWidget(const MyApp(showOnboarding: true));
      await tester.pumpAndSettle();
      await tester.drag(find.byType(PageView), const Offset(-700, 0));
      await tester.pumpAndSettle();
      expect(find.text('Play with\nFriends Online'), findsOneWidget);
      await tester.drag(find.byType(PageView), const Offset(-700, 0));
      await tester.pumpAndSettle();
      expect(find.text('Join Tournaments\n& Win Big'), findsOneWidget);
      expect(await const OnboardingService().isCompleted(), isFalse);
      await tester.ensureVisible(control(2, 'onboarding-dot-0'));
      await tester.tap(control(2, 'onboarding-dot-0'));
      await tester.pumpAndSettle();
      expect(find.text('Play Your\nFavourite Games'), findsOneWidget);
      expect(await const OnboardingService().isCompleted(), isFalse);
      await tester.ensureVisible(control(0, 'onboarding-dot-2'));
      await tester.tap(control(0, 'onboarding-dot-2'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(control(2, 'Get Started'));
      await tester.tap(control(2, 'Get Started'));
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(await const OnboardingService().isCompleted(), isTrue);
    },
  );

  for (final size in [
    const Size(320, 568),
    const Size(568, 320),
    const Size(1024, 1366),
  ]) {
    testWidgets('onboarding image and controls fit $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(
              textScaler: TextScaler.linear(2),
              disableAnimations: true,
            ),
            child: OnboardingScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      for (var slide = 0; slide < 3; slide++) {
        expect(find.text('Skip'), findsNothing);
        final label = slide == 2 ? 'Get Started' : 'Next';
        await tester.ensureVisible(control(slide, label));
        await tester.pumpAndSettle();
        final rect = tester.getRect(control(slide, label));
        expect(rect.height, greaterThanOrEqualTo(48));
        expect(rect.width, greaterThanOrEqualTo(48));
        expect(rect.top, greaterThanOrEqualTo(0));
        expect(rect.bottom, lessThanOrEqualTo(size.height));
        if (slide < 2) await nextSlide(tester, from: slide);
      }
      expect(tester.takeException(), isNull);
    });
  }
}
