// Läuft per GitHub Actions Cron alle 3 Std. (siehe .github/workflows/news-agent.yml).
// Sucht aktuelle Darts-News über OpenRouter (Modell + Web-Suche), zusätzlich
// gezielt zu jedem gerade von irgendeinem Nutzer favorisierten Spieler, und
// schreibt neue, noch unbekannte Meldungen in die Firestore-Collection `news`
// (Schema siehe CLAUDE.md → Datenmodell). Bilder werden bewusst NICHT
// automatisiert von Drittseiten übernommen (Lizenzrechte) — imageUrl bleibt leer.
//
// WICHTIG (2026-08-14 nachgebessert): `publishedAt` ist das ECHTE Datum der
// Meldung/des Ereignisses, nicht der Zeitpunkt, an dem der Agent sie
// gefunden hat — sonst zeigt die App z.B. eine Monate alte Meldung als
// "gerade eben"/"Eilmeldung" an, weil sie erst heute neu entdeckt wurde
// (genau das ist beim ersten Durchlauf passiert). Das Modell muss daher pro
// Meldung ein Datum liefern, und "isFlash" wird zusätzlich hart gegen dieses
// Datum geprüft, nicht blind übernommen.

import { cert, initializeApp } from "firebase-admin/app";
import { getFirestore, Timestamp } from "firebase-admin/firestore";

const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT_JSON);
initializeApp({ credential: cert(serviceAccount) });
const db = getFirestore();

const OPENROUTER_MODEL = process.env.OPENROUTER_MODEL || "moonshotai/kimi-k2-0905";

const now = new Date();
const todayIso = now.toISOString().slice(0, 10);

const RESPONSE_FORMAT_INSTRUCTIONS =
  `Heutiges Datum: ${todayIso}. Antworte ausschließlich mit einem JSON-Array, jedes Element mit ` +
  "den Feldern: title (deutsch, kurz), summary (deutsch, 2-3 Sätze), sourceUrl, sourceName, " +
  'publishedDate (das TATSÄCHLICHE Datum der Meldung/des Ereignisses im Format "YYYY-MM-DD", ' +
  "NICHT das heutige Datum, außer die Meldung ist wirklich von heute), relatedPlayerNames (Array " +
  "von Spielernamen), isFlash (true NUR wenn publishedDate wirklich innerhalb der letzten 48 " +
  "Stunden liegt UND es sich um etwas wirklich Besonderes handelt, z.B. 9-Darter, Titelgewinn — " +
  "eine ältere Meldung, die du nur gerade erst gefunden hast, ist KEINE Eilmeldung). Falls nichts " +
  "Relevantes gefunden wird, antworte mit []. Kein Text außerhalb des JSON-Arrays.";

