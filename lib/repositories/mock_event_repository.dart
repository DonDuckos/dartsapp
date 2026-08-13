import '../data/fixtures.dart';
import '../models/event.dart';
import '../models/match.dart';
import 'event_repository.dart';

class MockEventRepository implements EventRepository {
  @override
  Stream<DartsEvent?> watchCurrentEvent() => Stream.value(Fixtures.event);

  @override
  Stream<DartsEvent?> watchEvent(String eventId) =>
      Stream.value(Fixtures.event.id == eventId ? Fixtures.event : null);

  @override
  Stream<DartsMatch?> watchLiveMatch(String eventId) =>
      Stream.value(Fixtures.liveMatch.eventId == eventId ? Fixtures.liveMatch : null);

  @override
  Stream<DartsMatch?> watchNextMatch(String eventId) =>
      Stream.value(Fixtures.nextMatch.eventId == eventId ? Fixtures.nextMatch : null);

  @override
  Stream<List<StandingEntry>> watchStandings(String eventId) =>
      Stream.value(List.unmodifiable(Fixtures.standings));

  @override
  Stream<List<DartsMatch>> watchMatches(String eventId) => Stream.value([
        if (Fixtures.liveMatch.eventId == eventId) Fixtures.liveMatch,
        if (Fixtures.nextMatch.eventId == eventId) Fixtures.nextMatch,
      ]);
}
