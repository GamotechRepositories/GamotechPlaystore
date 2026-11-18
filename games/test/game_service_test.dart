import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:games/services/game_service.dart';

void main() {
  test('fetches games over HTTP and preserves API order', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    var status = 200;
    var body = jsonEncode({
      'games': [
        {
          'name': 'Teen Patti',
          'linkUrl': 'https://example.com/play/teen-patti',
          'imageUrl': 'https://example.com/teen-patti.png',
        },
        {'name': 'Ludo', 'imageUrl': 'https://example.com/ludo.png'},
      ],
    });
    server.listen((request) async {
      expect(request.method, 'GET');
      expect(request.uri.path, '/api/v1/games');
      expect(request.headers.value('Accept'), 'application/json');
      request.response.statusCode = status;
      request.response.write(body);
      await request.response.close();
    });
    final service = GameService(
      baseUrl: 'http://127.0.0.1:${server.port}/api/v1/',
    );
    final games = await service.fetchGames();
    expect(games.map((game) => game.name), ['Teen Patti', 'Ludo']);
    expect(games.first.imageUrl, 'https://example.com/teen-patti.png');
    expect(
      games.first.playUri.toString(),
      'https://example.com/play/teen-patti',
    );
    expect(games.last.playUri, isNull);

    body = '{"games":[]}';
    expect(await service.fetchGames(), isEmpty);

    for (final invalid in [
      '<html>Error</html>',
      '{}',
      '{"games":[null]}',
      '{"games":[{"name":"Ludo","imageUrl":"javascript:alert(1)"}]}',
    ]) {
      body = invalid;
      await expectLater(service.fetchGames(), throwsA(isA<GameException>()));
    }

    status = 500;
    body = '<html>Proxy error</html>';
    await expectLater(service.fetchGames(), throwsA(isA<GameException>()));
  });

  test('only HTTP and HTTPS game links can be played', () {
    for (final link in [
      null,
      '',
      'javascript:alert(1)',
      'file:///tmp/game',
      'not-a-url',
    ]) {
      final game = Game.fromJson({
        'name': 'Ludo',
        'imageUrl': 'https://example.com/ludo.png',
        'linkUrl': link,
      });
      expect(game.playUri, isNull);
    }
  });

  test('rejects an invalid API base URL', () async {
    await expectLater(
      GameService(baseUrl: '').fetchGames(),
      throwsA(isA<GameException>()),
    );
  });
}
