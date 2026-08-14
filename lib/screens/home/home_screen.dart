import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/match.dart';
import '../../models/player.dart';
import '../../providers/favorites_provider.dart';
import '../../providers/repository_providers.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../utils/event_format.dart';
import '../../utils/relative_time.dart';
import '../../widgets/live_badge.dart';
import '../../widgets/news_row.dart';
import '../../widgets/section_caption.dart';
import '../event/event_detail_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final players = ref.watch(rankedPlayersProvider).value;
    final event = ref.watch(currentEventProvider).value;
    final news = ref.watch(newsProvider).value ?? const [];
    final favorites = ref.watch(favoritesProvider);

    final liveMatch = event == null ? null : ref.watch(liveMatchProvider(event.id)).value;
    final nextMatch = event == null ? null : ref.watch(nextMatchProvider(event.id)).value;
    final flash = news.where((n) => n.isFlash).firstOrNull;

    if (players == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppColors.accent)));
    }

    final playerById = {for (final p in players) p.id: p};
    final favoritePlayers = favorites.map((id) => playerById[id]).whereType<Player>().toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('DartsApp', style: AppTypography.mono(size: 13, weight: FontWeight.w600, color: AppColors.inkMuted)),
        centerTitle: false,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            width: 6,
            height: 6,
            decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          if (event != null && liveMatch != null)
            _HeroLiveCard(
              eventName: event.name,
              round: event.currentRound ?? '',
              match: liveMatch,
              nextMatch: nextMatch,
              playerById: playerById,
              onTap: () => Navigator.of(context, rootNavigator: true).push(
                MaterialPageRoute(builder: (_) => EventDetailScreen(eventId: event.id)),
              ),
            )
          else if (event != null && nextMatch != null)
            _HeroNextCard(
              eventName: event.name,
              match: nextMatch,
              playerById: playerById,
              onTap: () => Navigator.of(context, rootNavigator: true).push(
                MaterialPageRoute(builder: (_) => EventDetailScreen(eventId: event.id)),
              ),
            )
          else if (event != null)
            _EventOnlyCard(eventName: event.name)
          else
            const _EmptyHero(),
          if (flash != null) ...[
            const SizedBox(height: 14),
            _FlashBanner(headline: flash.title, time: newsDate(flash.publishedAt)),
          ],
          const SizedBox(height: 20),
          const SectionCaption('Deine Favoriten'),
          const SizedBox(height: 8),
          if (favoritePlayers.isEmpty)
            Text('Noch keine Favoriten — in der Rangliste markieren.',
                style: AppTypography.body(size: 12, color: AppColors.inkFaint))
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final p in favoritePlayers)
                  _FavoriteChip(
                    name: p.name,
                    isLive: liveMatch != null && (liveMatch.player1Id == p.id || liveMatch.player2Id == p.id),
                  ),
              ],
            ),
          if (news.isNotEmpty) ...[
            const SizedBox(height: 20),
            const SectionCaption('Aktuelle News'),
            const SizedBox(height: 8),
            for (final (index, item) in news.take(3).indexed) ...[
              if (index > 0) const Divider(height: 20, color: AppColors.hairline),
              NewsRow(item: item, highlighted: item.relatedPlayerIds.any(favorites.contains)),
            ],
          ],
        ],
      ),
    );
  }
}

class _EventOnlyCard extends StatelessWidget {
  const _EventOnlyCard({required this.eventName});

  final String eventName;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: AppColors.surface,
        border: Border.all(color: AppColors.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Nächstes Event', style: AppTypography.mono(size: 10, color: AppColors.inkFaint)),
          const SizedBox(height: 6),
          Text(eventName, style: AppTypography.body(size: 16, weight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('Spielplan noch nicht bekannt.', style: AppTypography.body(size: 12, color: AppColors.inkMuted)),
        ],
      ),
    );
  }
}

class _EmptyHero extends StatelessWidget {
  const _EmptyHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: AppColors.surface,
        border: Border.all(color: AppColors.hairline),
      ),
      child: Text('Gerade kein Event geplant.', style: AppTypography.body(size: 13, color: AppColors.inkMuted)),
    );
  }
}

class _HeroLiveCard extends StatelessWidget {
  const _HeroLiveCard({
    required this.eventName,
    required this.round,
    required this.match,
    required this.nextMatch,
    required this.playerById,
    required this.onTap,
  });

