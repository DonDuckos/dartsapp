// bzzoiro-Darts-API-Client (https://sports.bzzoiro.com/docs/darts/) — bewusst
// von Firebase/OpenRouter getrennt, damit die reine Matching-Logik ohne
// Umgebungsvariablen importierbar und testbar ist (siehe test-matching.mjs).

const BZZOIRO_BASE = "https://sports.bzzoiro.com/darts/api/v2";

async function bzzoiroFetch(path) {
  const response = await fetch(`${BZZOIRO_BASE}${path}`, {
    headers: { Authorization: `Token ${process.env.BZZOIRO_API_KEY}` },
  });
  if (!response.ok) {
    throw new Error(`bzzoiro-Fehler ${response.status} bei ${path}`);
  }
  const data = await response.json();
  return Array.isArray(data) ? data : (data.results ?? []);
}

// bzzoiro und unsere eigenen Daten formatieren Spielernamen möglicherweise
// unterschiedlich (z.B. "Kayden Milne" vs. "Milne K."/"Milne, Kayden") — statt
// uns auf eine feste Reihenfolge/ein festes Format zu verlassen, vergleichen
// wir Namens-Tokens auf Überschneidung. Ein einzelnes gemeinsames Token (der
// Nachname) reicht, um zwei Namen als dieselbe Person zu erkennen; kurze
// Initialen ("G.") fallen nach dem Entfernen von Punkten unter die
// Mindestlänge und zählen nicht mit.
function normalizeTokens(name) {
  return name
    .toLowerCase()
    .replace(/\./g, "")
    .split(/\s+/)
    .filter((token) => token.length > 1);
}

export function namesMatch(nameA, nameB) {
  const tokensB = new Set(normalizeTokens(nameB));
  return normalizeTokens(nameA).some((token) => tokensB.has(token));
}

// Prüft, ob ein Spielerpaar (in beliebiger Reihenfolge) demselben Match
// entspricht wie ein anderes Spielerpaar.
export function pairMatches(ourP1, ourP2, otherP1, otherP2) {
  return (
    (namesMatch(ourP1, otherP1) && namesMatch(ourP2, otherP2)) ||
    (namesMatch(ourP1, otherP2) && namesMatch(ourP2, otherP1))
  );
}

function toDateStr(date) {
  return date.toISOString().slice(0, 10);
}

export async function loadBzzoiroData(event) {
  const dateFrom = toDateStr(new Date(event.startDate.toDate().getTime() - 24 * 60 * 60 * 1000));
  const dateTo = toDateStr(new Date(event.endDate.toDate().getTime() + 24 * 60 * 60 * 1000));

  const [matches, liveMatches] = await Promise.all([
    bzzoiroFetch(`/matches/?date_from=${dateFrom}&date_to=${dateTo}&limit=200`),
    bzzoiroFetch(`/matches/live/`),
  ]);

  return { matches, liveMatches };
}

// Sucht das zu unserem Spielerpaar passende bzzoiro-Match (falls vorhanden)
// sowie — falls es gerade läuft — die zugehörigen Live-Detaildaten (genauere
// Legs/aktuelles Set als die Turnier-Listenansicht). "swapped" gibt an, ob
// bzzoiros player1/player2 in umgekehrter Reihenfolge zu unserem
// player1Name/player2Name stehen — wichtig, damit Sets/Legs nicht vertauscht
// übernommen werden. Wir setzen voraus, dass bzzoiro dieselbe Reihenfolge
// zwischen der Turnierliste und der Live-Liste verwendet (dasselbe zugrunde
// liegende Match-Objekt).
export function findBzzoiroMatch(data, player1Name, player2Name) {
  const bMatch = data.matches.find(
    (m) => m.player1 && m.player2 && pairMatches(player1Name, player2Name, m.player1.name, m.player2.name),
  );
  if (!bMatch) return null;

  const swapped = !namesMatch(player1Name, bMatch.player1.name);
  const liveMatch = data.liveMatches.find(
    (m) => m.player1 && m.player2 && pairMatches(player1Name, player2Name, m.player1.name, m.player2.name),
  );
  return { bMatch, liveMatch, swapped };
}

export function bzzoiroToUpdate(bMatch, liveMatch, swapped) {
  if (!["scheduled", "live", "finished"].includes(bMatch.status)) return null;

  let sets =
    bMatch.player1_sets != null && bMatch.player2_sets != null
      ? [bMatch.player1_sets, bMatch.player2_sets]
      : null;

  let legs = null;
  if (liveMatch && liveMatch.player1_legs != null && liveMatch.player2_legs != null) {
    legs = [liveMatch.player1_legs, liveMatch.player2_legs];
  } else if (Array.isArray(bMatch.sets_detail) && bMatch.sets_detail.length > 0) {
    const last = bMatch.sets_detail[bMatch.sets_detail.length - 1];
    legs = [last.player1_legs, last.player2_legs];
  }

  if (swapped) {
    if (sets) sets = [sets[1], sets[0]];
    if (legs) legs = [legs[1], legs[0]];
  }

  return { status: bMatch.status, sets, legs };
}
