import 'package:cloud_firestore/cloud_firestore.dart';

enum MatchStatus { scheduled, live, finished }

class MatchScore {
  const MatchScore({required this.sets, required this.legs});

  final (int, int) sets;
  final (int, int) legs;

  factory MatchScore.fromMap(Map<String, dynamic> map) {
    final sets = (map['sets'] as List).cast<int>();
    final legs = (map['legs'] as List).cast<int>();
    return MatchScore(sets: (sets[0], sets[1]), legs: (legs[0], legs[1]));
  }

  Map<String, dynamic> toMap() => {
        'sets': [sets.$1, sets.$2],
        'legs': [legs.$1, legs.$2],
      };
}

class DartsMatch {
  const DartsMatch({
    required this.id,
    required this.eventId,
    required this.player1Id,
    required this.player2Id,
    required this.status,
    required this.scheduledAt,
    this.score,
    this.throwingPlayerId,
  });

  final String id;
  final String eventId;
  final String player1Id;
  final String player2Id;
  final MatchStatus status;
  final DateTime scheduledAt;
  final MatchScore? score;
  final String? throwingPlayerId;

  factory DartsMatch.fromMap(String id, Map<String, dynamic> map) {
    return DartsMatch(
      id: id,
      eventId: map['eventId'] as String,
      player1Id: map['player1Id'] as String,
      player2Id: map['player2Id'] as String,
      status: MatchStatus.values.byName(map['status'] as String),
      scheduledAt: (map['scheduledAt'] as Timestamp).toDate(),
      score: map['score'] == null ? null : MatchScore.fromMap(Map<String, dynamic>.from(map['score'] as Map)),
      throwingPlayerId: map['throwingPlayerId'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'eventId': eventId,
        'player1Id': player1Id,
        'player2Id': player2Id,
        'status': status.name,
        'scheduledAt': Timestamp.fromDate(scheduledAt),
        'score': score?.toMap(),
        'throwingPlayerId': throwingPlayerId,
      };
}