  final String eventName;
  final String round;
  final DartsMatch match;
  final DartsMatch? nextMatch;
  final Map<String, Player> playerById;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p1 = playerById[match.player1Id];
    final p2 = playerById[match.player2Id];
    final next1 = nextMatch == null ? null : playerById[nextMatch!.player1Id];
    final next2 = nextMatch == null ? null : playerById[nextMatch!.player2Id];
    // Ein Match kann "live" sein, bevor die Datenquelle schon Sets/Legs
    // meldet (z.B. direkt nach Anwurf) — 0:0 ist in dem Fall der korrekte
    // Anzeigewert, kein fehlender Zustand.
    final score = match.score ?? const MatchScore(sets: (0, 0), legs: (0, 0));

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.hairline),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.surface, AppColors.surface2],
          ),
          boxShadow: [
            BoxShadow(color: AppColors.accent.withValues(alpha: 0.16), blurRadius: 30, offset: const Offset(0, 14)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const LiveLabel(),
                const Spacer(),
                Flexible(
                  child: Text(eventName,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.body(size: 12, color: AppColors.inkFaint)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(round.toUpperCase(), style: AppTypography.mono(size: 10, color: AppColors.inkFaint)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: Text(p1?.name ?? '', style: AppTypography.body(size: 13))),
                Row(
                  children: [
                    Text('${score.sets.$1}', style: AppTypography.display(size: 32).copyWith(
                        shadows: [Shadow(color: AppColors.accent.withValues(alpha: 0.45), blurRadius: 18)])),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(':', style: AppTypography.display(size: 20, weight: FontWeight.w400).copyWith(color: AppColors.inkFaint)),
                    ),
                    Text('${score.sets.$2}', style: AppTypography.display(size: 32)),
                  ],
                ),
                Expanded(
                  child: Text(p2?.name ?? '', textAlign: TextAlign.right, style: AppTypography.body(size: 13)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Center(
              child: Text(
                'Legs ${score.legs.$1} : ${score.legs.$2}'
                '${match.throwingPlayerId == match.player1Id ? " · ${p1?.name} wirft" : match.throwingPlayerId == match.player2Id ? " · ${p2?.name} wirft" : ""}',
                style: AppTypography.mono(size: 11),
              ),
            ),
            if (nextMatch != null) ...[
              const SizedBox(height: 12),
              Container(height: 1, color: AppColors.hairline),
              const SizedBox(height: 10),
              RichText(
                text: TextSpan(
                  style: AppTypography.body(size: 12, color: AppColors.inkMuted),
                  children: [
                    const TextSpan(text: 'Danach: '),
                    TextSpan(text: next1?.name ?? '', style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w600)),
                    const TextSpan(text: ' – '),
                    TextSpan(text: next2?.name ?? '', style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _HeroNextCard extends StatelessWidget {
  const _HeroNextCard({
    required this.eventName,
    required this.match,
    required this.playerById,
    required this.onTap,
  });

  final String eventName;
  final DartsMatch match;
  final Map<String, Player> playerById;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p1 = playerById[match.player1Id];
    final p2 = playerById[match.player2Id];
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: AppColors.surface,
          border: Border.all(color: AppColors.hairline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: AppColors.accent.withValues(alpha: 0.5)),
                  ),
                  child: Text('NÄCHSTES SPIEL',
                      style: AppTypography.mono(size: 10, weight: FontWeight.w600, color: AppColors.accent)),
                ),
                const Spacer(),
                Flexible(
                  child: Text(eventName,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.body(size: 12, color: AppColors.inkFaint)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text('${p1?.name} – ${p2?.name}', style: AppTypography.body(size: 16, weight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(formatMatchDateTime(match.scheduledAt),
                style: AppTypography.mono(size: 11, color: AppColors.inkMuted)),
          ],
        ),
      ),
    );
  }
}

class _FlashBanner extends StatelessWidget {
  const _FlashBanner({required this.headline, required this.time});

  final String headline;
  final String time;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: const Border(left: BorderSide(color: AppColors.flash, width: 2)),
      ),
      child: Row(
        children: [
          Text('EIL', style: AppTypography.mono(size: 10, weight: FontWeight.w600, color: AppColors.flash)),
          const SizedBox(width: 10),
          Expanded(child: Text(headline, style: AppTypography.body(size: 12), maxLines: 2, overflow: TextOverflow.ellipsis)),
          const SizedBox(width: 8),
          Text(time, style: AppTypography.mono(size: 10, color: AppColors.inkFaint)),
        ],
      ),
    );
  }
}

class _FavoriteChip extends StatelessWidget {
  const _FavoriteChip({required this.name, required this.isLive});

  final String name;
  final bool isLive;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.hairline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isLive) ...[const LiveDot(size: 5), const SizedBox(width: 6)],
          Text(name, style: AppTypography.body(size: 12, color: AppColors.inkMuted)),
        ],
      ),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
