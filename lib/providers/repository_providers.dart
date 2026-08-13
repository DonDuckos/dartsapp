import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/event.dart';
import '../models/match.dart';
import '../models/news_item.dart';
import '../models/player.dart';
import '../repositories/event_repository.dart';
import '../repositories/firestore_event_repository.dart';
import '../repositories/firestore_news_repository.dart';
import '../repositories/firestore_player_repository.dart';
import '../repositories/news_repository.dart';
import '../repositories/player_repository.dart';

final playerRepositoryProvider = Provider<PlayerRepository>((ref) => FirestorePlayerRepository());
final eventRepositoryProvider = Provider<EventRepository>((ref) => FirestoreEventRepository());
final newsRepositoryProvider = Provider<NewsRepository>((ref) => FirestoreNewsRepository());

final rankedPlayersProvider = StreamProvider<List<Player>>(
  (ref) => ref.watch(playerRepositoryProvider).watchRankedPlayers(),
);

final currentEventProvider = StreamProvider<DartsEvent?>(
  (ref) => ref.watch(eventRepositoryProvider).watchCurrentEvent(),
);

final eventByIdProvider = StreamProvider.family<DartsEvent?, String>(
  (ref, eventId) => ref.watch(eventRepositoryProvider).watchEvent(eventId),
);

final liveMatchProvider = StreamProvider.family<DartsMatch?, String>(
  (ref, eventId) => ref.watch(eventRepositoryProvider).watchLiveMatch(eventId),
);

final nextMatchProvider = StreamProvider.family<DartsMatch?, String>(
  (ref, eventId) => ref.watch(eventRepositoryProvider).watchNextMatch(eventId),
);

final standingsProvider = StreamProvider.family<List<StandingEntry>, String>(
  (ref, eventId) => ref.watch(eventRepositoryProvider).watchStandings(eventId),
);

final newsProvider = StreamProvider<List<NewsItem>>(
  (ref) => ref.watch(newsRepositoryProvider).watchNews(),
);
