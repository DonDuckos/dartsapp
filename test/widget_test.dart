import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dartsapp/main.dart';
import 'package:dartsapp/providers/repository_providers.dart';
import 'package:dartsapp/repositories/mock_event_repository.dart';
import 'package:dartsapp/repositories/mock_news_repository.dart';
import 'package:dartsapp/repositories/mock_player_repository.dart';

void main() {
  testWidgets('App startet und zeigt die vier Tabs der Bottom-Navigation', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // Läuft offline mit Fixture-Daten statt gegen echtes Firestore.
          playerRepositoryProvider.overrideWithValue(MockPlayerRepository()),
          eventRepositoryProvider.overrideWithValue(MockEventRepository()),
          newsRepositoryProvider.overrideWithValue(MockNewsRepository()),
        ],
        child: const DartsApp(),
      ),
    );
    // Kein pumpAndSettle: die Live-Indikator-Animation läuft absichtlich endlos.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Rangliste'), findsOneWidget);
    expect(find.text('News'), findsOneWidget);
    expect(find.text('Profil'), findsOneWidget);
  });
}
