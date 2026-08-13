// Läuft per GitHub Actions Cron alle 3 Std. (siehe .github/workflows/news-agent.yml).
// Sucht aktuelle Darts-News über OpenRouter (Modell + Web-Suche), zusätzlich
// gezielt zu jedem gerade von irgendeinem Nutzer favorisierten Spieler, und
// schreibt neue, noch unbekannte Meldungen in die Firestore-Collection `news`
// (Schema siehe CLAUDE.md → Datenmodell). Bilder werden bewusst NICHT
// automatisiert von Drittseiten übernommen (Lizenzrechte) — imageUrl bleibt leer.

import { cert, initializeApp } from "firebase-admin/app";
import { FieldValue, getFirestore } from "firebase-admin/firestore";

const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT_JSON);
initializeApp({ credential: cert(serviceAccount) });
const db = getFirestore();

// Beliebiges Modell aus https://openrouter.ai/models, ":online" hängt das
// Web-Search-Plugin an. Per Repo-Variable OPENROUTER_MODEL überschreibbar,
// ohne Code-Änderung (Settings → Secrets and variables → Actions → Variables).
const OPENROUTER_MODEL = process.env.OPENROUTER_MODEL || "anthropic/claude-sonnet-5";

const RESPONSE_FORMAT_INSTRUCTIONS =
  "Antworte ausschließlich mit einem JSON-Array, jedes Element mit den Feldern: " +
  "title (deutsch, kurz), summary (deutsch, 2-3 Sätze), sourceUrl, sourceName, " +
  "relatedPlayerNames (Array von Spielernamen), isFlash (true nur bei wirklich " +
  "besonderen Eilmeldungen, z.B. 9-Darter, Titelgewinn). Falls nichts Relevantes " +
  "gefunden wird, antworte mit []. Kein Text außerhalb des JSON-Arrays.";

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

async function writeNewsItem(candidate, nameToId) {
  const existing = await db.collection("news").where("sourceUrl", "==", candidate.sourceUrl).limit(1).get();
  if (!existing.empty) return false;

  const relatedPlayerIds = [
    ...new Set((candidate.relatedPlayerNames ?? []).map((name) => nameToId.get(name)).filter(Boolean)),
  ];

  await db.collection("news").add({
    title: candidate.title,
    summary: candidate.summary,
    sourceUrl: candidate.sourceUrl,
    sourceName: candidate.sourceName,
    publishedAt: FieldValue.serverTimestamp(),
    relatedPlayerIds,
    isFlash: Boolean(candidate.isFlash),
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
