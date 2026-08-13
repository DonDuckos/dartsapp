import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/event.dart';
import '../../models/match.dart';
import '../../models/player.dart';
import '../../providers/favorites_provider.dart';
import '../../providers/repository_providers.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../utils/event_format.dart';
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
    final matches = ref.watch(eventMatchesProvider(eventId)).value ?? const [];
    final players = ref.watch(rankedPlayersProvider).value ?? const [];
    final playerById = {for (final p in players) p.id: p};

    return Scaffold(
      appBar: AppBar(title: Text(event?.name ?? '', overflow: TextOverflow.ellipsis)),
      body: event == null
          ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
          : Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _EventInfoCard(event: event),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.only(bottom: 8),
                        decoration: const BoxDecoration(
                          border: Border(bottom: BorderSide(color: AppColors.accent, width: 2)),
                        ),
                        child: Text(standings.isEmpty ? 'Spielplan' : 'Tabelle',
                            style: AppTypography.body(size: 13, weight: FontWeight.w600)),
                      ),
                      if (standings.isNotEmpty) ...[
                        const SizedBox(width: 20),
                        Text('Turnierbaum', style: AppTypography.body(size: 13, color: AppColors.inkFaint)),
                      ],
                    ],
                  ),
                  const Divider(height: 24, color: AppColors.hairline),
                  Expanded(
                    child: standings.isEmpty
                        ? _MatchList(matches: matches, playerById: playerById)
                        : _StandingsTable(standings: standings, playerById: playerById, favorites: favorites),
                  ),
                ],
              ),
            ),
    );
  }
}

class _EventInfoCard extends StatelessWidget {
  const _EventInfoCard({required this.event});

  final DartsEvent event;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (event.status == EventStatus.live)
            const Padding(padding: EdgeInsets.only(bottom: 8), child: LiveLabel()),
          _InfoRow(label: 'Termin', value: formatDateRange(event.startDate, event.endDate)),
          if (event.venue != null) ...[
            const SizedBox(height: 6),
            _InfoRow(label: 'Ort', value: event.venue!),
          ],
          const SizedBox(height: 6),
          _InfoRow(label: 'Format', value: formatEventFormat(event.format)),
          if (event.currentRound != null) ...[
            const SizedBox(height: 6),
            _InfoRow(label: 'Runde', value: event.currentRound!),
          ],
          if (event.preview != null) ...[
            const SizedBox(height: 10),
            Container(height: 1, color: AppColors.hairline),
            const SizedBox(height: 10),
            Text(event.preview!,
                style: AppTypography.body(size: 12, color: AppColors.inkMuted).copyWith(height: 1.5)),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 64,
          child: Text(label.toUpperCase(), style: AppTypography.mono(size: 10, color: AppColors.inkFaint)),
        ),
        Expanded(child: Text(value, style: AppTypography.body(size: 12, color: AppColors.inkMuted))),
      ],
    );
  }
}

class _MatchList extends StatelessWidget {
  const _MatchList({required this.matches, required this.playerById});

  final List<DartsMatch> matches;
  final Map<String, Player> playerById;

  @override
  Widget build(BuildContext context) {
    if (matches.isEmpty) {
      return Center(
        child: Text('Spielplan noch nicht bekannt.', style: AppTypography.body(size: 13, color: AppColors.inkFaint)),
      );
    }

    final sorted = [...matches]..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

    return ListView.separated(
      itemCount: sorted.length,
      separatorBuilder: (_, _) => const Divider(height: 20, color: AppColors.hairline),
      itemBuilder: (context, index) {
        final match = sorted[index];
        final p1 = playerById[match.player1Id];
        final p2 = playerById[match.player2Id];
        return Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${p1?.name ?? match.player1Id} – ${p2?.name ?? match.player2Id}',
                      style: AppTypography.body(size: 13, weight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(formatMatchDateTime(match.scheduledAt),
                      style: AppTypography.mono(size: 11, color: AppColors.inkFaint)),
                ],
              ),
            ),
            if (match.status == MatchStatus.live) const LiveLabel(),
            if (match.status == MatchStatus.finished && match.score != null)
              Text('${match.score!.sets.$1}:${match.score!.sets.$2}',
                  style: AppTypography.mono(size: 13, weight: FontWeight.w600, color: AppColors.ink)),
          ],
        );
      },
    );
  }
}

class _StandingsTable extends StatelessWidget {
  const _StandingsTable({required this.standings, required this.playerById, required this.favorites});

  final List<StandingEntry> standings;
  final Map<String, Player> playerById;
  final Set<String> favorites;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
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
                    Text(playerById[entry.playerId]?.name ?? '', style: AppTypography.body(size: 12)),
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
    );
  }
}
