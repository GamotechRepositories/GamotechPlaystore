import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/wallet_service.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({
    super.key,
    required this.session,
    this.walletService,
    this.onBalanceChanged,
  });
  final AuthSession session;
  final WalletService? walletService;
  final ValueChanged<int>? onBalanceChanged;
  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  WalletData? _data;
  String? _error;
  bool _loading = false;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool more = false}) async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final next = await (widget.walletService ?? WalletService()).fetch(
        widget.session.token,
        page: more ? _page + 1 : 1,
      );
      if (!mounted) return;
      setState(() {
        _data = WalletData(next.balance, [
          if (more) ...?_data?.records,
          ...next.records,
        ], next.hasMore);
        _page = more ? _page + 1 : 1;
      });
      widget.onBalanceChanged?.call(next.balance);
    } on WalletException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wallet'),
        actions: [
          IconButton(
            tooltip: 'Refresh wallet',
            onPressed: _loading ? null : () => _load(),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _load(),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.account_balance_wallet_rounded,
                                color: colors.secondary,
                                size: 36,
                              ),
                              const SizedBox(height: 16),
                              Text('${widget.session.username}’s wallet'),
                              const SizedBox(height: 8),
                              Text(
                                _data?.formattedBalance ?? '—',
                                style: Theme.of(
                                  context,
                                ).textTheme.headlineLarge,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _error != null && _data != null
                                    ? 'Last loaded balance • INR'
                                    : 'Available balance • INR',
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Transaction history',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      if (_loading)
                        const LinearProgressIndicator(
                          semanticsLabel: 'Loading wallet',
                        ),
                      if (_error != null) ...[
                        Text(_error!, semanticsLabel: _error),
                        TextButton(
                          onPressed: () =>
                              _load(more: _page > 0 && _data!.hasMore),
                          child: const Text('Retry'),
                        ),
                      ],
                      if (_data != null && _data!.records.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Text(
                            'No transactions yet. Your wallet activity will appear here.',
                          ),
                        ),
                      for (final record in _data?.records ?? <WalletActivity>[])
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  record.reason
                                      .replaceAll('_', ' ')
                                      .toUpperCase(),
                                  style: TextStyle(color: colors.secondary),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${record.type == 'credit' ? '+' : '−'}₹${(record.amount / 100).toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  record.type == 'credit' ? 'Credit' : 'Debit',
                                ),
                                Text(
                                  MaterialLocalizations.of(
                                    context,
                                  ).formatMediumDate(record.date),
                                ),
                                Text('Reference: ${record.reference}'),
                              ],
                            ),
                          ),
                        ),
                      if (_data?.hasMore == true && _error == null)
                        TextButton(
                          onPressed: _loading ? null : () => _load(more: true),
                          child: const Text('Load more'),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
