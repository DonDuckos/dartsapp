// Einmalig ausführen, um Firestore mit den bisherigen Mock-Daten
// (lib/data/fixtures.dart) zu befüllen, damit die App nach dem Umstieg auf
// Firestore nicht leer ist. Gefahrlos mehrfach ausführbar (überschreibt die
// gleichen Dokument-IDs).
//
// Aufruf:
//   FIREBASE_SERVICE_ACCOUNT_JSON="$(cat serviceAccountKey.json)" node seed.mjs

import { cert, initializeApp } from "firebase-admin/app";
import { FieldValue, getFirestore, Timestamp } from "firebase-admin/firestore";

const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT_JSON);
initializeApp({ credential: cert(serviceAccount) });
const db = getFirestore();

const players = [
  { id: "vandijk", name: "J. van Dijk", country: "NL", rankingPosition: 1, stats: { average3Dart: 98.4, checkoutPercentage: 44.1, count180s: 61, highFinish: 161 }, bio: "Amsterdam · Rechtshänder · Profi seit 2016" },
  { id: "krueger", name: "M. Krüger", country: "DE", rankingPosition: 2, stats: { average3Dart: 96.9, checkoutPercentage: 41.8, count180s: 54, highFinish: 170 }, bio: "Köln · Rechtshänder · Profi seit 2018" },
  { id: "petrov", name: "I. Petrov", country: "BG", rankingPosition: 3, stats: { average3Dart: 95.1, checkoutPercentage: 40.2, count180s: 49, highFinish: 156 } },
  { id: "novak", name: "T. Novak", country: "SI", rankingPosition: 4, stats: { average3Dart: 93.7, checkoutPercentage: 39.6, count180s: 45, highFinish: 167 } },
  { id: "fischer", name: "L. Fischer", country: "DE", rankingPosition: 5, stats: { average3Dart: 92.8, checkoutPercentage: 38.9, count180s: 42, highFinish: 148 }, bio: "Stuttgart · Linkshänder · Profi seit 2020" },
  { id: "bakker", name: "S. Bakker", country: "NL", rankingPosition: 6, stats: { average3Dart: 91.6, checkoutPercentage: 38.1, count180s: 38, highFinish: 140 } },
  { id: "keller", name: "D. Keller", country: "AT", rankingPosition: 7, stats: { average3Dart: 90.9, checkoutPercentage: 37.4, count180s: 36, highFinish: 132 } },
  { id: "albrecht", name: "N. Albrecht", country: "DE", rankingPosition: 8, stats: { average3Dart: 90.2, checkoutPercentage: 36.8, count180s: 33, highFinish: 145 } },
];

const eventId = "cdt-2026";
const event = {
  name: "Continental Darts Trophy",
  status: "live",
  format: "roundRobin",
  startDate: Timestamp.fromDate(new Date(Date.now() - 2 * 24 * 60 * 60 * 1000)),
  endDate: Timestamp.fromDate(new Date(Date.now() + 1 * 24 * 60 * 60 * 1000)),
  currentRound: "Halbfinale",
};

const standings = [
  { playerId: "vandijk", position: 1, wins: 3, losses: 0, legsFor: 9, legsAgainst: 2, nextOpponentPlayerId: "petrov" },
  { playerId: "krueger", position: 2, wins: 2, losses: 1, legsFor: 7, legsAgainst: 5, nextOpponentPlayerId: "novak" },
  { playerId: "petrov", position: 3, wins: 1, losses: 2, legsFor: 5, legsAgainst: 6, nextOpponentPlayerId: "vandijk" },
  { playerId: "bakker", position: 4, wins: 1, losses: 2, legsFor: 4, legsAgainst: 7, nextOpponentPlayerId: null },
  { playerId: "novak", position: 5, wins: 0, losses: 3, legsFor: 3, legsAgainst: 9, nextOpponentPlayerId: "krueger" },
];

