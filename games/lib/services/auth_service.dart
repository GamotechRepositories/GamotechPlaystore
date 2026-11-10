import 'dart:async';
import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class AuthException implements Exception {
  const AuthException(this.message);
  final String message;
}

typedef SignUpException = AuthException;

class AuthSession {
  const AuthSession({
    required this.token,
    required this.username,
    required this.email,
  });
  final String token;
  final String username;
  final String email;
}

class AuthService {
  AuthService({this.client, this.baseUrl});

  final http.Client? client;
  final String? baseUrl;

  Future<void> signUp({
    required String username,
    required String email,
    required String password,
  }) async {
    await _post('signup', {
      'username': username.trim(),
      'email': email.trim(),
      'password': password,
    }, expectedStatus: 201);
  }

  Future<AuthSession> signIn({
    required String email,
    required String password,
  }) async {
    final body = await _post('signin', {
      'email': email.trim(),
      'password': password,
    }, expectedStatus: 200);
    final user = body['user'];
    if (body['token'] is! String ||
        (body['token'] as String).isEmpty ||
        user is! Map<String, dynamic> ||
        user['username'] is! String ||
        user['email'] is! String) {
      throw const AuthException(
        'The server returned an invalid sign-in response.',
      );
    }
    return AuthSession(
      token: body['token'] as String,
      username: user['username'] as String,
      email: user['email'] as String,
    );
  }

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, String> data, {
    required int expectedStatus,
  }) async {
    final baseUrl =
        this.baseUrl ??
        (dotenv.isInitialized ? dotenv.get('API_BASE_URL', fallback: '') : '');
    final uri = Uri.tryParse(
      '${baseUrl.replaceFirst(RegExp(r'/+$'), '')}/$path',
    );
    if (uri == null ||
        !uri.hasAuthority ||
        !['http', 'https'].contains(uri.scheme)) {
      throw const AuthException(
        'The server address is not configured correctly.',
      );
    }
    final client = this.client ?? http.Client();
    try {
      final response = await client
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(data),
          )
          .timeout(const Duration(seconds: 15));
      Map<String, dynamic>? body;
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) body = decoded;
      } on FormatException {
        // A proxy may return an HTML error page.
      }
      if (response.statusCode == expectedStatus) {
        if (body == null) {
          throw const AuthException('The server returned an invalid response.');
        }
        return body;
      }
      var message = 'Unable to complete your request. Please try again.';
      if (body?['errors'] is List) {
        final errors = (body!['errors'] as List).whereType<String>().toList();
        if (errors.isNotEmpty) message = errors.join('\n');
      } else if (body?['message'] is String) {
        message = body!['message'] as String;
      }
      throw AuthException(message);
    } on TimeoutException {
      throw const AuthException(
        'The server took too long to respond. Please try again.',
      );
    } on http.ClientException {
      throw const AuthException(
        'Cannot reach the server. Check your connection and try again.',
      );
    } finally {
      if (this.client == null) client.close();
    }
  }
}
