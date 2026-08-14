// Debug-Hilfsskript: zeigt Status/Score aller Matches eines Events auf einen
// Blick, ohne durch die Firebase Console klicken zu müssen.
//   node check-matches.mjs
import { readFileSync } from "node:fs";
import { cert, initializeApp } from "firebase-admin/app";
import { getFirestore } from "firebase-admin/firestore";

const sa = JSON.parse(readFileSync("./serviceAccountKey.json", "utf8"));
initializeApp({ credential: cert(sa) });
const db = getFirestore();

console.log("Jetzt (UTC):", new Date().toISOString());

const event = await db.collection("events").doc("nz-darts-masters-2026").get();
console.log("\nEvent status:", event.data().status, "currentRound:", event.data().currentRound);

const matches = await db.collection("matches").where("eventId", "==", "nz-darts-masters-2026").get();
const sorted = matches.docs.map((d) => d.data()).sort((a, b) => a.scheduledAt.toDate() - b.scheduledAt.toDate());
for (const m of sorted) {
  console.log(
    `${m.scheduledAt.toDate().toISOString()} | ${m.status.padEnd(10)} | ${m.player1Id} vs ${m.player2Id} | score: ${m.score ? JSON.stringify(m.score) : "–"}`,
  );
}
