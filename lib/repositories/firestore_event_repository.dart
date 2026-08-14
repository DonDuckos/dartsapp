import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/event.dart';
import '../models/match.dart';
import 'event_repository.dart';

class FirestoreEventRepository implements EventRepository {
  FirestoreEventRepository({FirebaseFirestore? firestore}) : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  @override
  Stream<DartsEvent?> watchCurrentEvent() {
    // Kleine Collection (Freundeskreis-Nutzung) — komplett lesen und
    // clientseitig auswählen spart einen zusammengesetzten Firestore-Index.
    return _db.collection('events').snapshots().map((snapshot) {
      final events = snapshot.docs.map((doc) => DartsEvent.fromMap(doc.id, doc.data())).toList();
      final live = events.where((e) => e.status == EventStatus.live).firstOrNull;
      if (live != null) return live;

      final upcoming = events.where((e) => e.status == EventStatus.upcoming).toList()
        ..sort((a, b) => a.startDate.compareTo(b.startDate));
      return upcoming.firstOrNull;
    });
  }

  @override
  Stream<DartsEvent?> watchEvent(String eventId) {
    return _db.collection('events').doc(eventId).snapshots().map(
          (doc) => doc.exists ? DartsEvent.fromMap(doc.id, doc.data()!) : null,
        );
  }

  @override
  Stream<List<DartsMatch>> watchMatches(String eventId) => _watchMatchesForEvent(eventId);

  Stream<List<DartsMatch>> _watchMatchesForEvent(String eventId) {
    return _db.collection('matches').where('eventId', isEqualTo: eventId).snapshots().map(
          (snapshot) => snapshot.docs.map((doc) => DartsMatch.fromMap(doc.id, doc.data())).toList(),
        );
  }

  @override
  Stream<DartsMatch?> watchLiveMatch(String eventId) {
    return _watchMatchesForEvent(eventId).map((matches) {
      // Mehrere Matches können kurzzeitig gleichzeitig "live" sein (z.B. ein
      // Match wechselt gerade auf "finished", während das nächste schon
      // anläuft) — das zuletzt gestartete soll die Startseite bestimmen,
      // nicht die zufällige Firestore-Dokumentreihenfolge.
      final live = matches.where((m) => m.status == MatchStatus.live).toList()
        ..sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));
      return live.firstOrNull;
    });
  }

  @override
  Stream<DartsMatch?> watchNextMatch(String eventId) {
    return _watchMatchesForEvent(eventId).map((matches) {
      final scheduled = matches.where((m) => m.status == MatchStatus.scheduled).toList()
        ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
      return scheduled.firstOrNull;
    });
  }

  @override
  Stream<List<StandingEntry>> watchStandings(String eventId) {
    return _db.collection('events').doc(eventId).collection('standings').orderBy('position').snapshots().map(
          (snapshot) => snapshot.docs.map((doc) => StandingEntry.fromMap(doc.id, doc.data())).toList(),
        );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
