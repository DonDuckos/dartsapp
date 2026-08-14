// Läuft per GitHub Actions Cron alle 15 Min. (siehe .github/workflows/match-agent.yml).
// Hält während eines laufenden/anstehenden Turniers Status und Spielstand der
// bereits in Firestore angelegten Matches aktuell.
//
// Primärquelle: die bezahlte bzzoiro-Darts-API (strukturierte Echtzeitdaten,
// 5 $/Monat, siehe CLAUDE.md) — liefert echte Status/Sets/Legs statt einer
// LLM-Interpretation von Websuche-Treffern. Fällt nur für Matches, die dort
// nicht gefunden werden (z.B. API-Ausfall, kein BZZOIRO_API_KEY gesetzt, oder
// ein Spieler/Turnier, das bzzoiro nicht abdeckt), auf die bisherige
// OpenRouter-Websuche pro Match zurück.
//
// Wichtig: Wir fragen bzzoiro NICHT nach unserer eigenen (nur geschätzten)
// Ansetzungsreihenfolge, sondern nach allen Matches im Datumsfenster des
// Events und matchen sie über die Spielernamen zu unseren Firestore-Docs.
// Grund: Die reale Spielreihenfolge einer Session ist nie offiziell bekannt
// (siehe seed-nz-masters-2026.mjs) — unsere geschätzte Reihenfolge kann von
// der echten abweichen, das darf aber nicht dazu führen, dass wir ein Match
// fälschlich für "noch nicht dran" halten.
//
// Bewusste Grenze: Das Skript aktualisiert nur vorhandene Match-Dokumente
// (Status/Score) und schaltet event.status von "upcoming" auf "live", sobald
// ein Match nicht mehr "scheduled" ist (auch direkt "finished" — bei der
// 15-Minuten-Taktung kann ein schnelles Match komplett dazwischen
// durchlaufen, ohne je als "live" beobachtet zu werden). Es erzeugt KEINE
// neuen Matches für Folgerunden (Viertel-/Halbfinale/Finale) — dafür bräuchte
// es das komplette Turnierbaum-Schema, das noch nicht modelliert ist.

import { cert, initializeApp } from "firebase-admin/app";
import { getFirestore, Timestamp } from "firebase-admin/firestore";
import { bzzoiroToUpdate, findBzzoiroMatch, loadBzzoiroData } from "./bzzoiro.mjs";

const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT_JSON);
initializeApp({ credential: cert(serviceAccount) });
const db = getFirestore();

const OPENROUTER_MODEL = process.env.OPENROUTER_MODEL || "moonshotai/kimi-k2-0905";
const BZZOIRO_API_KEY = process.env.BZZOIRO_API_KEY;

// Zeitfenster um Start/Ende eines Events, in dem das Skript überhaupt aktiv
// wird — hält die meisten der alle 15 Min. laufenden Aufrufe billig (kein
// API-Call), wenn gerade kein Turnier ansteht.
const PRE_WINDOW_MS = 2 * 60 * 60 * 1000;
const POST_WINDOW_MS = 12 * 60 * 60 * 1000;

// Plausibilitäts-Check: ein Match kann nicht "live" oder "finished" sein,
// solange sein (von uns geschätzter) Ansetzungstermin noch deutlich in der
// Zukunft liegt. Gilt NUR für die OpenRouter-Fallback-Quelle (Schutz vor
// Modell-Halluzinationen) — bei bzzoiro (echte Strukturdaten) würde der
// Check nur gegen unsere eigene, oft ungenaue geschätzte Zeit prüfen und
// dadurch echte Updates verwerfen (siehe unten, scheduledAt-Korrektur).
const EARLY_START_TOLERANCE_MS = 30 * 60 * 1000;

// Ab welcher Abweichung wir unsere geschätzte scheduledAt-Zeit durch die
// von bzzoiro gemeldete tatsächliche Ansetzungszeit ersetzen.
const SCHEDULED_AT_DRIFT_TOLERANCE_MS = 5 * 60 * 1000;

// --- OpenRouter (Fallback-Quelle) ---

