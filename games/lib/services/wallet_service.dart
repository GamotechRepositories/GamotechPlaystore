import 'dart:async';
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class WalletException implements Exception {
  const WalletException(this.message);
  final String message;
}

class WalletActivity {
  WalletActivity(Map<String, dynamic> json)
    : type = json['type'] as String,
      amount = json['amount'] as int,
      reason = json['reason'] as String,
      reference = json['reference'] as String,
      date = DateTime.parse(json['createdAt'] as String).toLocal();
  final String type, reason, reference;
  final int amount;
  final DateTime date;
}

class WalletData {
  const WalletData(this.balance, this.records, this.hasMore);
  final int balance;
  final List<WalletActivity> records;
  final bool hasMore;
  String get formattedBalance => '₹${(balance / 100).toStringAsFixed(2)}';
}

class WalletService {
  WalletService({this.client, this.baseUrl});
  final http.Client? client;
  final String? baseUrl;

  Future<WalletData> fetch(String token, {int page = 1}) async {
    final base =
        baseUrl ??
        (dotenv.isInitialized ? dotenv.get('API_BASE_URL', fallback: '') : '');
    final uri = Uri.tryParse(
      '${base.replaceFirst(RegExp(r'/+$'), '')}/wallet?page=$page',
    );
    if (uri == null ||
        !uri.hasAuthority ||
        !['http', 'https'].contains(uri.scheme)) {
      throw const WalletException(
        'The server address is not configured correctly.',
      );
    }
    final connection = client ?? http.Client();
    try {
      final response = await connection
          .get(
            uri,
            headers: {
              'Authorization': 'Bearer $token',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 401) {
        throw const WalletException(
          'Your session has expired. Please sign in again.',
        );
      }
      if (response.statusCode == 404) {
        throw const WalletException('No wallet is linked to your account.');
      }
      if (response.statusCode != 200) {
        throw const WalletException(
          'Unable to load your wallet. Please try again.',
        );
      }
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final wallet = body['wallet'] as Map<String, dynamic>;
      if (wallet['currency'] != 'INR' ||
          wallet['balance'] is! int ||
          (wallet['balance'] as int) < 0 ||
          body['hasMore'] is! bool) {
        throw const FormatException();
      }
      return WalletData(
        wallet['balance'] as int,
        (body['records'] as List)
            .map((item) => WalletActivity(item as Map<String, dynamic>))
            .toList(),
        body['hasMore'] as bool,
      );
    } on TimeoutException {
      throw const WalletException(
        'Your wallet took too long to load. Please try again.',
      );
    } on http.ClientException {
      throw const WalletException(
        'Cannot reach your wallet. Check your connection.',
      );
    } on FormatException {
      throw const WalletException(
        'The server returned an invalid wallet response.',
      );
    } on TypeError {
      throw const WalletException(
        'The server returned an invalid wallet response.',
      );
    } finally {
      if (client == null) connection.close();
    }
  }
}
