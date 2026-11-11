import 'package:flutter/material.dart';

import '../services/game_service.dart';

class HomeGamesSection extends StatefulWidget {
  const HomeGamesSection({super.key, this.gameService});

  final GameService? gameService;

  @override
  State<HomeGamesSection> createState() => _HomeGamesSectionState();
}

class _HomeGamesSectionState extends State<HomeGamesSection> {
  late Future<List<Game>> _games;

  @override
  void initState() {
    super.initState();
    _games = (widget.gameService ?? GameService()).fetchGames();
  }

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
        FutureBuilder<List<Game>>(
          future: _games,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Padding(
                padding: EdgeInsets.all(24),
                child: Center(
                  child: CircularProgressIndicator(
                    semanticsLabel: 'Loading games',
                  ),
                ),
              );
            }
            if (snapshot.hasError) {
              final error = snapshot.error;
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        error is GameException
                            ? error.message
                            : 'Unable to load games. Please try again.',
                        textAlign: TextAlign.center,
                      ),
                      TextButton.icon(
                        onPressed: () => setState(() {
                          _games = (widget.gameService ?? GameService())
                              .fetchGames();
                        }),
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              );
            }
            final games = snapshot.data ?? [];
            if (games.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No games available yet.',
                  textAlign: TextAlign.center,
                ),
              );
            }
            return Column(
              children: [
                for (var row = 0; row < games.length; row += 2) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _GameCard(game: games[row])),
                      const SizedBox(width: 12),
                      Expanded(
                        child: row + 1 < games.length
                            ? _GameCard(game: games[row + 1])
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                  if (row + 2 < games.length) const SizedBox(height: 12),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}

class _GameCard extends StatelessWidget {
  const _GameCard({required this.game});
  final Game game;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFF141414), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: 4 / 3,
                child: ColoredBox(
                  color: colors.surfaceContainerHighest,
                  child: Image.network(
                    game.imageUrl,
                    fit: BoxFit.cover,
                    excludeFromSemantics: true,
                    loadingBuilder: (context, child, progress) =>
                        progress == null
                        ? child
                        : const Center(
                            child: CircularProgressIndicator(
                              semanticsLabel: 'Loading game image',
                            ),
                          ),
                    errorBuilder: (context, error, stackTrace) => const Center(
                      child: Icon(Icons.videogame_asset_rounded, size: 40),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              game.name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            if (game.description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                game.description,
                style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
