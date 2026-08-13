// Setzt Firestore auf einen sauberen Stand mit der echten PDC-Weltrangliste
// (Order of Merit, Top 30, Stand siehe unten) zurück. Entfernt vorher alle
// alten Platzhalter-/Demo-Daten (fiktive Spieler, Event, Matches, News), da
// die auf erfundene Spieler-IDs verweisen und mit echten Spielern nicht mehr
// zusammenpassen. Events/Matches/News bleiben danach leer, bis echte
// Turnierdaten eingepflegt werden — die App zeigt dafür bewusst einen
// "Gerade kein Event geplant"-Zustand statt erfundener Inhalte.
//
// Quellen (2026-08-13, siehe CLAUDE.md-Historie): PDC Order of Merit
// (thedartscout.com / dartsnews.com) für Rang + Preisgeld-Reihenfolge,
// mastercaller.com für Länder, dartsnews.com "Yearly Average Rankings" für
// die 3-Dart-Averages, die tatsächlich verifiziert werden konnten (10 von
// 30 Spielern — für den Rest ist average3Dart bewusst 0, kein Rateswert).
// checkoutPercentage/count180s/highFinish sind für alle 30 noch 0 (nicht
// recherchiert) — die App zeigt 0-Werte als "–" statt als falsche Zahl.
//
// Aufruf:
//   FIREBASE_SERVICE_ACCOUNT_JSON="$(cat serviceAccountKey.json)" node seed.mjs

import { cert, initializeApp } from "firebase-admin/app";
import { getFirestore } from "firebase-admin/firestore";

const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT_JSON);
initializeApp({ credential: cert(serviceAccount) });
const db = getFirestore();

const emptyStats = { average3Dart: 0, checkoutPercentage: 0, count180s: 0, highFinish: 0 };
const withAverage = (avg) => ({ ...emptyStats, average3Dart: avg });

const players = [
  { id: "luke-littler", name: "Luke Littler", country: "EN", rankingPosition: 1, stats: withAverage(101.86) },
  { id: "gian-van-veen", name: "Gian van Veen", country: "NL", rankingPosition: 2, stats: emptyStats },
  { id: "luke-humphries", name: "Luke Humphries", country: "EN", rankingPosition: 3, stats: withAverage(101.07) },
  { id: "gerwyn-price", name: "Gerwyn Price", country: "WA", rankingPosition: 4, stats: withAverage(99.37) },
  { id: "jonny-clayton", name: "Jonny Clayton", country: "WA", rankingPosition: 5, stats: withAverage(96.02) },
  { id: "james-wade", name: "James Wade", country: "EN", rankingPosition: 6, stats: emptyStats },
  { id: "michael-van-gerwen", name: "Michael van Gerwen", country: "NL", rankingPosition: 7, stats: withAverage(96.84) },
  { id: "josh-rock", name: "Josh Rock", country: "NI", rankingPosition: 8, stats: emptyStats },
  { id: "stephen-bunting", name: "Stephen Bunting", country: "EN", rankingPosition: 9, stats: emptyStats },
  { id: "danny-noppert", name: "Danny Noppert", country: "NL", rankingPosition: 10, stats: emptyStats },
  { id: "gary-anderson", name: "Gary Anderson", country: "SC", rankingPosition: 11, stats: withAverage(98.67) },
  { id: "ryan-searle", name: "Ryan Searle", country: "EN", rankingPosition: 12, stats: emptyStats },
  { id: "wessel-nijman", name: "Wessel Nijman", country: "NL", rankingPosition: 13, stats: withAverage(97.64) },
  { id: "chris-dobey", name: "Chris Dobey", country: "EN", rankingPosition: 14, stats: withAverage(97.66) },
  { id: "nathan-aspinall", name: "Nathan Aspinall", country: "EN", rankingPosition: 15, stats: emptyStats },
  { id: "ross-smith", name: "Ross Smith", country: "EN", rankingPosition: 16, stats: emptyStats },
  { id: "jermaine-wattimena", name: "Jermaine Wattimena", country: "NL", rankingPosition: 17, stats: emptyStats },
  { id: "luke-woodhouse", name: "Luke Woodhouse", country: "EN", rankingPosition: 18, stats: emptyStats },
  { id: "martin-schindler", name: "Martin Schindler", country: "DE", rankingPosition: 19, stats: emptyStats },
  { id: "damon-heta", name: "Damon Heta", country: "AU", rankingPosition: 20, stats: emptyStats },
  { id: "krzysztof-ratajski", name: "Krzysztof Ratajski", country: "PL", rankingPosition: 21, stats: emptyStats },
  { id: "dirk-van-duijvenbode", name: "Dirk van Duijvenbode", country: "NL", rankingPosition: 22, stats: withAverage(96.05) },
  { id: "rob-cross", name: "Rob Cross", country: "EN", rankingPosition: 23, stats: emptyStats },
  { id: "mike-de-decker", name: "Mike De Decker", country: "BE", rankingPosition: 24, stats: emptyStats },
  { id: "ryan-joyce", name: "Ryan Joyce", country: "EN", rankingPosition: 25, stats: emptyStats },
  { id: "cameron-menzies", name: "Cameron Menzies", country: "SC", rankingPosition: 26, stats: emptyStats },
  { id: "andrew-gilding", name: "Andrew Gilding", country: "EN", rankingPosition: 27, stats: emptyStats },
  { id: "dave-chisnall", name: "Dave Chisnall", country: "EN", rankingPosition: 28, stats: emptyStats },
  { id: "daryl-gurney", name: "Daryl Gurney", country: "NI", rankingPosition: 29, stats: emptyStats },
  { id: "kevin-doets", name: "Kevin Doets", country: "NL", rankingPosition: 30, stats: withAverage(96.57) },
];

async function deleteCollection(ref) {
  const snapshot = await ref.get();
  if (snapshot.empty) return;
  const batch = db.batch();
  for (const doc of snapshot.docs) {
    // Subcollections (z.B. events/{id}/standings) hängen nicht am Elterndokument
    // und müssen einzeln geleert werden, bevor das Elterndokument gelöscht wird.
    const standings = await doc.ref.collection("standings").get();
    for (const s of standings.docs) batch.delete(s.ref);
    batch.delete(doc.ref);
  }
  await batch.commit();
}

async function seed() {
  await Promise.all(
    ["players", "events", "matches", "news"].map((name) => deleteCollection(db.collection(name))),
  );

  const batch = db.batch();
  for (const { id, ...data } of players) {
    batch.set(db.collection("players").doc(id), data);
  }
  await batch.commit();

  console.log(`Seed abgeschlossen: ${players.length} echte Spieler (Order of Merit Top 30) geschrieben.`);
  console.log("Events/Matches/News sind jetzt leer — die App zeigt den Leer-Zustand, bis echte Turnierdaten folgen.");
}

seed().catch((error) => {
  console.error("Seed fehlgeschlagen:", error);
  process.exitCode = 1;
});
