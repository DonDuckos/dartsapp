import '../models/player.dart';

abstract class PlayerRepository {
  /// Sortiert nach `rankingPosition`. Enthält die komplette Rangliste (bis
  /// Top 30) — bei dieser Größenordnung reicht ein einzelner Listener statt
  /// pro Spieler ein eigenes Dokument zu beobachten.
  Stream<List<Player>> watchRankedPlayers();
}
