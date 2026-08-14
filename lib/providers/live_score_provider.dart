import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/match.dart';
import '../services/bzzoiro_client.dart';

const _pollInterval = Duration(seconds: 10);
const _client = BzzoiroClient();

/// Pollt bzzoiro direkt vom Gerät (siehe bzzoiro_client.dart), solange
/// irgendwo ein Live-Match aus (player1Name, player2Name) angezeigt wird.
/// autoDispose sorgt dafür, dass das Polling automatisch stoppt, sobald kein
/// Widget mehr zuhört (z.B. Home-Screen nicht sichtbar oder kein Live-Match
/// mehr) — es läuft also nie unbeaufsichtigt im Hintergrund weiter.
final liveScoreProvider =
    StreamProvider.autoDispose.family<MatchScore?, ({String player1Name, String player2Name})>((ref, params) async* {
  // Ohne konfigurierten Key (z.B. lokale Debug-Builds ohne
  // --dart-define-from-file, oder Tests) gibt es nichts zu pollen — der
  // Stream endet sofort statt einen dauerhaften Timer zu starten.
  if (!_client.isConfigured) {
    yield null;
    return;
  }
  while (true) {
    yield await _client.fetchLiveScore(params.player1Name, params.player2Name);
    await Future.delayed(_pollInterval);
  }
});