async function callOpenRouter(prompt) {
  const response = await fetch("https://openrouter.ai/api/v1/chat/completions", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${process.env.OPENROUTER_API_KEY}`,
      "Content-Type": "application/json",
      "HTTP-Referer": "https://github.com/DonDuckos/dartsapp",
      "X-Title": "DartsApp News Agent",
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

function parseJsonArray(text) {
  const attempts = [text.trim()];

  const fenceMatch = text.match(/```(?:json)?\s*([\s\S]*?)```/i);
  if (fenceMatch) attempts.push(fenceMatch[1].trim());

  const start = text.indexOf("[");
  const end = text.lastIndexOf("]");
  if (start !== -1 && end !== -1 && end > start) {
    attempts.push(text.slice(start, end + 1));
  }

  for (const attempt of attempts) {
    try {
      const parsed = JSON.parse(attempt);
      if (Array.isArray(parsed)) return parsed;
    } catch {
      // nächsten Versuch probieren
    }
  }

  console.error("Konnte Antwort nicht als JSON-Array parsen:", text);
  return [];
}

async function fetchNewsCandidates(focusInstruction) {
  const prompt = `${focusInstruction}\n\n${RESPONSE_FORMAT_INSTRUCTIONS}`;
  const text = await callOpenRouter(prompt);
  return parseJsonArray(text);
}

async function loadPlayerMaps() {
  const snapshot = await db.collection("players").get();
  const nameToId = new Map();
  const idToName = new Map();
  for (const doc of snapshot.docs) {
    const name = doc.data().name;
    nameToId.set(name, doc.id);
    idToName.set(doc.id, name);
  }
  return { nameToId, idToName };
}

async function loadFavoritedPlayerIds() {
  const snapshot = await db.collection("users").get();
  const ids = new Set();
  for (const doc of snapshot.docs) {
    const favorites = doc.data().favoritePlayerIds;
    if (Array.isArray(favorites)) {
      favorites.forEach((id) => ids.add(id));
    }
  }
  return ids;
}

const MAX_AGE_DAYS = 365 * 2;

// Parst publishedDate und prüft auf Plausibilität — fängt sowohl kaputte
// Formate als auch offensichtlich falsche Daten ab (Zukunft, absurd alt).
function parsePublishedDate(value) {
  if (typeof value !== "string") return null;
  const parsed = new Date(`${value}T12:00:00Z`); // Mittags UTC, um Zeitzonen-Off-by-one zu vermeiden
  if (Number.isNaN(parsed.getTime())) return null;
  const ageMs = now.getTime() - parsed.getTime();
  if (ageMs < -24 * 60 * 60 * 1000) return null; // mehr als 1 Tag in der Zukunft
  if (ageMs > MAX_AGE_DAYS * 24 * 60 * 60 * 1000) return null;
  return parsed;
}

async function writeNewsItem(candidate, nameToId) {
  const publishedAt = parsePublishedDate(candidate.publishedDate);
  if (!publishedAt) {
    console.warn(`  Ohne plausibles Datum verworfen: "${candidate.title}" (publishedDate="${candidate.publishedDate}")`);
    return false;
  }

  const existing = await db.collection("news").where("sourceUrl", "==", candidate.sourceUrl).limit(1).get();
  if (!existing.empty) return false;

  const relatedPlayerIds = [
    ...new Set((candidate.relatedPlayerNames ?? []).map((name) => nameToId.get(name)).filter(Boolean)),
  ];

  // isFlash nicht blind übernehmen: nur echte Eilmeldungen der letzten 48 Std.
  const ageHours = (now.getTime() - publishedAt.getTime()) / (60 * 60 * 1000);
  const isFlash = Boolean(candidate.isFlash) && ageHours <= 48;

  await db.collection("news").add({
    title: candidate.title,
    summary: candidate.summary,
    sourceUrl: candidate.sourceUrl,
    sourceName: candidate.sourceName,
    publishedAt: Timestamp.fromDate(publishedAt),
    relatedPlayerIds,
    isFlash,
    imageUrl: null,
  });
  return true;
}

async function main() {
  const { nameToId, idToName } = await loadPlayerMaps();

  const candidates = await fetchNewsCandidates(
    "Suche nach aktuellen Darts-News der letzten 24 Stunden (Turnierergebnisse, " +
      "besondere Ankündigungen, Rekorde, Interviews, Rangliste-Änderungen). Auch außerhalb " +
      "laufender Turniere gibt es meist relevante Meldungen (Transfers, Aussagen, Vorschauen) " +
      "— nicht nur auf Live-Ergebnisse beschränken.",
  );

  const favoritedIds = await loadFavoritedPlayerIds();
  console.log(`${favoritedIds.size} aktuell favorisierte Spieler gefunden, suche zusätzlich gezielt nach ihnen.`);

  for (const playerId of favoritedIds) {
    const name = idToName.get(playerId);
    if (!name) continue;

    const playerCandidates = await fetchNewsCandidates(
      `Suche gezielt nach aktuellen News der letzten 24 Stunden über den Profi-Dartspieler ` +
        `"${name}" (Ergebnisse, Interviews, Ankündigungen, Verletzungen).`,
    );
    // Sicherstellen, dass der gesuchte Spieler immer verknüpft wird, auch falls
    // das Modell den Namen nicht exakt im Feld relatedPlayerNames wiederholt.
    for (const candidate of playerCandidates) {
      candidate.relatedPlayerNames = [...new Set([...(candidate.relatedPlayerNames ?? []), name])];
    }
    candidates.push(...playerCandidates);
  }

  let written = 0;
  const seenInThisRun = new Set();
  for (const candidate of candidates) {
    if (!candidate.sourceUrl || !candidate.title) continue;
    if (seenInThisRun.has(candidate.sourceUrl)) continue;
    seenInThisRun.add(candidate.sourceUrl);
    if (await writeNewsItem(candidate, nameToId)) written += 1;
  }

  console.log(`News-Agent: ${candidates.length} Kandidaten geprüft, ${written} neu geschrieben.`);
}

main().catch((error) => {
  console.error("News-Agent fehlgeschlagen:", error);
  process.exitCode = 1;
});
