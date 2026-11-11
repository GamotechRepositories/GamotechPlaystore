import 'package:flutter/material.dart';

class HomeGamesSection extends StatelessWidget {
  const HomeGamesSection({super.key});

  static const _games = [
    (name: 'Ludo', icon: Icons.casino_rounded),
    (name: 'Rummy', icon: Icons.style_rounded),
    (name: 'Poker', icon: Icons.trip_origin_rounded),
    (name: 'Teen Patti', icon: Icons.filter_3_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Games',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: colors.secondary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 8),
        for (var row = 0; row < _games.length; row += 2) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var column = 0; column < 2; column++) ...[
                if (column > 0) const SizedBox(width: 12),
                Expanded(
                  child: Card(
                    margin: EdgeInsets.zero,
                    clipBehavior: Clip.antiAlias,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(
                        color: Color(0xFF141414),
                        width: 1.5,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            height: 100,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  colors.primary.withValues(alpha: 0.3),
                                  const Color(0xFF080808),
                                ],
                              ),
                            ),
                            child: ExcludeSemantics(
                              child: Icon(
                                _games[row + column].icon,
                                color: colors.secondary,
                                size: 48,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _games[row + column].name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Coming soon',
                            style: TextStyle(
                              color: colors.onSurfaceVariant,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (row + 2 < _games.length) const SizedBox(height: 12),
        ],
      ],
    );
  }
}
