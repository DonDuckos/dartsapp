# DartsApp — Projektauftrag für Claude Code

> Status: **Voller Echtdaten-Betrieb, live während des New Zealand Darts Masters 2026 verifiziert (2026-08-14).** Firebase-Projekt „Dartz" (`dartz-39d69`, Spark-Plan) mit Firestore, Sicherheitsregeln, Google-Auth und E-Mail/Passwort-Auth eingerichtet. Google Sign-In läuft, Favoriten/Benachrichtigungen synchronisieren live mit `users/{uid}`. `players`-Collection enthält die echte PDC Order of Merit Top 30 (`scripts/seed/seed.mjs`) plus 8 Oceanic-Qualifikanten. `events`/`matches` enthalten das echte New Zealand Darts Masters 2026 (`scripts/seed/seed-nz-masters-2026.mjs`, 14.–15.08., Spark Arena Auckland, komplette Erstrunden-Paarung).
>
> **Drei Cron-Jobs in GitHub Actions**, alle über OpenRouter mit **Kimi K2** (`moonshotai/kimi-k2-0905`, ~5x günstiger als das vorherige Claude-Modell, passt zum 3–8€/Monat-Budget):
> - **News-Agent** (`scripts/news-agent/`, alle 3 Std.): Websuche allgemein + pro favorisiertem Spieler, Zeitfenster 24 Std.
> - **Match-Agent** (`scripts/match-agent/`, alle 15 Min.): hält Match-Status/Score aktuell, schaltet Events automatisch auf „live" (auch bei direkt erkanntem „finished", falls ein schnelles Match zwischen zwei Läufen komplett durchläuft). **Primärquelle seit 2026-08-14: die bezahlte bzzoiro-Darts-API** (`sports.bzzoiro.com`, 5 $/Monat, strukturierte Echtzeitdaten statt LLM-Interpretation) — matcht Matches über Spielernamen (Token-Overlap in `scripts/match-agent/bzzoiro.mjs`, robust gegenüber Namensformat und vertauschter Reihenfolge) und übernimmt bei Abweichung >5 Min. auch die echte Ansetzungszeit, da unsere eigene beim Seeding nur geschätzt wird. OpenRouter/Kimi K2 bleibt als Fallback für Matches, die bzzoiro nicht findet; der Plausibilitäts-Check (verwirft „live"/„finished" bei Ansetzungstermin >30 Min. in der Zukunft) gilt nur noch für diesen Fallback-Pfad, da er bei bzzoiro-Daten echte Updates fälschlich verworfen hat (siehe Git-Historie). Matching-Logik unit-getestet (`scripts/match-agent/test-matching.mjs`).
> - **Profile-Agent** (`scripts/profile-agent/`, manuell + wöchentlich Mo. 6 Uhr): ergänzt Spieler-Vitas, Zitate (mit Quelle), Fotos (ausschließlich Wikimedia Commons mit geprüfter Lizenz, keine KI-Einschätzung) sowie 3-Dart-Average/Checkout-Quote/180er/High-Finish pro Spieler und journalistische Location-Previews pro Event. Statistiken kommen bevorzugt kostenlos strukturiert von darts-nerd.com (per Scraping, kein LLM) und fallen nur bei Lücken auf die OpenRouter-Websuche zurück — deren „Highest Checkout"-Feld ist nachweislich fehlerhaft (immer exakt 170) und wird nie übernommen. Hat harte Plausibilitätsgrenzen für die Statistikfelder (z.B. High Finish max. 170 — das theoretische Maximum, ein Finish endet immer auf einem Doppel) und verwarf beim Testen bereits mehrere unmögliche/unbelegte Werte automatisch. Bereits zweimal für alle 38 Spieler + 1 Event gelaufen, Ergebnis stichprobenartig geprüft.
>
> Home-Screen zeigt Badge/Datum/Uhrzeit (korrekte Gerätezeitzone) bei „Nächstes Spiel" (klickbar → Event-Detail mit Termin/Ort/Format/Location-Preview/Spielplan) sowie die 3 aktuellsten News. Spieler-Detail zeigt Foto+Attribution, Vita, Zitat und Statistik; Rangliste zeigt Foto-Avatare (mit Fallback bei Ladefehler, `lib/widgets/player_avatar.dart`). Bewusste Grenze: Der Match-Agent erzeugt keine Folgerunden-Matches (Viertelfinale etc.) — dafür fehlt noch ein Turnierbaum-Datenmodell.
>
> **Datenqualitäts-Fixes (2026-08-13):** Drei vom Nutzer gemeldete Bugs behoben. (1) Alle Erstrunden-Matches des NZ Masters liefen fälschlich auf identischer Startzeit 9:00 — jetzt in 28-Min.-Schritten gestaffelt (`scripts/seed/seed-nz-masters-2026.mjs`), plus Disclaimer im Spielplan, da die PDC nur den Sitzungsbeginn offiziell ansetzt. (2) Eine monatealte News wurde als „Eilmeldung" angezeigt, weil `publishedAt` der Zeitpunkt war, an dem der Agent die Meldung fand, nicht ihr echtes Datum — News-Agent verlangt jetzt ein recherchiertes `publishedDate` pro Meldung, verwirft unplausible Werte (`parsePublishedDate`) und setzt `isFlash` nur noch bei hart geprüftem Alter ≤48 Std. (3) News zeigen jetzt immer ein Datum (`newsDate()` — relative Zeit <48 Std., sonst TT.MM.JJJJ) und einen anklickbaren Quellenlink (`url_launcher`) in Liste und Detailansicht.