const matches = [
  {
    id: "m-live-1",
    eventId,
    player1Id: "krueger",
    player2Id: "vandijk",
    status: "live",
    scheduledAt: Timestamp.fromDate(new Date(Date.now() - 40 * 60 * 1000)),
    score: { sets: [2, 1], legs: [3, 2] },
    throwingPlayerId: "krueger",
  },
  {
    id: "m-next-1",
    eventId,
    player1Id: "fischer",
    player2Id: "novak",
    status: "scheduled",
    scheduledAt: Timestamp.fromDate(new Date(Date.now() + 60 * 60 * 1000)),
    score: null,
    throwingPlayerId: null,
  },
];

const news = [
  {
    id: "n1",
    title: "Krüger erzwingt Decider – Halbfinale geht in den fünften Satz",
    summary: "Im Halbfinale der Continental Darts Trophy gleicht Mika Krüger gegen Joran van Dijk zum 2:1 aus und erzwingt einen fünften Satz.",
    sourceUrl: "https://example.org/news/kruger-decider",
    sourceName: "Redaktion",
    publishedAt: Timestamp.fromDate(new Date(Date.now() - 4 * 60 * 1000)),
    relatedPlayerIds: ["krueger", "vandijk"],
    isFlash: true,
    imageUrl: null,
  },
  {
    id: "n2",
    title: "Van Dijk übernimmt Tabellenführung nach Gruppensieg",
    summary: "Mit einem klaren Sieg in der Gruppenphase sichert sich Joran van Dijk Platz eins vor dem Halbfinale.",
    sourceUrl: "https://example.org/news/vandijk-tabelle",
    sourceName: "Redaktion",
    publishedAt: Timestamp.fromDate(new Date(Date.now() - 38 * 60 * 1000)),
    relatedPlayerIds: ["vandijk"],
    isFlash: false,
    imageUrl: null,
  },
  {
    id: "n3",
    title: "Neuer Checkout-Rekord: Novak trifft 167 aus dem Stand",
    summary: "Toma Novak markiert mit einem 167er-Finish den höchsten Checkout des Turniers.",
    sourceUrl: "https://example.org/news/novak-checkout",
    sourceName: "Redaktion",
    publishedAt: Timestamp.fromDate(new Date(Date.now() - 60 * 60 * 1000)),
    relatedPlayerIds: ["novak"],
    isFlash: false,
    imageUrl: null,
  },
  {
    id: "n4",
    title: "Vorschau: Fischer gegen Albrecht im Viertelfinale",
    summary: "Luca Fischer trifft im Viertelfinale auf Noah Albrecht — beide gewannen ihre Gruppen ungeschlagen.",
    sourceUrl: "https://example.org/news/fischer-albrecht-vorschau",
    sourceName: "Redaktion",
    publishedAt: Timestamp.fromDate(new Date(Date.now() - 3 * 60 * 60 * 1000)),
    relatedPlayerIds: ["fischer", "albrecht"],
    isFlash: false,
    imageUrl: null,
  },
];

async function seed() {
  const batch = db.batch();

  for (const { id, ...data } of players) {
    batch.set(db.collection("players").doc(id), data);
  }

  batch.set(db.collection("events").doc(eventId), event);

  for (const entry of standings) {
    const { playerId, ...data } = entry;
    batch.set(db.collection("events").doc(eventId).collection("standings").doc(playerId), data);
  }

  for (const { id, ...data } of matches) {
    batch.set(db.collection("matches").doc(id), data);
  }

  for (const { id, ...data } of news) {
    batch.set(db.collection("news").doc(id), data);
  }

  await batch.commit();
  console.log(
    `Seed abgeschlossen: ${players.length} Spieler, 1 Event, ${standings.length} Standings, ${matches.length} Matches, ${news.length} News.`,
  );
}

seed().catch((error) => {
  console.error("Seed fehlgeschlagen:", error);
  process.exitCode = 1;
});
