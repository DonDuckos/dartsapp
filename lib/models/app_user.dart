class NotificationSettings {
  const NotificationSettings({
    required this.favoriteMatchStart,
    required this.dailyDigest,
  });

  final bool favoriteMatchStart;
  final bool dailyDigest;

  NotificationSettings copyWith({bool? favoriteMatchStart, bool? dailyDigest}) {
    return NotificationSettings(
      favoriteMatchStart: favoriteMatchStart ?? this.favoriteMatchStart,
      dailyDigest: dailyDigest ?? this.dailyDigest,
    );
  }
}
