import '../models/event.dart';
import '../models/match.dart';

abstract class EventRepository {
  /// Das aktuell relevante Event fürs Home-Screen: bevorzugt ein laufendes
  /// (`status == live`), sonst das nächste bevorstehende. Bei der zu
  /// erwartenden Eventanzahl (Freundeskreis-Nutzung) reicht ein Listener auf
  /// die gesamte Collection, ausgewählt wird clientseitig.
  Stream<DartsEvent?> watchCurrentEvent();

  Stream<DartsEvent?> watchEvent(String eventId);

  Stream<DartsMatch?> watchLiveMatch(String eventId);

  Stream<DartsMatch?> watchNextMatch(String eventId);

  Stream<List<StandingEntry>> watchStandings(String eventId);
}
