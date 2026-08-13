import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/favorites_provider.dart';
import '../../providers/repository_providers.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../widgets/favorite_diamond.dart';
import '../player/player_detail_screen.dart';

class RankingScreen extends ConsumerStatefulWidget {
  const RankingScreen({super.key});

  @override
  ConsumerState<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends ConsumerState<RankingScreen> {
  bool onlyFavorites = false;

  @override
  Widget build(BuildContext context) {
    final players = ref.watch(rankedPlayersProvider).value;
    final favorites = ref.watch(favoritesProvider);

    if (players == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppColors.accent)));
    }

    final visible = onlyFavorites ? players.where((p) => favorites.contains(p.id)).toList() : players;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Weltrangliste'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(28),
          child: Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 10),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('TOP 30', style: AppTypography.mono(size: 11, color: AppColors.inkFaint)),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: FilterChip(
                label: const Text('Nur Favoriten'),
                selected: onlyFavorites,
                onSelected: (v) => setState(() => onlyFavorites = v),
                labelStyle: AppTypography.mono(size: 11, color: onlyFavorites ? AppColors.bg : AppColors.inkMuted),
                backgroundColor: AppColors.surface,
                selectedColor: AppColors.accent,
                side: const BorderSide(color: AppColors.hairline),
                shape: const StadiumBorder(),
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: visible.length,
              separatorBuilder: (_, _) => const Divider(height: 1, color: AppColors.hairline),
              itemBuilder: (context, index) {
                final player = visible[index];
                final isTop = player.rankingPosition <= 3;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  onTap: () => Navigator.of(context, rootNavigator: true).push(
                    MaterialPageRoute(builder: (_) => PlayerDetailScreen(playerId: player.id)),
                  ),
                  leading: SizedBox(
                    width: 28,
                    child: Text(
                      '${player.rankingPosition}',
                      style: AppTypography.mono(
                        size: 13,
                        weight: FontWeight.w600,
                        color: isTop ? AppColors.accent : AppColors.inkFaint,
                      ),
                    ),
                  ),
                  title: Text(player.name, style: AppTypography.body(size: 14)),
                  subtitle: Text(player.country, style: AppTypography.mono(size: 10, color: AppColors.inkFaint)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(player.stats.average3Dart.toStringAsFixed(1),
                          style: AppTypography.mono(size: 12, color: AppColors.inkMuted)),
                      FavoriteDiamond(
                        active: favorites.contains(player.id),
                        onTap: () => ref.read(favoritesProvider.notifier).toggle(player.id),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
