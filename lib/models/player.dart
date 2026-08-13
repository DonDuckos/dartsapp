class PlayerStats {
  const PlayerStats({
    required this.average3Dart,
    required this.checkoutPercentage,
    required this.count180s,
    required this.highFinish,
  });

  factory PlayerStats.fromMap(Map<String, dynamic> map) {
    return PlayerStats(
      average3Dart: (map['average3Dart'] as num).toDouble(),
      checkoutPercentage: (map['checkoutPercentage'] as num).toDouble(),
      count180s: map['count180s'] as int,
      highFinish: map['highFinish'] as int,
    );
  }

  final double average3Dart;
  final double checkoutPercentage;
  final int count180s;
  final int highFinish;

  Map<String, dynamic> toMap() => {
        'average3Dart': average3Dart,
        'checkoutPercentage': checkoutPercentage,
        'count180s': count180s,
        'highFinish': highFinish,
      };
}

class Player {
  const Player({
    required this.id,
    required this.name,
    required this.country,
    required this.rankingPosition,
    required this.stats,
    this.photoUrl,
    this.bio,
  });

  final String id;
  final String name;
  final String country;
  final int rankingPosition;
  final PlayerStats stats;
  final String? photoUrl;
  final String? bio;

  factory Player.fromMap(String id, Map<String, dynamic> map) {
    return Player(
      id: id,
      name: map['name'] as String,
      country: map['country'] as String,
      rankingPosition: map['rankingPosition'] as int,
      stats: PlayerStats.fromMap(Map<String, dynamic>.from(map['stats'] as Map)),
      photoUrl: map['photoUrl'] as String?,
      bio: map['bio'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'country': country,
        'rankingPosition': rankingPosition,
        'stats': stats.toMap(),
        'photoUrl': photoUrl,
        'bio': bio,
      };
}
