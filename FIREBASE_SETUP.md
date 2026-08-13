# Firebase-Setup

Die App ist bereits auf Firebase vorbereitet (`cloud_firestore`, `firebase_auth`, `firebase_core`, `google_sign_in`, `firebase_messaging` sind in `pubspec.yaml`). Aktuell läuft die App noch mit Mock-Daten aus `lib/data/fixtures.dart` — folgende Schritte sind einmalig nötig, um sie an ein echtes, kostenloses Firebase-Projekt anzubinden. Das kann nur der Kontoinhaber selbst tun (Google-Login erforderlich), Claude Code kann das nicht automatisiert übernehmen.

## 1. Firebase-Projekt anlegen

1. https://console.firebase.google.com öffnen, mit dem gewünschten Google-Konto anmelden
2. „Projekt hinzufügen" → Name z.B. `dartsapp` → Google Analytics kann deaktiviert bleiben (nicht benötigt)
3. Im **Spark-Plan** (kostenlos) bleiben — für Firestore, Auth und Messaging ausreichend

## 2. Firestore aktivieren

1. Im Projekt: „Firestore Database" → „Datenbank erstellen"
2. Produktionsmodus wählen, Region z.B. `eur3 (europe-west)`
3. Sicherheitsregeln später anpassen (siehe unten) — im Freundeskreis-Rahmen reichen einfache Regeln, da Security bewusst niedrig priorisiert ist (siehe CLAUDE.md)

## 3. Google Sign-In aktivieren

1. „Authentication" → „Sign-in method" → „Google" aktivieren

## 4. FlutterFire CLI verbinden

```bash
dart pub global activate flutterfire_cli
cd /home/donduckos/dartsapp
flutterfire configure
```

Der Befehl fragt interaktiv nach dem Firebase-Projekt und der Android-Package-ID (`com.dartsapp.dartsapp`) und erzeugt automatisch `lib/firebase_options.dart` sowie `android/app/google-services.json`. Beide Dateien enthalten projektspezifische, aber nicht geheime Konfigurationswerte — trotzdem nicht committen, falls das Repo später öffentlich wird (stehen bereits in `.gitignore`-Kandidaten, ggf. prüfen).

## 5. `main.dart` erweitern

Nach Schritt 4 in `lib/main.dart` ergänzen:

```dart
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const ProviderScope(child: DartsApp()));
}
```

## 6. Firestore-Sicherheitsregeln (Minimal-Variante)

Da Security bewusst niedrig priorisiert ist, reicht ein einfaches Regelwerk: Lesen für alle (auch ohne Login, z.B. für den GitHub-Actions-Newsagent), Schreiben nur für angemeldete Nutzer auf ihr eigenes `users/{uid}`-Dokument. Für den News-Agent-Schreibzugriff (`news`-Collection) wird stattdessen der Firebase Admin SDK Service-Account genutzt, der Regeln umgeht — dafür muss `news` also nicht für normale Nutzer beschreibbar sein.

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /players/{playerId} { allow read: if true; allow write: if false; }
    match /events/{eventId} {
      allow read: if true;
      allow write: if false;
      match /standings/{playerId} { allow read: if true; allow write: if false; }
    }
    match /matches/{matchId} { allow read: if true; allow write: if false; }
    match /news/{newsId} { allow read: if true; allow write: if false; }
    match /users/{uid} { allow read, write: if request.auth != null && request.auth.uid == uid; }
  }
}
```

## 7. Repository-Implementierungen ersetzen

Jede Mock-Repository-Klasse (`lib/repositories/*_repository.dart`) hat ein Gegenstück, das noch fehlt: eine `Firestore*Repository`-Klasse, die dasselbe Interface implementiert und `cloud_firestore` statt `Fixtures` nutzt. Danach in `lib/providers/repository_providers.dart` einfach die Provider-Implementierung austauschen — der Rest der App (Screens, Widgets) ändert sich nicht, da alles nur gegen die Interfaces programmiert ist.

Das ist der nächste Implementierungsschritt, sobald das Firebase-Projekt eingerichtet ist — bitte Bescheid geben, wenn Schritt 1–4 erledigt sind.
