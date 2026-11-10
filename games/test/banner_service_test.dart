import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:games/services/banner_service.dart';

void main() {
  test('fetches home banners over HTTP and preserves API order', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    var status = 200;
    var body = jsonEncode({
      'banners': [
        {
          'title': 'Teen Patti',
          'imageUrl': 'https://example.com/teen-patti.png',
        },
        {'title': 'Ludo', 'imageUrl': 'https://example.com/ludo.png'},
      ],
    });
    server.listen((request) async {
      expect(request.method, 'GET');
      expect(request.uri.path, '/api/v1/home-banners');
      expect(request.headers.value('Accept'), 'application/json');
      request.response.statusCode = status;
      request.response.write(body);
      await request.response.close();
    });
    final service = BannerService(
      baseUrl: 'http://127.0.0.1:${server.port}/api/v1/',
    );
    final banners = await service.fetchHomeBanners();
    expect(banners.map((banner) => banner.title), ['Teen Patti', 'Ludo']);
    expect(banners.first.imageUrl, 'https://example.com/teen-patti.png');

    body = '{"banners":[]}';
    expect(await service.fetchHomeBanners(), isEmpty);

    for (final invalid in [
      '<html>Error</html>',
      '{}',
      '{"banners":[null]}',
      '{"banners":[{"title":"Ludo","imageUrl":"javascript:alert(1)"}]}',
    ]) {
      body = invalid;
      await expectLater(
        service.fetchHomeBanners(),
        throwsA(isA<BannerException>()),
      );
    }

    status = 500;
    body = '<html>Proxy error</html>';
    await expectLater(
      service.fetchHomeBanners(),
      throwsA(isA<BannerException>()),
    );
  });

  test('rejects an invalid API base URL', () async {
    await expectLater(
      BannerService(baseUrl: '').fetchHomeBanners(),
      throwsA(isA<BannerException>()),
    );
  });
}
