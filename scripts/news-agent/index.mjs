// Läuft per GitHub Actions Cron alle 3 Std. (siehe .github/workflows/news-agent.yml).
// Sucht aktuelle Darts-News, lässt Claude sie zusammenfassen und schreibt neue,
// noch unbekannte Meldungen in die Firestore-Collection `news` (Schema siehe
// CLAUDE.md → Datenmodell). Bilder werden hier bewusst NICHT automatisiert von
// Drittseiten übernommen (Lizenzrechte, siehe CLAUDE.md) — imageUrl bleibt leer,
// bis eine eigene/freie Bildquelle angebunden ist.

import Anthropic from "@anthropic-ai/sdk";
import { cert, initializeApp } from "firebase-admin/app";
import { FieldValue, getFirestore } from "firebase-admin/firestore";

const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT_JSON);
initializeApp({ credential: cert(serviceAccount) });
const db = getFirestore();

const anthropic = new Anthropic({ apiKey: process.env.ANTHROPIC_API_KEY });

async function fetchNewsCandidates() {
  // TODO: Modellname und Web-Search-Tool-Definition ggf. an die aktuelle
  // Anthropic-API-Version anpassen (https://docs.anthropic.com/).
  const response = await anthropic.messages.create({
    model: "claude-sonnet-5",
    max_tokens: 2000,
    tools: [{ type: "web_search_20250305", name: "web_search" }],
    messages: [
      {
        role: "user",
        content:
          "Suche nach aktuellen Darts-News der letzten 3 Stunden (Turnierergebnisse, " +
          "besondere Ankündigungen, Rekorde). Antworte ausschließlich mit einem JSON-Array, " +
          "jedes Element mit den Feldern: title (deutsch, kurz), summary (deutsch, 2-3 Sätze), " +
          "sourceUrl, sourceName, relatedPlayerNames (Array von Spielernamen), " +
          "isFlash (true nur bei wirklich besonderen Eilmeldungen, z.B. 9-Darter, Titelgewinn). " +
          "Kein anderer Text außerhalb des JSON-Arrays.",
      },
    ],
  });

  const text = response.content.find((block) => block.type === "text")?.text ?? "[]";
  try {
    return JSON.parse(text);
  } catch {
    console.error("Konnte Claude-Antwort nicht als JSON parsen:", text);
    return [];
  }
}

async function buildPlayerNameToIdMap() {
  const snapshot = await db.collection("players").get();
  const map = new Map();
  for (const doc of snapshot.docs) {
    map.set(doc.data().name, doc.id);
  }
  return map;
}

async function writeNewsItem(candidate, playerNameToId) {
  const existing = await db.collection("news").where("sourceUrl", "==", candidate.sourceUrl).limit(1).get();
  if (!existing.empty) return false;

  const relatedPlayerIds = (candidate.relatedPlayerNames ?? [])
    .map((name) => playerNameToId.get(name))
    .filter(Boolean);

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
  const [candidates, playerNameToId] = await Promise.all([
    fetchNewsCandidates(),
    buildPlayerNameToIdMap(),
  ]);

  let written = 0;
  for (const candidate of candidates) {
    if (!candidate.sourceUrl || !candidate.title) continue;
    if (await writeNewsItem(candidate, playerNameToId)) written += 1;
  }

  console.log(`News-Agent: ${candidates.length} Kandidaten geprüft, ${written} neu geschrieben.`);
}

main().catch((error) => {
  console.error("News-Agent fehlgeschlagen:", error);
  process.exitCode = 1;
});
