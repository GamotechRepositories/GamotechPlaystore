import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:games/services/game_service.dart';
import 'package:games/widgets/home_games_section.dart';

class FakeGameService extends GameService {
  List<Game> games = [];
  bool fail = false;
  int calls = 0;

  @override
  Future<List<Game>> fetchGames() async {
    calls++;
    if (fail) throw const GameException('Unable to load games.');
    return games;
  }
}

void main() {
  testWidgets(
    'renders API games including an odd final row on a small screen',
    (tester) async {
      tester.view.physicalSize = const Size(375, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final service = FakeGameService()
        ..games = [
          const Game(
            name: 'Chess',
            imageUrl: 'https://example.com/chess.png',
            description: 'Challenge a friend',
          ),
          const Game(name: 'Ludo', imageUrl: 'https://example.com/ludo.png'),
          const Game(name: 'Poker', imageUrl: 'https://example.com/poker.png'),
        ];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: HomeGamesSection(gameService: service),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Chess'), findsOneWidget);
      expect(find.text('Challenge a friend'), findsOneWidget);
      expect(find.text('Ludo'), findsOneWidget);
      expect(find.text('Poker'), findsOneWidget);
      expect(find.text('Teen Patti'), findsNothing);
      expect(service.calls, 1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('shows errors, retries, and renders empty results', (
    tester,
  ) async {
    final service = FakeGameService()..fail = true;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: HomeGamesSection(gameService: service)),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Unable to load games.'), findsOneWidget);
    service.fail = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('No games available yet.'), findsOneWidget);
    expect(service.calls, 2);
  });
}
