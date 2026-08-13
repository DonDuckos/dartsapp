import '../data/fixtures.dart';
import '../models/player.dart';
import 'player_repository.dart';

/// Für Tests und Offline-Vorschau — liefert die Fixture-Daten als
/// einmaligen Stream-Wert.
class MockPlayerRepository implements PlayerRepository {
  @override
  Stream<List<Player>> watchRankedPlayers() => Stream.value(List.unmodifiable(Fixtures.players));
}
