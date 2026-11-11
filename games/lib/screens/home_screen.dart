import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../services/auth_service.dart';
import '../services/banner_service.dart';
import '../services/wallet_service.dart';
import '../widgets/home_banner_carousel.dart';
import '../widgets/daily_bonus_card.dart';
import '../widgets/home_games_section.dart';
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
      backgroundColor: const Color(0xFF080808),
      appBar: AppBar(
        titleSpacing: 12,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              session.username,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14),
            ),
            InkWell(
              onTap: () => _openPage(
                context,
                WalletScreen(
                  session: session,
                  onBalanceChanged: (balance) {
                    if (mounted) setState(() => _balance = balance);
                  },
                ),
              ),
              child: Text(
                _balance == null
                    ? 'Unavailable'
                    : '${(_balance! / 100).toStringAsFixed(2)} coins',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: colors.secondary, fontSize: 11),
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: 144,
            child: FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 32),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
              ),
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                builder: (_) => SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Get Coins',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Coins are for playing only and have no cash value.',
                        ),
                        const SizedBox(height: 16),
                        for (final price in [
                          100,
                          200,
                          300,
                          400,
                          500,
                          600,
                          700,
                          800,
                          900,
                          1000,
                        ])
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: SvgPicture.asset(
                              'assets/icons/coin.svg',
                              width: 24,
                              height: 24,
                            ),
                            title: Text('${price * 10} coins'),
                            trailing: Text('₹$price'),
                          ),
                        const SizedBox(height: 12),
                        const Text(
                          'Purchases will be available when Google Play Billing is connected.',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SvgPicture.asset(
                    'assets/icons/coin.svg',
                    width: 20,
                    height: 20,
                    excludeFromSemantics: true,
                  ),
                  const SizedBox(width: 6),
                  const Flexible(
                    child: Text(
                      'Get Coins +',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
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
                  const SizedBox(height: 12),
                  const HomeGamesSection(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
