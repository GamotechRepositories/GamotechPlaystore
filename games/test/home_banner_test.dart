import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:games/screens/home_screen.dart';
import 'package:games/services/auth_service.dart';
import 'package:games/services/banner_service.dart';
import 'package:games/widgets/home_banner_carousel.dart';

class TestBannerService extends BannerService {
  TestBannerService(this.load);
  Future<List<HomeBanner>> Function() load;
  int calls = 0;

  @override
  Future<List<HomeBanner>> fetchHomeBanners() {
    calls++;
    return load();
  }
}

const banners = [
  HomeBanner(
    title: 'Teen Patti',
    imageUrl: 'https://example.com/teen-patti.png',
  ),
  HomeBanner(title: 'Ludo', imageUrl: 'https://example.com/ludo.png'),
];

void main() {
  testWidgets('loads once and navigates API banners by buttons and swipe', (
    tester,
  ) async {
    final pending = Completer<List<HomeBanner>>();
    final service = TestBannerService(() => pending.future);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: HomeBannerCarousel(bannerService: service)),
      ),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    pending.complete(banners);
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Banner 1 of 2'), findsOneWidget);
    final image = tester.widgetList<Image>(find.byType(Image)).first;
    expect((image.image as NetworkImage).url, banners.first.imageUrl);
    expect(image.semanticLabel, 'Teen Patti');
    await tester.drag(find.byType(PageView), const Offset(-700, 0));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Banner 2 of 2'), findsOneWidget);
    await tester.drag(find.byType(PageView), const Offset(700, 0));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Banner 1 of 2'), findsOneWidget);
    await tester.drag(find.byType(PageView), const Offset(-700, 0));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Banner 2 of 2'), findsOneWidget);
    expect(service.calls, 1);
  });

  testWidgets('auto advances every four seconds and wraps to the first dot', (
    tester,
  ) async {
    final service = TestBannerService(() async => banners);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: HomeBannerCarousel(bannerService: service)),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Banner 1 of 2'), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Banner 2 of 2'), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Banner 1 of 2'), findsOneWidget);
    expect(find.byType(IconButton), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('shows an error, retries, and handles an empty collection', (
    tester,
  ) async {
    final service = TestBannerService(
      () async => throw const BannerException('Connection failed'),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: HomeBannerCarousel(bannerService: service)),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Connection failed'), findsOneWidget);
    service.load = () async => [];
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(service.calls, 2);
    expect(find.text('Retry'), findsNothing);
    expect(find.byType(PageView), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('home fits a small phone with enlarged text and failed images', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final service = TestBannerService(() async => banners);
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            textScaler: TextScaler.linear(1.5),
            disableAnimations: true,
          ),
          child: HomeScreen(
            session: const AuthSession(
              token: 'test',
              username: 'player1',
              email: 'player@example.com',
            ),
            bannerService: service,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.drag(find.byType(PageView), const Offset(-700, 0));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Banner 2 of 2'), findsOneWidget);
    expect(find.text('Sign out'), findsNothing);
    expect(find.text('You’re signed in and ready to play.'), findsNothing);
    expect(find.text('player1'), findsOneWidget);
    expect(find.text('Welcome, player1!'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