## Ziel & Kontext

Eine Android-App rund um Darts, gebaut für einen Freund des Entwicklers (privates Projekt, kein kommerzielles Produkt). Kernanliegen:

- So **stabil und schnell** wie möglich auf Android
- **Kostenlose** Online-Datenbank
- **Sicherheit ist bewusst niedrig priorisiert** — kein Grund, hier Aufwand zu investieren (kein sensibler Datenumgang, kleine Nutzerzahl)
- Klare, **nicht überladene Struktur**
- Design: **dezent, stylisch, mit WOW-Effekt** — nicht verspielt/bunt-überladen, sondern hochwertig-reduziert mit gezielten Akzenten

## Tech-Stack (Empfehlung)

| Bereich | Wahl | Begründung |
|---|---|---|
| App-Framework | **Flutter** | Ein Codebase, sehr performant auf Android, große Community |
| State Management | **Riverpod** | Klar strukturiert, gut testbar |
| Backend/DB | **Firebase Firestore** | Kostenloser Spark-Plan reicht für Freundeskreis-Nutzung |
| Auth | **Firebase Auth** (Google Sign-In) | Ein Klick, kein eigenes Passwort-Handling nötig |
| Push | **Firebase Cloud Messaging** | Kostenlos, direkt mit Firestore-Änderungen kombinierbar |
| Bilder | **Firebase Storage** oder externe URLs | Nur bei eigenen/lizenzfreien Bildern selbst hosten |
| News-Agent (periodischer Web-Scan) | Scheduler + LLM-Call, siehe unten | Details unter „News-Agent" |

**Wichtiger Hinweis zu „kostenlos":** Firestore, Auth und Messaging sind im Spark-Plan (kostenlos) nutzbar. Cloud Functions/Cloud Scheduler von Firebase würden den kostenpflichtigen Blaze-Plan (mit hinterlegter Kreditkarte) voraussetzen — das wird hier bewusst vermieden.

**News-Agent-Trigger (entschieden):** Ein **GitHub-Actions-Scheduled-Workflow** (Cron, alle 3 Std., kostenlos in üblichen Limits) führt einen Script-Job aus, der News sammelt/zusammenfasst und direkt per Firebase Admin SDK (Service-Account) in die `news`-Collection in Firestore schreibt. Kein Blaze-Plan, keine Kreditkarten-Hinterlegung nötig.

## Design-Sprache

- **Dark-first Theme**: tiefes Anthrazit/Nachtblau als Basis, ein einziger kräftiger Akzentton (z.B. Electric-Green oder Gold, wie ein Dartboard-Highlight) für Live-Elemente, CTAs und Erfolgsmomente
- Reduzierte Farbpalette (max. 1 Akzentfarbe + neutrale Grau-/Dunkeltöne), keine bunte Über-Dekoration
- Großzügiger Weißraum, klare Typo-Hierarchie, keine überladenen Karten
- **WOW-Effekt gezielt einsetzen**, nicht flächendeckend: z.B. sanft glühender Rand bei „Live"-Kachel, animierter Score-Wechsel, dezente Mikro-Animationen beim Öffnen von Events — kein Kitsch, keine Dauer-Animation
- Konsistente Karten-/Listendarstellung über alle Screens hinweg (Wiedererkennbarkeit statt Screen-für-Screen-Neuerfindung)

## Datenmodell (Firestore, Vorschlag)

