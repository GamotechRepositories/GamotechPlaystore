import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class DailyBonusCard extends StatefulWidget {
  const DailyBonusCard({
    super.key,
    required this.token,
    required this.onBalanceChanged,
  });
  final String token;
  final ValueChanged<int> onBalanceChanged;
  @override
  State<DailyBonusCard> createState() => _DailyBonusCardState();
}

class _DailyBonusCardState extends State<DailyBonusCard> {
  bool _busy = false;
  bool _claimed = false;
  int? _amount;
  String? _error;
  DateTime? _nextClaim;

  @override
  void initState() {
    super.initState();
    _request();
  }

  Future<void> _request({bool claim = false}) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final client = http.Client();
    try {
      final base = dotenv.isInitialized
          ? dotenv.get('API_BASE_URL', fallback: '')
          : '';
      final uri = Uri.tryParse(
        '${base.replaceFirst(RegExp(r'/+$'), '')}/wallet/daily-bonus${claim ? '/claim' : ''}',
      );
      if (uri == null ||
          !uri.hasAuthority ||
          !['http', 'https'].contains(uri.scheme)) {
        throw const FormatException();
      }
      final headers = {
        'Authorization': 'Bearer ${widget.token}',
        'Accept': 'application/json',
      };
      final response =
          await (claim
                  ? client.post(uri, headers: headers)
                  : client.get(uri, headers: headers))
              .timeout(const Duration(seconds: 15));
      if (!mounted) return;
      if (response.statusCode == 409) {
        setState(() => _claimed = true);
        return;
      }
      if (response.statusCode != 200) {
        setState(
          () => _error = response.statusCode == 401
              ? 'Please sign in again to claim your bonus.'
              : 'Daily bonus is unavailable. Please try again.',
        );
        return;
      }
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final amount = body['amount'] as int;
      final claimed = body['claimed'] as bool;
      final nextClaim = DateTime.parse(body['nextClaimAt'] as String).toLocal();
      if (amount <= 0) throw const FormatException();
      final balance = claim
          ? (body['wallet'] as Map<String, dynamic>)['balance'] as int
          : null;
      setState(() {
        _amount = amount;
        _claimed = claimed;
        _nextClaim = nextClaim;
      });
      if (balance != null) widget.onBalanceChanged(balance);
    } on Object {
      if (mounted) {
        setState(
          () => _error =
              'Could not load your bonus. Check your connection and retry.',
        );
      }
    } finally {
      client.close();
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final canClaim =
        _amount != null &&
        (!_claimed ||
            (_nextClaim != null && DateTime.now().isAfter(_nextClaim!)));
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  Icons.card_giftcard_rounded,
                  color: colors.secondary,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Daily Bonus',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: colors.secondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _amount == null
                  ? 'Come back each day for a wallet bonus.'
                  : 'Claim ₹${(_amount! / 100).toStringAsFixed(2)} for your wallet each day.',
            ),
            if (_claimed && !canClaim) ...[
              const SizedBox(height: 8),
              const Text('Today’s bonus is claimed. Come back tomorrow!'),
            ],
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: TextStyle(color: colors.error)),
            ],
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _busy || (_claimed && !canClaim)
                  ? null
                  : () => _request(claim: canClaim),
              icon: Icon(
                _claimed && !canClaim
                    ? Icons.check_circle_rounded
                    : Icons.redeem_rounded,
              ),
              label: Text(
                _busy
                    ? 'Loading…'
                    : _claimed && !canClaim
                    ? 'Claimed'
                    : _amount == null
                    ? 'Retry'
                    : 'Claim daily bonus',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
