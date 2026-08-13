import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/favorites_provider.dart';
import '../../providers/repository_providers.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../utils/stat_format.dart';
import '../../widgets/favorite_diamond.dart';
import '../../widgets/player_avatar.dart';

class PlayerDetailScreen extends ConsumerWidget {
  const PlayerDetailScreen({super.key, required this.playerId});

  final String playerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final players = ref.watch(rankedPlayersProvider).value;
    final favorites = ref.watch(favoritesProvider);

    if (players == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppColors.accent)));
    }

    final player = players.where((p) => p.id == playerId).firstOrNull;
    if (player == null) {
      return const Scaffold(body: Center(child: Text('Spieler nicht gefunden')));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(player.name),
        actions: [
          FavoriteDiamond(
            active: favorites.contains(player.id),
            size: 11,
            onTap: () => ref.read(favoritesProvider.notifier).toggle(player.id),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PlayerAvatar(photoUrl: player.photoUrl, size: 56),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Platz ${player.rankingPosition} · ${player.country}',
                        style: AppTypography.mono(size: 11, color: AppColors.inkFaint)),
                    const SizedBox(height: 4),
                    Text(player.name, style: AppTypography.body(size: 18, weight: FontWeight.w600)),
                    if (player.photoAttribution != null) ...[
                      const SizedBox(height: 4),
                      Text(player.photoAttribution!,
                          style: AppTypography.mono(size: 9, color: AppColors.inkFaint)),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (player.bio != null) ...[
            const SizedBox(height: 16),
            Text(player.bio!, style: AppTypography.body(size: 13, color: AppColors.inkMuted)),
          ],
          if (player.quote != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: const Border(left: BorderSide(color: AppColors.accent, width: 2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('„${player.quote!}"',
                      style: AppTypography.body(size: 13, weight: FontWeight.w600).copyWith(
                            fontStyle: FontStyle.italic,
                            height: 1.4,
                          )),
                  if (player.quoteSource != null) ...[
                    const SizedBox(height: 6),
                    Text('— ${player.quoteSource}',
                        style: AppTypography.mono(size: 10, color: AppColors.inkFaint)),
                  ],
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          Text('STATISTIK', style: AppTypography.mono(size: 11, color: AppColors.inkFaint)),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 2.1,
            children: [
              _StatTile(label: '3-Dart-Average', value: formatAverage(player.stats.average3Dart)),
              _StatTile(label: 'Checkout-Quote', value: formatPercentage(player.stats.checkoutPercentage)),
              _StatTile(label: '180er', value: formatCount(player.stats.count180s)),
              _StatTile(label: 'High Finish', value: formatCount(player.stats.highFinish)),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(value, style: AppTypography.mono(size: 20, weight: FontWeight.w600, color: AppColors.ink)),
          const SizedBox(height: 2),
          Text(label, style: AppTypography.body(size: 11, color: AppColors.inkFaint)),
        ],
      ),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