```
users/{uid}
  displayName: string
  favoritePlayerIds: string[]
  notificationSettings: { favoriteMatchStart: bool, dailyDigest: bool }

players/{playerId}
  name: string
  country: string
  rankingPosition: number        // Platz in Top-30(+)-Liste
  photoUrl: string | null
  stats: {
    average3Dart: number
    checkoutPercentage: number
    count180s: number
    highFinish: number
  }
  bio: string | null

events/{eventId}
  name: string
  status: "upcoming" | "live" | "finished"
  startDate: timestamp
  endDate: timestamp
  format: "knockout" | "roundrobin"
  currentRound: string | null

events/{eventId}/standings/{playerId}
  position: number
  wins: number
  losses: number
  legsFor: number
  legsAgainst: number
  nextOpponentPlayerId: string | null

matches/{matchId}
  eventId: string
  player1Id: string
  player2Id: string
  status: "scheduled" | "live" | "finished"
  score: { sets: [number, number], legs: [number, number] }
  scheduledAt: timestamp

news/{newsId}
  title: string
  summary: string
  imageUrl: string | null
  sourceUrl: string
  publishedAt: timestamp
  relatedPlayerIds: string[]
  isFlash: boolean               // besondere Ankündigung / Eilmeldung
```

## Screens (Übersicht — Details im freigegebenen Mockup)

Freigegebenes visuelles Referenz-Mockup: https://claude.ai/code/artifact/e71a1e90-5767-4314-a1e3-f98ea7f4c70a

Bottom-Navigation mit **4 Tabs**, bewusst schlank gehalten:

1. **Home** — aktuelles/nächstes wichtiges Event, Live-Score oder nächstes Spiel, Flash-News-Banner
2. **Ranking** — Top-30-Spielerliste (erweiterbar), Favoriten markierbar
3. **News** — chronologischer Feed, Flash-News hervorgehoben, Filter „nur Favoriten"
4. **Profil** — Login-Status, gespeicherte Favoriten, Benachrichtigungseinstellungen

Detail-Screens (per Push von obigen erreichbar, kein eigener Tab):

- **Event-Detail** — Tabelle (Score, nächster Gegner), optional Turnierbaum
- **Live-Match** — Live-Score-Ansicht
- **Spieler-Detail** — Stats, Bio, Head-to-Head, Favorit-Toggle
- **News-Detail** — Volltext + Bild

## Nicht-Ziele / bewusste Einschränkungen

- Kein hoher Security-Aufwand (kein 2FA, keine strengen Rollen-/Rechte-Systeme)
- Kein iOS-Fokus (Android zuerst, Flutter erlaubt späteres iOS falls gewünscht)
- Kein Community-/Social-Feature-Umfang (Kommentare, Chat etc. nicht Teil des Scopes, außer explizit gewünscht)

## Aktueller Stand (2026-08-14)

