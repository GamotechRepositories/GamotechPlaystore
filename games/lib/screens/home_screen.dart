import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/banner_service.dart';
import '../services/wallet_service.dart';
import '../widgets/home_banner_carousel.dart';
import '../widgets/daily_bonus_card.dart';
import 'wallet_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.session, this.bannerService});

  final AuthSession session;
  final BannerService? bannerService;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  AuthSession get session => widget.session;
  BannerService? get bannerService => widget.bannerService;
  int? _balance;

  @override
  void initState() {
    super.initState();
    _balance = session.walletBalance;
    _refreshBalance();
  }

  Future<void> _refreshBalance() async {
    try {
      final wallet = await WalletService().fetch(session.token);
      if (mounted) setState(() => _balance = wallet.balance);
    } on WalletException {
      // A failed refresh must not present the sign-in snapshot as current.
      if (mounted) setState(() => _balance = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    const red = Color(0xFFD32F2F);
    const gold = Color(0xFFFFD166);
    const black = Color(0xFF0B0B0B);
    final theme = Theme.of(context);
    final colors =
        ColorScheme.fromSeed(
          seedColor: red,
          brightness: Brightness.dark,
        ).copyWith(
          primary: red,
          onPrimary: Colors.white,
          secondary: gold,
          onSecondary: black,
          surface: black,
          onSurface: Colors.white,
          onSurfaceVariant: const Color(0xFFCCCCCC),
          surfaceContainerLow: const Color(0xFF161616),
          surfaceContainer: const Color(0xFF1C1C1C),
          surfaceContainerHigh: const Color(0xFF242424),
          surfaceContainerHighest: const Color(0xFF2C2C2C),
          outline: const Color(0xFF777777),
        );

    return Theme(
      data: theme.copyWith(
        colorScheme: colors,
        scaffoldBackgroundColor: black,
        textTheme: theme.textTheme.apply(
          bodyColor: Colors.white,
          displayColor: gold,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: black,
          foregroundColor: gold,
          surfaceTintColor: Colors.transparent,
        ),
        iconTheme: const IconThemeData(color: gold),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: colors.onSurface),
        ),
        progressIndicatorTheme: const ProgressIndicatorThemeData(color: red),
      ),
      child: Builder(builder: _buildHome),
    );
  }

  void _openPage(BuildContext context, Widget page) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => Theme(data: Theme.of(context), child: page),
      ),
    );
  }

  Widget _buildHome(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(session.username, overflow: TextOverflow.ellipsis),
        actions: [
          TextButton.icon(
            onPressed: () => _openPage(
              context,
              WalletScreen(
                session: session,
                onBalanceChanged: (balance) {
                  if (mounted) setState(() => _balance = balance);
                },
              ),
            ),
            icon: Icon(
              Icons.account_balance_wallet_rounded,
              color: colors.secondary,
            ),
            label: SizedBox(
              width: 96,
              child: Text(
                _balance == null
                    ? 'Unavailable'
                    : '₹${(_balance! / 100).toStringAsFixed(2)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: colors.secondary),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Profile',
            onPressed: () async {
              final signOut = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) => Theme(
                    data: Theme.of(context),
                    child: ProfileScreen(session: session),
                  ),
                ),
              );
              if (signOut == true && context.mounted) {
                Navigator.of(context).pop();
              }
            },
            icon: const Icon(Icons.account_circle_rounded),
          ),
          const SizedBox(width: 8),
        ],
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 960),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  HomeBannerCarousel(bannerService: bannerService),
                  const SizedBox(height: 24),
                  DailyBonusCard(
                    token: session.token,
                    onBalanceChanged: (balance) {
                      if (mounted) setState(() => _balance = balance);
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
