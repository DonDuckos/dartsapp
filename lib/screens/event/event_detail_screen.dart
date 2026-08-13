import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/event.dart';
import '../../providers/favorites_provider.dart';
import '../../providers/repository_providers.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../widgets/favorite_diamond.dart';
import '../../widgets/live_badge.dart';

class EventDetailScreen extends ConsumerWidget {
  const EventDetailScreen({super.key, required this.eventId});

  final String eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoritesProvider);
    final event = ref.watch(eventByIdProvider(eventId)).value;
    final standings = ref.watch(standingsProvider(eventId)).value ?? const [];
    final players = ref.watch(rankedPlayersProvider).value ?? const [];
    final playerById = {for (final p in players) p.id: p};

    return Scaffold(
      appBar: AppBar(title: Text(event?.name ?? '', overflow: TextOverflow.ellipsis)),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (event?.status == EventStatus.live)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: AppColors.live.withValues(alpha: 0.45)),
                  ),
                  child: const LiveLabel(),
                ),
              ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.only(bottom: 8),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: AppColors.accent, width: 2)),
                  ),
                  child: Text('Tabelle', style: AppTypography.body(size: 13, weight: FontWeight.w600)),
                ),
                const SizedBox(width: 20),
                Text('Turnierbaum', style: AppTypography.body(size: 13, color: AppColors.inkFaint)),
              ],
            ),
            const Divider(height: 24, color: AppColors.hairline),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columnSpacing: 18,
                  headingRowHeight: 32,
                  dataRowMinHeight: 40,
                  dataRowMaxHeight: 44,
                  dividerThickness: 0.5,
                  headingTextStyle: AppTypography.mono(size: 10, color: AppColors.inkFaint),
                  dataTextStyle: AppTypography.mono(size: 12, color: AppColors.inkMuted),
                  columns: const [
                    DataColumn(label: Text('#')),
                    DataColumn(label: Text('SPIELER')),
                    DataColumn(label: Text('S-N')),
                    DataColumn(label: Text('LEGS')),
                    DataColumn(label: Text('NÄ. GEGNER')),
                  ],
                  rows: [
                    for (final entry in standings)
                      DataRow(
                        color: favorites.contains(entry.playerId)
                            ? WidgetStatePropertyAll(AppColors.accent.withValues(alpha: 0.06))
                            : null,
                        cells: [
                          DataCell(Text('${entry.position}')),
                          DataCell(Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (favorites.contains(entry.playerId)) ...[
                                const FavoriteDiamond(active: true, size: 7),
                                const SizedBox(width: 6),
                              ],
                              Text(playerById[entry.playerId]?.name ?? '',
                                  style: AppTypography.body(size: 12)),
                            ],
                          )),
                          DataCell(Text('${entry.wins}-${entry.losses}')),
                          DataCell(Text('${entry.legsFor}-${entry.legsAgainst}')),
                          DataCell(Text(entry.nextOpponentPlayerId == null
                              ? '—'
                              : playerById[entry.nextOpponentPlayerId]?.name ?? '—')),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
