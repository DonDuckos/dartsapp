import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/match.dart';

/// Direkter Client für die bzzoiro-Darts-API (nur /matches/live/), fürs
/// Polling vom Gerät aus, solange ein Live-Match auf dem Home-Screen zu sehen
/// ist — niedrigere Latenz als der Umweg über den GitHub-Actions-Match-Agent
/// und Firestore (der weiterhin alle 15 Min. läuft und die Grunddaten
/// aktuell hält, auch wenn gerade niemand die App offen hat). bzzoiro bietet
/// nur REST, kein WebSocket/SSE — das hier ist also weiterhin Polling, nur
/// direkt vom Gerät statt vom Server aus.
///
/// Sicherheitshinweis: Der API-Key wird zur Build-Zeit per
/// --dart-define-from-file eingebettet und landet dadurch im kompilierten
/// APK. Anders als die GitHub-Actions-Secrets verlässt er damit kontrollierte
/// Infrastruktur — bei Bedarf aus der APK extrahierbar. Für ein 5-$/Monat-
/// Abo in einem Freundeskreis-Hobbyprojekt ist das ein bewusst akzeptiertes
/// Risiko (siehe CLAUDE.md, "Sicherheit bewusst niedrig priorisiert").
const _apiKey = String.fromEnvironment('BZZOIRO_API_KEY');
const _baseUrl = 'https://sports.bzzoiro.com/darts/api/v2';

// Portiert aus scripts/match-agent/bzzoiro.mjs — bzzoiro und unsere eigenen
// Daten formatieren Spielernamen möglicherweise unterschiedlich, daher
// Vergleich über Namens-Tokens statt exaktem String-Match.
List<String> _tokens(String name) => name
    .toLowerCase()
    .replaceAll('.', '')
    .split(RegExp(r'\s+'))
    .where((token) => token.length > 1)
    .toList();

bool _namesMatch(String a, String b) {
  final tokensB = _tokens(b).toSet();
  return _tokens(a).any(tokensB.contains);
}

bool _pairMatches(String ourP1, String ourP2, String otherP1, String otherP2) {
  return (_namesMatch(ourP1, otherP1) && _namesMatch(ourP2, otherP2)) ||
      (_namesMatch(ourP1, otherP2) && _namesMatch(ourP2, otherP1));
}

class BzzoiroClient {
  const BzzoiroClient();

  bool get isConfigured => _apiKey.isNotEmpty;

  /// Sucht in der aktuellen bzzoiro-Live-Liste nach einem Match, das zu
  /// [player1Name]/[player2Name] passt, und liefert den Spielstand relativ
  /// zu dieser Reihenfolge (nicht bzzoiros eigener). Gibt null zurück, wenn
  /// nicht konfiguriert, nicht gefunden, oder die Anfrage fehlschlägt — der
  /// Aufrufer soll in dem Fall auf die Firestore-Daten zurückfallen.
  Future<MatchScore?> fetchLiveScore(String player1Name, String player2Name) async {
    if (!isConfigured) return null;
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/matches/live/'), headers: {'Authorization': 'Token $_apiKey'})
          .timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return null;

      final decoded = jsonDecode(response.body);
      final matches = decoded is List ? decoded : (decoded['results'] as List? ?? const []);

      for (final raw in matches) {
        final m = raw as Map<String, dynamic>;
        final p1 = m['player1']?['name'] as String?;
        final p2 = m['player2']?['name'] as String?;
        if (p1 == null || p2 == null) continue;
        if (!_pairMatches(player1Name, player2Name, p1, p2)) continue;

        final sets1 = (m['player1_sets'] as num?)?.toInt() ?? 0;
        final sets2 = (m['player2_sets'] as num?)?.toInt() ?? 0;
        final legs1 = (m['player1_legs'] as num?)?.toInt() ?? 0;
        final legs2 = (m['player2_legs'] as num?)?.toInt() ?? 0;

        final swapped = !_namesMatch(player1Name, p1);
        return MatchScore(
          sets: swapped ? (sets2, sets1) : (sets1, sets2),
          legs: swapped ? (legs2, legs1) : (legs1, legs2),
        );
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
