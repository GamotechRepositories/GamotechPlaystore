import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:games/services/auth_service.dart';

void main() {
  test(
    'Auth service sends signup JSON and handles server errors over HTTP',
    () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => server.close(force: true));
      var status = 201;
      var body = '{"message":"User created successfully"}';
      final requests = <Map<String, dynamic>>[];
      server.listen((request) async {
        expect(request.method, 'POST');
        expect(request.uri.path, '/api/v1/signup');
        requests.add(
          jsonDecode(await utf8.decoder.bind(request).join())
              as Map<String, dynamic>,
        );
        request.response.statusCode = status;
        request.response.write(body);
        await request.response.close();
      });
      final service = AuthService(
        baseUrl: 'http://127.0.0.1:${server.port}/api/v1/',
      );
      Future<void> submit() => service.signUp(
        username: ' player1 ',
        email: ' player@example.com ',
        password: 'password123',
      );
      await submit();
      expect(requests.single, {
        'username': 'player1',
        'email': 'player@example.com',
        'password': 'password123',
      });
      status = 409;
      body = '{"message":"Email or username already exists"}';
      await expectLater(
        submit(),
        throwsA(
          isA<SignUpException>().having(
            (e) => e.message,
            'message',
            'Email or username already exists',
          ),
        ),
      );
      status = 500;
      body = '<html>Server error</html>';
      await expectLater(
        submit(),
        throwsA(
          isA<SignUpException>().having(
            (e) => e.message,
            'message',
            contains('Please try again'),
          ),
        ),
      );
    },
  );
  test(
    'Sign-in service parses sessions and reports invalid credentials over HTTP',
    () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => server.close(force: true));
      var status = 200;
      var body =
          '{"token":"signed-token","user":{"username":"player1","email":"player@example.com"}}';
      server.listen((request) async {
        expect(request.uri.path, '/api/v1/signin');
        final data = jsonDecode(await utf8.decoder.bind(request).join());
        expect(data, {
          'email': 'player@example.com',
          'password': 'password123',
        });
        request.response.statusCode = status;
        request.response.write(body);
        await request.response.close();
      });
      final service = AuthService(
        baseUrl: 'http://127.0.0.1:${server.port}/api/v1',
      );
      Future<AuthSession> submit() => service.signIn(
        email: ' player@example.com ',
        password: 'password123',
      );
      final session = await submit();
      expect(session.token, 'signed-token');
      expect(session.username, 'player1');
      status = 401;
      body = '{"message":"Invalid email or password"}';
      await expectLater(
        submit(),
        throwsA(
          isA<AuthException>().having(
            (e) => e.message,
            'message',
            'Invalid email or password',
          ),
        ),
      );
      status = 200;
      body = '{}';
      await expectLater(submit(), throwsA(isA<AuthException>()));
    },
  );
}
