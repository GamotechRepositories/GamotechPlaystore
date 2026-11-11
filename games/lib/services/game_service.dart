import 'dart:async';
import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class GameException implements Exception {
  const GameException(this.message);
  final String message;
}

class Game {
  const Game({
    required this.name,
    required this.imageUrl,
    this.description = '',
  });

  final String name;
  final String imageUrl;
  final String description;

  factory Game.fromJson(Map<String, dynamic> json) {
    final name = json['name'];
    final imageUrl = json['imageUrl'];
    final uri = imageUrl is String ? Uri.tryParse(imageUrl) : null;
    if (name is! String ||
        name.trim().isEmpty ||
        uri == null ||
        !uri.hasAuthority ||
        !['http', 'https'].contains(uri.scheme)) {
      throw const FormatException('Invalid game');
    }
    final description = json['description'];
    if (description != null && description is! String) {
      throw const FormatException('Invalid game description');
    }
    return Game(
      name: name,
      imageUrl: imageUrl as String,
      description: description as String? ?? '',
    );
  }
}

class GameService {
  GameService({this.client, this.baseUrl});

  final http.Client? client;
  final String? baseUrl;

  Future<List<Game>> fetchGames() async {
    final base =
        baseUrl ??
        (dotenv.isInitialized ? dotenv.get('API_BASE_URL', fallback: '') : '');
    final uri = Uri.tryParse('${base.replaceFirst(RegExp(r'/+$'), '')}/games');
    if (uri == null ||
        !uri.hasAuthority ||
        !['http', 'https'].contains(uri.scheme)) {
      throw const GameException(
        'The server address is not configured correctly.',
      );
    }

    final client = this.client ?? http.Client();
    try {
      final response = await client
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) {
        throw const GameException('Unable to load games. Please try again.');
      }
      final body = jsonDecode(response.body);
      if (body is! Map<String, dynamic> || body['games'] is! List) {
        throw const FormatException('Invalid game response');
      }
      return (body['games'] as List).map((item) {
        if (item is! Map<String, dynamic>) {
          throw const FormatException('Invalid game');
        }
        return Game.fromJson(item);
      }).toList();
    } on TimeoutException {
      throw const GameException(
        'Games took too long to load. Please try again.',
      );
    } on http.ClientException {
      throw const GameException(
        'Cannot load games. Check your connection and try again.',
      );
    } on FormatException {
      throw const GameException(
        'The server returned invalid games. Please try again.',
      );
    } finally {
      if (this.client == null) client.close();
    }
  }
}
