import 'dart:async';
import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class BannerException implements Exception {
  const BannerException(this.message);
  final String message;
}

class HomeBanner {
  const HomeBanner({required this.title, required this.imageUrl});

  final String title;
  final String imageUrl;

  factory HomeBanner.fromJson(Map<String, dynamic> json) {
    final title = json['title'];
    final imageUrl = json['imageUrl'];
    final uri = imageUrl is String ? Uri.tryParse(imageUrl) : null;
    if (title is! String ||
        title.trim().isEmpty ||
        uri == null ||
        !uri.hasAuthority ||
        !['http', 'https'].contains(uri.scheme)) {
      throw const FormatException('Invalid banner');
    }
    return HomeBanner(title: title, imageUrl: imageUrl as String);
  }
}

class BannerService {
  BannerService({this.client, this.baseUrl});

  final http.Client? client;
  final String? baseUrl;

  Future<List<HomeBanner>> fetchHomeBanners() async {
    final base =
        baseUrl ??
        (dotenv.isInitialized ? dotenv.get('API_BASE_URL', fallback: '') : '');
    final uri = Uri.tryParse(
      '${base.replaceFirst(RegExp(r'/+$'), '')}/home-banners',
    );
    if (uri == null ||
        !uri.hasAuthority ||
        !['http', 'https'].contains(uri.scheme)) {
      throw const BannerException(
        'The server address is not configured correctly.',
      );
    }

    final client = this.client ?? http.Client();
    try {
      final response = await client
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) {
        throw const BannerException(
          'Unable to load banners. Please try again.',
        );
      }
      final body = jsonDecode(response.body);
      if (body is! Map<String, dynamic> || body['banners'] is! List) {
        throw const FormatException('Invalid banner response');
      }
      return (body['banners'] as List).map((item) {
        if (item is! Map<String, dynamic>) {
          throw const FormatException('Invalid banner');
        }
        return HomeBanner.fromJson(item);
      }).toList();
    } on TimeoutException {
      throw const BannerException(
        'Banners took too long to load. Please try again.',
      );
    } on http.ClientException {
      throw const BannerException(
        'Cannot load banners. Check your connection and try again.',
      );
    } on FormatException {
      throw const BannerException(
        'The server returned invalid banners. Please try again.',
      );
    } finally {
      if (this.client == null) client.close();
    }
  }
}
