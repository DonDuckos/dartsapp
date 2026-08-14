import assert from "node:assert/strict";
import { bzzoiroToUpdate, findBzzoiroMatch, namesMatch } from "./bzzoiro.mjs";

// Unsere echten Firestore-Namen, unsere 8 NZ-Masters-Erstrundenpaarungen.
const ourPairs = [
  ["Gian van Veen", "Jonny Tata"],
  ["Jonny Clayton", "Haupai Puha"],
  ["James Wade", "Kayden Milne"],
  ["Josh Rock", "Simon Whitlock"],
  ["Gerwyn Price", "Mark Cleaver"],
  ["Damon Heta", "Ben Robb"],
  ["Stephen Bunting", "Raymond Smith"],
  ["Ross Smith", "Adam Leek"],
];

// bzzoiro liefert laut Schema "Full display name" — wir testen trotzdem
// bewusst mit vertauschter Reihenfolge (player1/player2 relativ zu uns
// getauscht), um sicherzustellen, dass das kein stilles Falsch-Zuordnen der
// Sets/Legs verursacht.
const bzzoiroMatches = ourPairs.map(([p1, p2], i) => ({
  id: i,
  status: "scheduled",
  player1: { name: p2 }, // absichtlich vertauscht
  player2: { name: p1 },
  player1_sets: null,
  player2_sets: null,
  sets_detail: null,
}));

for (let i = 0; i < ourPairs.length; i++) {
  const [p1, p2] = ourPairs[i];
  const found = findBzzoiroMatch({ matches: bzzoiroMatches, liveMatches: [] }, p1, p2);
  assert.ok(found, `Kein Match gefunden für Paar ${i}: ${p1} vs ${p2}`);
  assert.equal(found.bMatch.id, i, `Falsches Match gefunden für Paar ${i}`);
}
console.log("Alle 8 Paare korrekt gematcht (inkl. vertauschter Reihenfolge).");

// "Jonny Clayton" und "Jonny Tata" teilen den Vornamen — trotzdem darf das
// jeweils richtige Match gefunden werden, weil beide Spieler eines Paares
// übereinstimmen müssen, nicht nur einer.
const foundClayton = findBzzoiroMatch({ matches: bzzoiroMatches, liveMatches: [] }, "Jonny Clayton", "Haupai Puha");
assert.equal(foundClayton.bMatch.id, 1);
const foundTata = findBzzoiroMatch({ matches: bzzoiroMatches, liveMatches: [] }, "Gian van Veen", "Jonny Tata");
assert.equal(foundTata.bMatch.id, 0);
console.log("Gemeinsamer Vorname 'Jonny' führt zu keiner Verwechslung.");

// Sets/Legs müssen bei vertauschter bzzoiro-Reihenfolge korrekt zurückgedreht werden.
const swappedMatch = {
  status: "live",
  player1_sets: 2, // gehört laut bzzoiro zu player2 (= unser player1: "James Wade")
  player2_sets: 1,
  sets_detail: [{ set_number: 4, player1_legs: 3, player2_legs: 1 }],
};
const foundWade = findBzzoiroMatch(
  { matches: [{ ...swappedMatch, player1: { name: "Kayden Milne" }, player2: { name: "James Wade" } }], liveMatches: [] },
  "James Wade",
  "Kayden Milne",
);
assert.equal(foundWade.swapped, true);
const wadeUpdate = bzzoiroToUpdate(foundWade.bMatch, foundWade.liveMatch, foundWade.swapped);
assert.deepEqual(wadeUpdate, { status: "live", sets: [1, 2], legs: [1, 3] });
console.log("Vertauschte bzzoiro-Reihenfolge wird korrekt zurückgedreht (Sets UND Legs).");

// Regressionstest für den vom Nutzer gemeldeten Bug: Match ist laut bzzoiro
// "live" mit Legs 5:0 im laufenden ersten Set, aber player1_sets/
// player2_sets sind noch null (kein Set abgeschlossen) UND das Match wurde
// nicht in der Live-Liste gefunden (z.B. Name-Mismatch bei diesem Aufruf) —
// die alte Fassung verwarf dadurch das komplette Update.
const liveNoSetsYet = bzzoiroToUpdate(
  { status: "live", player1_sets: null, player2_sets: null, sets_detail: null },
  undefined,
  false,
);
assert.deepEqual(liveNoSetsYet, { status: "live", sets: [0, 0], legs: [0, 0] });
console.log("Live-Match ohne bekannte Sets/Legs bekommt 0:0 statt verworfen zu werden.");

// Sets bekannt (0:0, noch kein Set gewonnen), Legs bekannt aus Live-Detail —
// beide Werte müssen erhalten bleiben, nicht durch den 0:0-Fallback ersetzt.
const liveWithLegs = bzzoiroToUpdate(
  { status: "live", player1_sets: 0, player2_sets: 0, sets_detail: null },
  { player1_legs: 5, player2_legs: 0, current_set: 1 },
  false,
);
assert.deepEqual(liveWithLegs, { status: "live", sets: [0, 0], legs: [5, 0] });
console.log("Bekannte Legs (5:0) im laufenden ersten Set werden korrekt übernommen.");

// Live-Legs werden bevorzugt vor sets_detail, wenn beide vorhanden sind.
const bMatchLive = {
  status: "live",
  player1_sets: 1,
  player2_sets: 0,
  sets_detail: [{ set_number: 1, player1_legs: 3, player2_legs: 2 }],
};
const liveDetail = { player1_legs: 1, player2_legs: 0, current_set: 2 };
assert.deepEqual(bzzoiroToUpdate(bMatchLive, liveDetail, false), { status: "live", sets: [1, 0], legs: [1, 0] });
assert.deepEqual(bzzoiroToUpdate(bMatchLive, undefined, false), { status: "live", sets: [1, 0], legs: [3, 2] });
console.log("Legs-Priorität (Live-Detail vor sets_detail) korrekt.");

// Vor Turnierbeginn: sets/legs beide null, kein Crash.
const scheduled = bzzoiroToUpdate(
  { status: "scheduled", player1_sets: null, player2_sets: null, sets_detail: null },
  undefined,
  false,
);
assert.deepEqual(scheduled, { status: "scheduled", sets: null, legs: null });
console.log("Scheduled-Match ohne Score korrekt behandelt.");

assert.equal(namesMatch("Gian van Veen", "van Veen G."), true);
assert.equal(namesMatch("Ross Smith", "Adam Leek"), false);
console.log("namesMatch-Grundfälle OK.");

console.log("\nAlle Tests grün.");