- Flutter-SDK lokal unter `/home/donduckos/development/flutter` installiert (PATH-Eintrag in `~/.zshrc`), Android-SDK unter `/home/donduckos/development/android-sdk`
- `flutter create` gelaufen, Riverpod + Firebase-Pakete + `google_fonts` in `pubspec.yaml`
- Theme (`lib/theme/`), Datenmodelle (`lib/models/`, inkl. Firestore-`fromMap`/`toMap`), Repositories (`lib/repositories/` — je ein `Firestore*`- und ein `Mock*`-Repository pro Domäne, `Mock*` nur für Tests), alle Screens (`lib/screens/`) und die Bottom-Nav-Shell (`lib/shell/root_shell.dart`) sind implementiert und folgen der freigegebenen Designsprache
- Daten-Provider (`lib/providers/repository_providers.dart`) sind Stream-basiert (Riverpod `StreamProvider`/`.family`) — Firestore-Änderungen (z.B. neue News vom Agent) aktualisieren die UI automatisch in Echtzeit
- `flutter analyze` → keine Probleme, `flutter test` → grün (läuft mit Mock-Repositories, offline), `flutter build apk --debug` → erfolgreich (`build/app/outputs/flutter-apk/app-debug.apk`)
- Firebase-Projekt „Dartz" (`dartz-39d69`, Spark-Plan) angelegt, Firestore + Google-Auth aktiviert, Sicherheitsregeln gesetzt, `flutterfire configure` gelaufen (`lib/firebase_options.dart`, `android/app/google-services.json`, beide gitignored)
- Firestore mit Startdaten befüllt via `scripts/seed/seed.mjs` (8 Spieler, 1 Event, 5 Standings, 2 Matches, 4 News) — beliebig oft erneut ausführbar
- Google Sign-In implementiert (`lib/providers/auth_provider.dart`, `lib/screens/profile/profile_screen.dart`): Debug-SHA-1 des lokalen Keystores wurde per Firebase-CLI (`firebase apps:android:sha:create`) registriert, `google-services.json` danach neu gezogen (`firebase apps:sdkconfig`), damit der Android-OAuth-Client zum SHA-1 passt. **Wichtig:** Für einen Android-Release-Build (signierter APK/AAB statt Debug) muss zusätzlich der SHA-1 des Release-Keystores auf die gleiche Weise registriert werden, sonst schlägt Google Sign-In dort fehl.
- Favoriten (`lib/providers/favorites_provider.dart`) und Benachrichtigungseinstellungen (`lib/providers/notification_settings_provider.dart`) synchronisieren live mit `users/{uid}` in Firestore, sobald angemeldet; ohne Anmeldung nur lokal für die Session (Gast-Modus)
- **Windows-Testumgebung eingerichtet** (2026-08-13): Android-SDK-Kommandozeilen-Tools + Emulator unter `C:\AndroidSDK` (JDK 17 unter `C:\Program Files\Microsoft\jdk-17.0.20.8-hotspot`), AVD `dartsapp_test` (Pixel 6, API 35). Start: `C:\AndroidSDK\emulator\emulator.exe -avd dartsapp_test`. App-Debug-Build wurde erfolgreich installiert und getestet (`adb.exe install`, Home/Rangliste live mit echten Firestore-Daten verifiziert). **Hinweis:** WSL hat einen eigenen ADB-Server auf Port 5037 — falls `adb.exe devices` auf Windows leer bleibt, `adb kill-server` in WSL ausführen (WSL-Server blockiert sonst den Windows-Server über die Port-Weiterleitung).
- **Anmeldung mit Zugangsdaten** (2026-08-14): E-Mail/Passwort-Provider in Firebase Auth aktiviert (für Testnutzer ohne bequemen Google-Account, z.B. ältere Personen). Profil-Screen hat einen einklappbaren „Mit Zugangsdaten anmelden"-Bereich zusätzlich zum Google-Button; Benutzername wird intern auf eine Fake-E-Mail (`{username}@dartsapp.app`) gemappt. Test-Accounts werden über `scripts/seed/create-test-account.mjs` angelegt — Zugangsdaten kommen bewusst nur über Umgebungsvariablen, nie als Literal im (öffentlichen) Repo.
- **Match-Agent auf bzzoiro-API umgestellt** (2026-08-14): Auslöser war ein vom Nutzer gemeldeter Bug — die Startseite zeigte während des laufenden NZ Masters ein bereits gespieltes Match als „Nächstes Spiel" an. Ursache: Der alte Match-Agent fragte OpenRouter pro Match einzeln und vertraute dabei implizit unserer nur geschätzten Ansetzungsreihenfolge (die PDC veröffentlicht die reale Reihenfolge nie offiziell) — zwei Matches wurden real korrekt als „finished" erkannt, während chronologisch frühere (laut unserer Schätzung) noch „scheduled" blieben. Jetzt Primärquelle: die bezahlte bzzoiro-Darts-API (5 $/Monat, `sports.bzzoiro.com`), die alle Matches im Datumsfenster des Events abfragt und über Spielernamen zu unseren Firestore-Docs matcht (`scripts/match-agent/bzzoiro.mjs`, Token-Overlap-Vergleich statt exaktem String-Match, funktioniert unabhängig von Namensreihenfolge/-format). Übernimmt bei Abweichung >5 Min. auch bzzoiros echte Ansetzungszeit statt unserer Schätzung. OpenRouter/Kimi K2 bleibt Fallback für nicht gefundene Matches; der bisherige Plausibilitäts-Check gilt nur noch für diesen Fallback-Pfad (er hatte im Live-Test korrekte bzzoiro-Updates fälschlich verworfen, weil er gegen unsere ungenaue geschätzte Zeit prüfte). Live gegen das laufende Turnier getestet und verifiziert.

## Nächste Schritte