async function callOpenRouter(prompt) {
  const response = await fetch("https://openrouter.ai/api/v1/chat/completions", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${process.env.OPENROUTER_API_KEY}`,
      "Content-Type": "application/json",
      "HTTP-Referer": "https://github.com/DonDuckos/dartsapp",
      "X-Title": "DartsApp Match Agent",
    },
    body: JSON.stringify({
      model: `${OPENROUTER_MODEL}:online`,
      messages: [{ role: "user", content: prompt }],
    }),
  });

  if (!response.ok) {
    throw new Error(`OpenRouter-Fehler ${response.status}: ${await response.text()}`);
  }

  const data = await response.json();
  return data.choices?.[0]?.message?.content ?? "";
}

function parseJsonObject(text) {
  const attempts = [text.trim()];

  const fenceMatch = text.match(/```(?:json)?\s*([\s\S]*?)```/i);
  if (fenceMatch) attempts.push(fenceMatch[1].trim());

  const start = text.indexOf("{");
  const end = text.lastIndexOf("}");
  if (start !== -1 && end !== -1 && end > start) attempts.push(text.slice(start, end + 1));

  for (const attempt of attempts) {
    try {
      const parsed = JSON.parse(attempt);
      if (parsed && typeof parsed === "object") return parsed;
    } catch {
      // nächsten Versuch probieren
    }
  }
  console.error("Konnte Antwort nicht als JSON-Objekt parsen:", text);
  return null;
}

async function fetchMatchUpdateViaOpenRouter({ eventName, player1Name, player2Name }) {
  const prompt =
    `Suche den aktuellen Status des Darts-Erstrunden-/K.o.-Matches "${player1Name}" gegen ` +
    `"${player2Name}" beim Turnier "${eventName}". Antworte ausschließlich mit einem JSON-Objekt: ` +
    `{"status": "scheduled" | "live" | "finished", "sets": [Zahl für ${player1Name}, Zahl für ${player2Name}] oder null, ` +
    `"legs": [Zahl für ${player1Name}, Zahl für ${player2Name}] oder null}. ` +
    `"scheduled", wenn das Match noch nicht begonnen hat. Kein Text außerhalb des JSON-Objekts.`;

  const text = await callOpenRouter(prompt);
  return parseJsonObject(text);
}

// --- Kern ---

async function findRelevantEvents() {
  const now = Date.now();
  const snapshot = await db.collection("events").where("status", "in", ["upcoming", "live"]).get();
  return snapshot.docs
    .map((doc) => ({ id: doc.id, ...doc.data() }))
    .filter((event) => {
      const start = event.startDate.toDate().getTime();
      const end = event.endDate.toDate().getTime();
      return now >= start - PRE_WINDOW_MS && now <= end + POST_WINDOW_MS;
    });
}

function passesPlausibilityGuard(match, update, label) {
  const scheduledAtMs = match.scheduledAt.toDate().getTime();
  if (update.status !== "scheduled" && scheduledAtMs - Date.now() > EARLY_START_TOLERANCE_MS) {
    console.warn(
      `  ${label}: Update meldet "${update.status}", Match beginnt aber erst ` +
        `${match.scheduledAt.toDate().toISOString()} — als unplausibel verworfen.`,
    );
    return false;
  }
  return true;
}

async function processEvent(event, playerNameById) {
  const matchesSnapshot = await db.collection("matches").where("eventId", "==", event.id).get();
  const pendingMatches = matchesSnapshot.docs.filter((doc) => doc.data().status !== "finished");

  if (pendingMatches.length === 0) {
    console.log(`Event "${event.name}": alle bekannten Matches bereits abgeschlossen, nichts zu tun.`);
    return;
  }

  let bzzoiroData = null;
  if (BZZOIRO_API_KEY) {
    try {
      bzzoiroData = await loadBzzoiroData(event);
    } catch (error) {
      console.warn(`  bzzoiro-Abfrage fehlgeschlagen, falle komplett auf Websuche zurück: ${error.message}`);
    }
  }

  let anyStarted = false;
  let updated = 0;

  for (const doc of pendingMatches) {
    const match = doc.data();
    const player1Name = playerNameById.get(match.player1Id) ?? match.player1Id;
    const player2Name = playerNameById.get(match.player2Id) ?? match.player2Id;
    const label = `${player1Name} vs ${player2Name}`;

    let update = null;
    let source = null;
    let matchDate = null;

    if (bzzoiroData) {
      const found = findBzzoiroMatch(bzzoiroData, player1Name, player2Name);
      if (found) {
        update = bzzoiroToUpdate(found.bMatch, found.liveMatch, found.swapped);
        source = "bzzoiro";
        matchDate = found.bMatch.match_date ? new Date(found.bMatch.match_date) : null;
        if (found.bMatch.status === "live") {
          console.log(
            `  [debug] ${label}: bMatch.sets=${found.bMatch.player1_sets}:${found.bMatch.player2_sets}, ` +
              `sets_detail=${JSON.stringify(found.bMatch.sets_detail)}, ` +
              `liveMatch=${found.liveMatch ? `${found.liveMatch.player1_legs}:${found.liveMatch.player2_legs} (Set ${found.liveMatch.current_set})` : "nicht in /matches/live/ gefunden"}`,
          );
        }
      }
    }

    if (!update) {
      update = await fetchMatchUpdateViaOpenRouter({ eventName: event.name, player1Name, player2Name });
      source = "openrouter";
    }

    if (!update || !["scheduled", "live", "finished"].includes(update.status)) continue;
    if (source === "openrouter" && !passesPlausibilityGuard(match, update, label)) continue;

    if (update.status !== "scheduled") anyStarted = true;

    const fields = {};
    if (update.status !== match.status) fields.status = update.status;
    if (Array.isArray(update.sets) && Array.isArray(update.legs)) {
      fields.score = { sets: update.sets, legs: update.legs };
    } else if (update.status === "live" && match.score == null) {
      // Ein Match kann laut Quelle schon "live" sein, bevor Sets/Legs
      // gemeldet werden (z.B. direkt nach Anwurf) — 0:0 ist der korrekte
      // Wert in dem Moment, kein fehlender Zustand. Verhindert außerdem,
      // dass die UI mit score == null bei status == "live" umgehen muss.
      fields.score = { sets: [0, 0], legs: [0, 0] };
    }
    // bzzoiro kennt die echte Ansetzungszeit — unsere eigene ist nur eine
    // Schätzung (siehe seed-nz-masters-2026.mjs). Korrigieren, damit
    // "nächstes Spiel" auf der Startseite (sortiert nach scheduledAt) auch
    // bei noch nicht gestarteten Matches die echte Reihenfolge zeigt.
    if (matchDate && Math.abs(matchDate.getTime() - match.scheduledAt.toDate().getTime()) > SCHEDULED_AT_DRIFT_TOLERANCE_MS) {
      fields.scheduledAt = Timestamp.fromDate(matchDate);
    }

    if (Object.keys(fields).length === 0) continue; // nichts Neues

    await doc.ref.update(fields);
    updated += 1;
    console.log(
      `  ${label}: ${match.status} -> ${fields.status ?? match.status}` +
        `${fields.scheduledAt ? " (Zeit korrigiert)" : ""} (Quelle: ${source})`,
    );
  }

  if (anyStarted && event.status === "upcoming") {
    await db.collection("events").doc(event.id).update({ status: "live" });
    console.log(`Event "${event.name}": auf "live" gesetzt.`);
  }

  console.log(`Event "${event.name}": ${updated} von ${pendingMatches.length} Matches aktualisiert.`);
}

async function main() {
  const events = await findRelevantEvents();
  if (events.length === 0) {
    console.log("Kein Turnier im relevanten Zeitfenster — nichts zu tun.");
    return;
  }

  const playersSnapshot = await db.collection("players").get();
  const playerNameById = new Map(playersSnapshot.docs.map((doc) => [doc.id, doc.data().name]));

  for (const event of events) {
    await processEvent(event, playerNameById);
  }
}

main().catch((error) => {
  console.error("Match-Agent fehlgeschlagen:", error);
  process.exitCode = 1;
});
