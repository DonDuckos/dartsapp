// Einmaliger Hotfix: setzt score auf 0:0 für Matches, die "live" sind, aber
// (noch) keinen Score haben — Ursache des "Null check operator used on a
// null value"-Crashs auf dem Home-Screen, direkt behoben statt auf den
// nächsten Match-Agent-Lauf zu warten.
import { readFileSync } from "node:fs";
import { cert, initializeApp } from "firebase-admin/app";
import { getFirestore } from "firebase-admin/firestore";

const sa = JSON.parse(readFileSync("./serviceAccountKey.json", "utf8"));
initializeApp({ credential: cert(sa) });
const db = getFirestore();

const snapshot = await db.collection("matches").where("status", "==", "live").get();
let fixed = 0;
for (const doc of snapshot.docs) {
  const data = doc.data();
  if (data.score == null) {
    await doc.ref.update({ score: { sets: [0, 0], legs: [0, 0] } });
    console.log(`Gefixt: ${doc.id} (${data.player1Id} vs ${data.player2Id})`);
    fixed += 1;
  }
}
console.log(`${fixed} Match(es) korrigiert.`);
