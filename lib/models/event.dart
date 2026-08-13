import 'package:cloud_firestore/cloud_firestore.dart';

enum EventStatus { upcoming, live, finished }

enum EventFormat { knockout, roundRobin }

class DartsEvent {
  const DartsEvent({
    required this.id,
    required this.name,
    required this.status,
    required this.format,
    required this.startDate,
    required this.endDate,
    this.currentRound,
    this.venue,
  });

  final String id;
  final String name;
  final EventStatus status;
  final EventFormat format;
  final DateTime startDate;
  final DateTime endDate;
  final String? currentRound;
  final String? venue;

  factory DartsEvent.fromMap(String id, Map<String, dynamic> map) {
    return DartsEvent(
      id: id,
      name: map['name'] as String,
      status: EventStatus.values.byName(map['status'] as String),
      format: EventFormat.values.byName(map['format'] as String),
      startDate: (map['startDate'] as Timestamp).toDate(),
      endDate: (map['endDate'] as Timestamp).toDate(),
      currentRound: map['currentRound'] as String?,
      venue: map['venue'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'status': status.name,
        'format': format.name,
        'startDate': Timestamp.fromDate(startDate),
        'endDate': Timestamp.fromDate(endDate),
        'currentRound': currentRound,
        'venue': venue,
      };
}

class StandingEntry {
  const StandingEntry({
    required this.playerId,
    required this.position,
    required this.wins,
    required this.losses,
    required this.legsFor,
    required this.legsAgainst,
    this.nextOpponentPlayerId,
  });

  final String playerId;
  final int position;
  final int wins;
  final int losses;
  final int legsFor;
  final int legsAgainst;
  final String? nextOpponentPlayerId;

  factory StandingEntry.fromMap(String playerId, Map<String, dynamic> map) {
    return StandingEntry(
      playerId: playerId,
      position: map['position'] as int,
      wins: map['wins'] as int,
      losses: map['losses'] as int,
      legsFor: map['legsFor'] as int,
      legsAgainst: map['legsAgainst'] as int,
      nextOpponentPlayerId: map['nextOpponentPlayerId'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'position': position,
        'wins': wins,
        'losses': losses,
        'legsFor': legsFor,
        'legsAgainst': legsAgainst,
        'nextOpponentPlayerId': nextOpponentPlayerId,
      };
}
