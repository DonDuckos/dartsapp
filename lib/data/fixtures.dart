import '../models/event.dart';
import '../models/match.dart';
import '../models/news_item.dart';
import '../models/player.dart';

/// Platzhalterdaten für die Mock-Phase — Namen und Werte sind erfunden
/// (siehe CLAUDE.md), decken sich mit dem freigegebenen Screen-Mockup.
/// Sobald Firestore angebunden ist, ersetzen echte Repository-Implementierungen
/// diese Fixtures 1:1 hinter denselben Interfaces.
class Fixtures {
  const Fixtures._();

  static const players = <Player>[
    Player(
      id: 'vandijk',
      name: 'J. van Dijk',
      country: 'NL',
      rankingPosition: 1,
      stats: PlayerStats(average3Dart: 98.4, checkoutPercentage: 44.1, count180s: 61, highFinish: 161),
      bio: 'Amsterdam · Rechtshänder · Profi seit 2016',
    ),
    Player(
      id: 'krueger',
      name: 'M. Krüger',
      country: 'DE',
      rankingPosition: 2,
      stats: PlayerStats(average3Dart: 96.9, checkoutPercentage: 41.8, count180s: 54, highFinish: 170),
      bio: 'Köln · Rechtshänder · Profi seit 2018',
    ),
    Player(
      id: 'petrov',
      name: 'I. Petrov',
      country: 'BG',
      rankingPosition: 3,
      stats: PlayerStats(average3Dart: 95.1, checkoutPercentage: 40.2, count180s: 49, highFinish: 156),
    ),
    Player(
      id: 'novak',
      name: 'T. Novak',
      country: 'SI',
      rankingPosition: 4,
      stats: PlayerStats(average3Dart: 93.7, checkoutPercentage: 39.6, count180s: 45, highFinish: 167),
    ),
    Player(
      id: 'fischer',
      name: 'L. Fischer',
      country: 'DE',
      rankingPosition: 5,
      stats: PlayerStats(average3Dart: 92.8, checkoutPercentage: 38.9, count180s: 42, highFinish: 148),
      bio: 'Stuttgart · Linkshänder · Profi seit 2020',
    ),
    Player(
      id: 'bakker',
      name: 'S. Bakker',
      country: 'NL',
      rankingPosition: 6,
      stats: PlayerStats(average3Dart: 91.6, checkoutPercentage: 38.1, count180s: 38, highFinish: 140),
    ),
    Player(
      id: 'keller',
      name: 'D. Keller',
      country: 'AT',
      rankingPosition: 7,
      stats: PlayerStats(average3Dart: 90.9, checkoutPercentage: 37.4, count180s: 36, highFinish: 132),
    ),
    Player(
      id: 'albrecht',
      name: 'N. Albrecht',
      country: 'DE',
      rankingPosition: 8,
      stats: PlayerStats(average3Dart: 90.2, checkoutPercentage: 36.8, count180s: 33, highFinish: 145),
    ),
  ];

  static final event = DartsEvent(
    id: 'cdt-2026',
    name: 'Continental Darts Trophy',
    status: EventStatus.live,
    format: EventFormat.roundRobin,
    startDate: DateTime.now().subtract(const Duration(days: 2)),
    endDate: DateTime.now().add(const Duration(days: 1)),
    currentRound: 'Halbfinale',
  );

  static final liveMatch = DartsMatch(
    id: 'm-live-1',
    eventId: 'cdt-2026',
    player1Id: 'krueger',
    player2Id: 'vandijk',
    status: MatchStatus.live,
    scheduledAt: DateTime.now().subtract(const Duration(minutes: 40)),
    score: const MatchScore(sets: (2, 1), legs: (3, 2)),
    throwingPlayerId: 'krueger',
  );

  static final nextMatch = DartsMatch(
    id: 'm-next-1',
    eventId: 'cdt-2026',
    player1Id: 'fischer',
    player2Id: 'novak',
    status: MatchStatus.scheduled,
    scheduledAt: DateTime.now().add(const Duration(hours: 1)),
  );

  static const standings = <StandingEntry>[
    StandingEntry(playerId: 'vandijk', position: 1, wins: 3, losses: 0, legsFor: 9, legsAgainst: 2, nextOpponentPlayerId: 'petrov'),
    StandingEntry(playerId: 'krueger', position: 2, wins: 2, losses: 1, legsFor: 7, legsAgainst: 5, nextOpponentPlayerId: 'novak'),
    StandingEntry(playerId: 'petrov', position: 3, wins: 1, losses: 2, legsFor: 5, legsAgainst: 6, nextOpponentPlayerId: 'vandijk'),
    StandingEntry(playerId: 'bakker', position: 4, wins: 1, losses: 2, legsFor: 4, legsAgainst: 7),
    StandingEntry(playerId: 'novak', position: 5, wins: 0, losses: 3, legsFor: 3, legsAgainst: 9, nextOpponentPlayerId: 'krueger'),
  ];

  static final newsItems = <NewsItem>[
    NewsItem(
      id: 'n1',
      title: 'Krüger erzwingt Decider – Halbfinale geht in den fünften Satz',
      summary:
          'Im Halbfinale der Continental Darts Trophy gleicht Mika Krüger gegen Joran van Dijk zum 2:1 aus und erzwingt einen fünften Satz.',
      sourceUrl: 'https://example.org/news/kruger-decider',
      sourceName: 'Redaktion',
      publishedAt: DateTime.now().subtract(const Duration(minutes: 4)),
      relatedPlayerIds: const ['krueger', 'vandijk'],
      isFlash: true,
    ),
    NewsItem(
      id: 'n2',
      title: 'Van Dijk übernimmt Tabellenführung nach Gruppensieg',
      summary: 'Mit einem klaren Sieg in der Gruppenphase sichert sich Joran van Dijk Platz eins vor dem Halbfinale.',
      sourceUrl: 'https://example.org/news/vandijk-tabelle',
      sourceName: 'Redaktion',
      publishedAt: DateTime.now().subtract(const Duration(minutes: 38)),
      relatedPlayerIds: const ['vandijk'],
      isFlash: false,
    ),
    NewsItem(
      id: 'n3',
      title: 'Neuer Checkout-Rekord: Novak trifft 167 aus dem Stand',
      summary: 'Toma Novak markiert mit einem 167er-Finish den höchsten Checkout des Turniers.',
      sourceUrl: 'https://example.org/news/novak-checkout',
      sourceName: 'Redaktion',
      publishedAt: DateTime.now().subtract(const Duration(hours: 1)),
      relatedPlayerIds: const ['novak'],
      isFlash: false,
    ),
    NewsItem(
      id: 'n4',
      title: 'Vorschau: Fischer gegen Albrecht im Viertelfinale',
      summary: 'Luca Fischer trifft im Viertelfinale auf Noah Albrecht — beide gewannen ihre Gruppen ungeschlagen.',
      sourceUrl: 'https://example.org/news/fischer-albrecht-vorschau',
      sourceName: 'Redaktion',
      publishedAt: DateTime.now().subtract(const Duration(hours: 3)),
      relatedPlayerIds: const ['fischer', 'albrecht'],
      isFlash: false,
    ),
  ];
}
