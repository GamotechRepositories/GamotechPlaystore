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
    final isClaimed = _claimed && !canClaim;
    const claimedGreen = Color(0xFF8BD65A);
    const textSize = 12.0;
    final description = _amount == null
        ? 'Come back each day for a wallet bonus.'
        : 'Claim ${(_amount! / 100).toStringAsFixed(2)} coins for your wallet each day.';

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.secondary.withValues(alpha: 0.75)),
        gradient: const RadialGradient(
          center: Alignment(-0.85, -0.55),
          radius: 1.25,
          colors: [Color(0xFF70410C), Color(0xFF21160E), Color(0xFF100D0A)],
          stops: [0, 0.52, 1],
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Center(
              child: ExcludeSemantics(
                child: Stack(
                  children: [
                    Image.asset(
                      'assets/images/box.png',
                      width: 260,
                      fit: BoxFit.contain,
                    ),
                    const Positioned.fill(
                      child: IconTheme(
                        data: IconThemeData(
                          color: Color(0xFFFFD166),
                          shadows: [
                            Shadow(color: Color(0xFFFFA000), blurRadius: 8),
                          ],
                        ),
                        child: Stack(
                          children: [
                            Align(
                              alignment: Alignment(-0.85, -0.75),
                              child: Icon(Icons.auto_awesome, size: 14),
                            ),
                            Align(
                              alignment: Alignment(0.85, -0.65),
                              child: Icon(Icons.auto_awesome, size: 12),
                            ),
                            Align(
                              alignment: Alignment(-0.72, 0.82),
                              child: Icon(Icons.auto_awesome, size: 10),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            flex: 6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.event_available_outlined,
                      color: colors.secondary,
                      size: 22,
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        'Daily Bonus',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: colors.secondary,
                          fontWeight: FontWeight.bold,
                          fontSize: textSize,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(description, style: const TextStyle(fontSize: textSize)),
                if (_error != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    _error!,
                    style: TextStyle(color: colors.error, fontSize: textSize),
                  ),
                ],
                const SizedBox(height: 5),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.secondary,
                    foregroundColor: colors.onSecondary,
                    disabledBackgroundColor: isClaimed
                        ? const Color(0xFF293020)
                        : null,
                    disabledForegroundColor: isClaimed ? claimedGreen : null,
                    minimumSize: const Size(0, 28),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 2,
                    ),
                  ),
                  onPressed: _busy || isClaimed
                      ? null
                      : () => _request(claim: canClaim),
                  icon: Icon(
                    isClaimed
                        ? Icons.check_circle_rounded
                        : Icons.redeem_rounded,
                    size: 16,
                  ),
                  label: Text(
                    _busy
                        ? 'Loading…'
                        : isClaimed
                        ? 'Claimed'
                        : _amount == null
                        ? 'Retry'
                        : 'Claim daily bonus',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: textSize),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
