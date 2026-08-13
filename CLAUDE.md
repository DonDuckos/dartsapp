# DartsApp — Projektauftrag für Claude Code

> Status: **Auf GitHub (DonDuckos/dartsapp), News-Agent lokal verifiziert (2026-08-13).** Firebase-Projekt „Dartz" (`dartz-39d69`, Spark-Plan) mit Firestore, Sicherheitsregeln und Google-Auth ist eingerichtet und mit Startdaten befüllt. Google Sign-In läuft (SHA-1 registriert), Favoriten/Benachrichtigungen synchronisieren live mit `users/{uid}`. Auf einem eingerichteten Windows-Emulator erfolgreich getestet — Home und Rangliste zeigen echte Firestore-Daten. Der News-Agent (`scripts/news-agent/`) läuft jetzt über OpenRouter statt direkt über Anthropic, sucht zusätzlich pro favorisiertem Spieler gezielt, und wurde lokal erfolgreich getestet (echte Websuche bestätigt). Noch offen: GitHub Secrets fürs Actions-Workflow eintragen, dann den Workflow einmal live auslösen.

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

## Aktueller Stand (2026-08-13)

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
10. GitHub-Secrets `FIREBASE_SERVICE_ACCOUNT_JSON` und `OPENROUTER_API_KEY` im Repo https://github.com/DonDuckos/dartsapp hinterlegen (Settings → Secrets and variables → Actions), danach den News-Agent-Workflow einmal manuell auslösen (Actions-Tab → „Darts News Agent" → „Run workflow") und die `news`-Collection in Firestore prüfen