1. ~~Screens als visuelle Mockups vom Nutzer freigeben lassen~~ ✓ erledigt (2026-08-13)
2. ~~Finale Tech-Entscheidung News-Agent~~ ✓ GitHub Actions Cron (2026-08-13)
3. ~~Flutter-Projekt aufsetzen und V1 mit Mock-Daten implementieren~~ ✓ erledigt (2026-08-13)
4. ~~Firebase-Projekt einrichten~~ ✓ erledigt (2026-08-13)
5. ~~Mock-Repositories durch Firestore-Implementierungen ersetzen~~ ✓ erledigt (2026-08-13)
6. ~~Firestore mit Startdaten befüllen~~ ✓ erledigt (2026-08-13, `scripts/seed/seed.mjs`)
7. ~~Google-Sign-In-UI bauen und Favoriten/Einstellungen an `users/{uid}` anbinden~~ ✓ erledigt (2026-08-13)
8. ~~App auf echtem Gerät/Emulator testen~~ ✓ erledigt (2026-08-13, Windows-Emulator, siehe oben)
9. ~~News-Agent auf OpenRouter umstellen + pro Favorit suchen + lokal testen~~ ✓ erledigt (2026-08-13)
10. ~~GitHub-Secrets hinterlegen und Workflow live testen~~ ✓ erledigt (2026-08-13, Run erfolgreich, `gh` CLI ist jetzt lokal eingerichtet und angemeldet)
11. ~~Echte Spielerdaten (Weltrangliste) recherchieren und einpflegen~~ ✓ erledigt (2026-08-13, PDC Order of Merit Top 30)
12. ~~Echtes Event (New Zealand Darts Masters 2026) mit Erstrunden-Spielplan einpflegen~~ ✓ erledigt (2026-08-13)
13. ~~Home-Screen: Badge/Datum/Uhrzeit bei „Nächstes Spiel" + klickbar, Event-Detail mit Termin/Ort/Format, News-Sektion auf Home~~ ✓ erledigt (2026-08-13)
14. ~~Match-Agent für automatische Live-Spielstand-Updates~~ ✓ erledigt (2026-08-13, `scripts/match-agent/`, Cron alle 15 Min.)
15. ~~Zeitzonen-Fix (Home/Event-Detail zeigen jetzt korrekte Gerätezeitzone)~~ ✓ erledigt (2026-08-13 — war nur eine Emulator-Einstellung, kein Code-Bug)
16. ~~Agenten auf OpenRouter/Kimi K2 statt Claude umstellen~~ ✓ erledigt (2026-08-13, `moonshotai/kimi-k2-0905`, ~5x günstiger)
17. ~~Profile-Agent: Spieler-Vitas/Zitate/Fotos (Wikimedia) + Event-Location-Reporting~~ ✓ erledigt (2026-08-13, `scripts/profile-agent/`)
18. ~~Statistiken (Average/Checkout-Quote/180er/High-Finish) nachrecherchieren~~ ✓ erledigt (2026-08-13, inkl. Plausibilitäts-Check nach gefundenen Ausreißern — siehe git-Historie)
19. ~~Bugfixes: gestaffelte Match-Zeiten, News-Datum korrekt statt Fund-Zeitpunkt, News-Quellenlink~~ ✓ erledigt (2026-08-13)
20. ~~Anmeldung mit Zugangsdaten als Alternative zu Google Sign-In (für Testnutzer ohne bequemen Google-Account)~~ ✓ erledigt (2026-08-14, `lib/providers/auth_provider.dart`, Profil-Screen)
21. ~~Match-Agent auf bzzoiro-API umstellen (Live-Bug beim NZ Masters live behoben)~~ ✓ erledigt (2026-08-14, siehe oben)

## Mögliche Erweiterungen (kein Auftrag, nur Ideen für später)

- **Turnierbaum-Datenmodell**: Der Match-Agent kann aktuell nur bestehende Matches aktualisieren, aber keine Folgerunden (Viertelfinale etc.) automatisch anlegen, da die Bracket-Struktur (wer spielt nach einem Sieg gegen wen) noch nicht modelliert ist. Für volle Turnierbaum-Automatisierung müsste das Datenmodell um Round/Bracket-Beziehungen erweitert werden.
- Sobald das New Zealand Darts Masters vorbei ist: nächstes echtes Event (z.B. Australian Darts Masters, 21.–22.08.) nach demselben Muster wie `scripts/seed/seed-nz-masters-2026.mjs` einpflegen
- Für 10 von 38 Spielern (u.a. Andrew Gilding, Damon Heta, Martin Schindler, Jonny Tata) fand der Profile-Agent auch im zweiten Anlauf keine verlässlichen Saison-2026-Statistiken — ehrlich leer gelassen statt geraten, könnte bei einem späteren Lauf erneut versucht werden
- Push-Benachrichtigungen tatsächlich versenden (Firebase Cloud Messaging ist vorbereitet, aber noch nicht am Laufen)
- Live-Highlight-Erkennung direkt aus eigenen Match-Daten statt nur externer Websuche
- Journalistische "Warum spielt X nicht mit"-Storys: aktuell deckt die allgemeine News-Suche das teilweise ab, ein gezielterer Prompt könnte das noch verlässlicher machen
