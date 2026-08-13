// Einmaliger, additiver Import des echten New Zealand Darts Masters 2026
// (14.–15.08.2026, Spark Arena Auckland) — im Gegensatz zu seed.mjs wird hier
// NICHTS gelöscht, nur ergänzt. Nicht erneut ausführen, nachdem das Turnier
// vorbei ist, ohne die Daten vorher zu aktualisieren (K.o.-Turnierdaten
// veralten anders als die Weltrangliste — siehe CLAUDE.md).
//
// Quellen (2026-08-13): dartsnews.com (Format, Draw-Status), Sky Sports +
// dartsworld.com (vollständige 1.-Runden-Paarung, Startzeit 19:00 NZST),
// pdc.tv + nzherald.co.nz (Nationalitäten der Oceanic-Qualifikanten).
//
// Aufruf:
//   FIREBASE_SERVICE_ACCOUNT_JSON="$(cat serviceAccountKey.json)" node seed-nz-masters-2026.mjs

import { cert, initializeApp } from "firebase-admin/app";
import { getFirestore, Timestamp } from "firebase-admin/firestore";

const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT_JSON);
initializeApp({ credential: cert(serviceAccount) });
const db = getFirestore();

const emptyStats = { average3Dart: 0, checkoutPercentage: 0, count180s: 0, highFinish: 0 };

// Oceanic-Qualifikanten — nicht in der PDC Order of Merit Top 30, daher
// Rangpositionen 31+ (keine offizielle Weltrangliste für diese Spieler).
const qualifiers = [
  { id: "jonny-tata", name: "Jonny Tata", country: "NZ", rankingPosition: 31, stats: emptyStats },
  { id: "haupai-puha", name: "Haupai Puha", country: "NZ", rankingPosition: 32, stats: emptyStats },
  { id: "kayden-milne", name: "Kayden Milne", country: "NZ", rankingPosition: 33, stats: emptyStats },
  { id: "simon-whitlock", name: "Simon Whitlock", country: "AU", rankingPosition: 34, stats: emptyStats },
  { id: "mark-cleaver", name: "Mark Cleaver", country: "NZ", rankingPosition: 35, stats: emptyStats },
  { id: "ben-robb", name: "Ben Robb", country: "NZ", rankingPosition: 36, stats: emptyStats },
  { id: "raymond-smith", name: "Raymond Smith", country: "AU", rankingPosition: 37, stats: emptyStats },
  { id: "adam-leek", name: "Adam Leek", country: "AU", rankingPosition: 38, stats: emptyStats },
];

const eventId = "nz-darts-masters-2026";
const event = {
  name: "New Zealand Darts Masters 2026",
  status: "upcoming",
  format: "knockout",
  venue: "Spark Arena, Auckland",
  startDate: Timestamp.fromDate(new Date("2026-08-14T00:00:00Z")),
  endDate: Timestamp.fromDate(new Date("2026-08-15T23:59:00Z")),
  currentRound: null,
};

// 19:00 NZST (UTC+12, kein Sommerzeit-Versatz im August) = 07:00 UTC.
const round1Start = Timestamp.fromDate(new Date("2026-08-14T07:00:00Z"));

const matches = [
  { id: "nzdm2026-r1-1", player1Id: "gian-van-veen", player2Id: "jonny-tata" },
  { id: "nzdm2026-r1-2", player1Id: "jonny-clayton", player2Id: "haupai-puha" },
  { id: "nzdm2026-r1-3", player1Id: "james-wade", player2Id: "kayden-milne" },
  { id: "nzdm2026-r1-4", player1Id: "josh-rock", player2Id: "simon-whitlock" },
  { id: "nzdm2026-r1-5", player1Id: "gerwyn-price", player2Id: "mark-cleaver" },
  { id: "nzdm2026-r1-6", player1Id: "damon-heta", player2Id: "ben-robb" },
  { id: "nzdm2026-r1-7", player1Id: "stephen-bunting", player2Id: "raymond-smith" },
  { id: "nzdm2026-r1-8", player1Id: "ross-smith", player2Id: "adam-leek" },
].map((m) => ({
  ...m,
  eventId,
  status: "scheduled",
  scheduledAt: round1Start,
  score: null,
  throwingPlayerId: null,
}));

async function seed() {
  const batch = db.batch();

  for (const { id, ...data } of qualifiers) {
    batch.set(db.collection("players").doc(id), data);
  }

  batch.set(db.collection("events").doc(eventId), event);

  for (const { id, ...data } of matches) {
    batch.set(db.collection("matches").doc(id), data);
  }

  await batch.commit();
  console.log(
    `New Zealand Darts Masters 2026 importiert: ${qualifiers.length} Qualifikanten, 1 Event, ${matches.length} Erstrunden-Matches.`,
  );
}

seed().catch((error) => {
  console.error("Import fehlgeschlagen:", error);
  process.exitCode = 1;
});
