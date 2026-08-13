// Läuft per GitHub Actions Cron alle 15 Min. (siehe .github/workflows/match-agent.yml).
// Hält während eines laufenden/anstehenden Turniers Status und Spielstand der
// bereits in Firestore angelegten Matches über Websuche (OpenRouter) aktuell.
//
// Bewusste Grenze: Das Skript aktualisiert nur vorhandene Match-Dokumente
// (Status/Score) und schaltet event.status von "upcoming" auf "live", sobald
// ein Match läuft. Es erzeugt KEINE neuen Matches für Folgerunden (Viertel-/
// Halbfinale/Finale) — dafür bräuchte es das komplette Turnierbaum-Schema,
// das noch nicht modelliert ist (siehe CLAUDE.md). Folgerunden müssen also
// weiterhin manuell per Skript ergänzt werden, sobald die Paarungen feststehen.

import { cert, initializeApp } from "firebase-admin/app";
import { getFirestore } from "firebase-admin/firestore";

const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT_JSON);
initializeApp({ credential: cert(serviceAccount) });
const db = getFirestore();

const OPENROUTER_MODEL = process.env.OPENROUTER_MODEL || "anthropic/claude-sonnet-5";

// Zeitfenster um Start/Ende eines Events, in dem das Skript überhaupt aktiv
// wird — hält die meisten der alle 15 Min. laufenden Aufrufe billig (kein
// API-Call), wenn gerade kein Turnier ansteht.
const PRE_WINDOW_MS = 2 * 60 * 60 * 1000;
const POST_WINDOW_MS = 12 * 60 * 60 * 1000;

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

async function fetchMatchUpdate({ eventName, player1Name, player2Name }) {
  const prompt =
    `Suche den aktuellen Status des Darts-Erstrunden-/K.o.-Matches "${player1Name}" gegen ` +
    `"${player2Name}" beim Turnier "${eventName}". Antworte ausschließlich mit einem JSON-Objekt: ` +
    `{"status": "scheduled" | "live" | "finished", "sets": [Zahl für ${player1Name}, Zahl für ${player2Name}] oder null, ` +
    `"legs": [Zahl für ${player1Name}, Zahl für ${player2Name}] oder null}. ` +
    `"scheduled", wenn das Match noch nicht begonnen hat. Kein Text außerhalb des JSON-Objekts.`;

  const text = await callOpenRouter(prompt);
  return parseJsonObject(text);
}

async function processEvent(event, playerNameById) {
  const matchesSnapshot = await db.collection("matches").where("eventId", "==", event.id).get();
  const pendingMatches = matchesSnapshot.docs.filter((doc) => doc.data().status !== "finished");

  if (pendingMatches.length === 0) {
    console.log(`Event "${event.name}": alle bekannten Matches bereits abgeschlossen, nichts zu tun.`);
    return;
  }

  let anyLive = false;
  let updated = 0;

  for (const doc of pendingMatches) {
    const match = doc.data();
    const player1Name = playerNameById.get(match.player1Id) ?? match.player1Id;
    const player2Name = playerNameById.get(match.player2Id) ?? match.player2Id;

    const update = await fetchMatchUpdate({ eventName: event.name, player1Name, player2Name });
    if (!update || !["scheduled", "live", "finished"].includes(update.status)) continue;

    if (update.status === "live") anyLive = true;
    if (update.status === "scheduled" && match.status === "scheduled") continue; // keine Änderung

    await doc.ref.update({
      status: update.status,
      score:
        Array.isArray(update.sets) && Array.isArray(update.legs)
          ? { sets: update.sets, legs: update.legs }
          : match.score ?? null,
    });
    updated += 1;
    console.log(`  ${player1Name} vs ${player2Name}: ${match.status} -> ${update.status}`);
  }

  if (anyLive && event.status === "upcoming") {
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
