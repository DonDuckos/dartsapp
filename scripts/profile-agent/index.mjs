// Ergänzt, was die Rangliste/Event-Ansicht "lebendiger" macht: kurze
// Spieler-Vitas, ein aktuelles Zitat, ein Foto sowie eine kurze journalistische
// Einordnung des Austragungsorts pro Event. Läuft NICHT im engen Cron-Takt wie
// News-/Match-Agent, sondern manuell oder wöchentlich (siehe
// .github/workflows/profile-agent.yml) — Vitas ändern sich kaum, und jeder
// Lauf ist idempotent (überspringt bereits befüllte Felder), kostet also nur
// beim ersten Mal bzw. für neue Spieler/Events wirklich etwas.
//
// Fotos kommen AUSSCHLIESSLICH von Wikimedia Commons mit strukturiert
// geprüfter Lizenz (kein KI-"das sieht frei aus"-Urteil) — siehe
// isAcceptableLicense(). Bio/Zitat werden ausdrücklich mit der Anweisung
// recherchiert, im Zweifel null statt zu raten, um keine falschen Fakten
// über echte Personen zu erfinden.

import { cert, initializeApp } from "firebase-admin/app";
import { getFirestore } from "firebase-admin/firestore";

const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT_JSON);
initializeApp({ credential: cert(serviceAccount) });
const db = getFirestore();

const OPENROUTER_MODEL = process.env.OPENROUTER_MODEL || "moonshotai/kimi-k2-0905";

async function callOpenRouter(prompt) {
  const response = await fetch("https://openrouter.ai/api/v1/chat/completions", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${process.env.OPENROUTER_API_KEY}`,
      "Content-Type": "application/json",
      "HTTP-Referer": "https://github.com/DonDuckos/dartsapp",
      "X-Title": "DartsApp Profile Agent",
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

function parseJsonObject(text) {
  const attempts = [text.trim()];
  const fenceMatch = text.match(/```(?:json)?\s*([\s\S]*?)```/i);
  if (fenceMatch) attempts.push(fenceMatch[1].trim());
  const start = text.indexOf("{");
  const end = text.lastIndexOf("}");
  if (start !== -1 && end !== -1 && end > start) attempts.push(text.slice(start, end + 1));

  for (const attempt of attempts) {
    try {
      const parsed = JSON.parse(attempt);
      if (parsed && typeof parsed === "object") return parsed;
    } catch {
      // nächsten Versuch probieren
    }
  }
  console.error("Konnte Antwort nicht als JSON-Objekt parsen:", text);
  return null;
}

const ACCEPTABLE_LICENSE_PREFIXES = ["cc0", "cc by", "public domain", "pd"];

function isAcceptableLicense(shortName) {
  if (!shortName) return false;
  const normalized = shortName.toLowerCase();
  return ACCEPTABLE_LICENSE_PREFIXES.some((prefix) => normalized.startsWith(prefix));
}

function stripHtml(value) {
  return (value ?? "").replace(/<[^>]*>/g, "").trim();
}

async function findWikimediaPhoto(query) {
  const url =
    "https://commons.wikimedia.org/w/api.php?action=query&generator=search" +
    `&gsrsearch=${encodeURIComponent(query)}&gsrnamespace=6&gsrlimit=5` +
    "&prop=imageinfo&iiprop=url|extmetadata&iiurlwidth=500&format=json";

  const response = await fetch(url, {
    headers: { "User-Agent": "DartsApp/1.0 (privates Hobby-Projekt, kein kommerzieller Einsatz)" },
  });
  if (!response.ok) return null;

  const data = await response.json();
  const pages = Object.values(data.query?.pages ?? {});
  for (const page of pages) {
    const info = page.imageinfo?.[0];
    if (!info) continue;
    const license = info.extmetadata?.LicenseShortName?.value;
    if (!isAcceptableLicense(license)) continue;

    const artist = stripHtml(info.extmetadata?.Artist?.value) || stripHtml(info.extmetadata?.Credit?.value) || "Unbekannt";
    return {
      url: info.thumburl || info.url,
      attribution: `${artist} · ${license} · Wikimedia Commons`,
    };
  }
  return null;
}

async function fetchPlayerProfile(playerName) {
  const prompt =
    `Suche kurze, verifizierbare Fakten zum Profi-Dartspieler "${playerName}": Nationalität, ` +
    "Heimatstadt (falls bekannt), Jahr des Profi-Debüts, Spitzname (falls vorhanden). Suche außerdem " +
    "ein aktuelles, wörtliches Zitat von ihm mit Quellenangabe (Publikation). Antworte NUR mit einem " +
    'JSON-Objekt: {"bio": "2-3 Sätze Deutsch, NUR gesicherte Fakten" oder null, "quote": "wörtliches ' +
    'Zitat" oder null, "quoteSource": "Publikation/Quelle" oder null}. Bei Unsicherheit lieber null ' +
    "statt zu raten oder etwas zu erfinden.";

  const text = await callOpenRouter(prompt);
  return parseJsonObject(text);
}

function slugifyName(name) {
  return name
    .toLowerCase()
    .replace(/[^a-z0-9\s-]/g, "")
    .trim()
    .replace(/\s+/g, "-");
}

// darts-nerd.com hat pro Spieler eine strukturierte Statistikseite mit
// eingebettetem JSON-LD (FAQPage). Liefert average3Dart/checkoutPercentage/
// count180s zuverlässig und kostenlos, KEIN Websuche-Raten nötig — daher
// erste Anlaufstelle, bevor überhaupt ein OpenRouter-Call für Stats gemacht
// wird. "highFinish" liefert die Seite NICHT mit (siehe unten), das bleibt
// bei der Websuche.
//
// Wichtig: Die Seite hat selbst einen Bug/Platzhalter — "höchster Checkout"
// stand beim Testen für JEDEN geprüften Spieler identisch auf 170, dem
// theoretischen Maximum. Dieses Feld wird deshalb bewusst NICHT übernommen.
async function fetchDartsNerdStats(playerName) {
  const slug = slugifyName(playerName);
  const response = await fetch(`https://www.darts-nerd.com/en/players/${slug}/stats`, {
    headers: { "User-Agent": "DartsApp/1.0 (privates Hobby-Projekt, kein kommerzieller Einsatz)" },
  });
  if (!response.ok) return null;

  const html = await response.text();

  const avgMatch = html.match(/averages ([\d.]+) per leg/);
  const checkoutMatch = html.match(/est de ([\d.]+)% sur les 12 derniers mois/);
  const count180sMatch = html.match(/has hit ([\d,]+) 180s over the last 12 months/);

  const result = {};
  if (avgMatch) result.average3Dart = Number.parseFloat(avgMatch[1]);
  if (checkoutMatch) result.checkoutPercentage = Number.parseFloat(checkoutMatch[1]);
  if (count180sMatch) result.count180s = Number.parseInt(count180sMatch[1].replace(/,/g, ""), 10);

  return Object.keys(result).length > 0 ? result : null;
}

async function fetchPlayerStats(playerName) {
  const prompt =
    `Suche die aktuellen PDC-Saison-2026-Statistiken des Profi-Dartspielers "${playerName}": ` +
    "3-Dart-Average (Saison), Checkout-Quote in Prozent, Anzahl 180er (Saison), höchstes Finish " +
    "(Checkout) der Saison. Nutze verlässliche Quellen wie offizielle PDC-Statistiken, " +
    'thestatsdontlie.com oder dartsworld.com. Antworte NUR mit JSON: {"average3Dart": Zahl oder null, ' +
    '"checkoutPercentage": Zahl oder null, "count180s": Zahl oder null, "highFinish": Zahl oder null, ' +
    '"source": "kurze Quellenangabe"}. Bei Unsicherheit lieber null statt zu raten — diese Zahlen sind ' +
    "Recherche-Bestwerte, keine garantiert exakten Werte, da Darts-Statistiken nicht einheitlich " +
    "zentral erfasst werden. WICHTIG zu highFinish: 170 ist das theoretisch höchstmögliche Finish " +
    "(T20-T20-Bull) — nenne 170 NUR, wenn du eine konkrete Quelle für genau DIESEN Spieler mit genau " +
    "diesem Wert gefunden hast, niemals als Schätzung oder Platzhalter. Im Zweifel null.";

  const text = await callOpenRouter(prompt);
  return parseJsonObject(text);
}

// Grobe Plausibilitätsgrenzen für Saison-Statistiken im Profi-Darts — fängt
// Modell-Hallizinationen ab (z.B. wurde beim ersten Lauf "highFinish: 170",
// das theoretische Maximum, auffällig oft ohne echte Quelle als Platzhalter
// genannt, und einzelne Checkout-Quoten waren für einen Saisondurchschnitt
// unrealistisch, siehe git-Historie).
const STATS_BOUNDS = {
  average3Dart: [70, 112],
  checkoutPercentage: [20, 55],
  count180s: [0, 1500],
  highFinish: [100, 170],
};

function isPlausibleStat(field, value) {
  const [min, max] = STATS_BOUNDS[field];
  return value >= min && value <= max;
}

async function fetchEventPreview(event) {
  const locationHint = event.venue ? ` in ${event.venue}` : "";
  const prompt =
    `Schreibe einen kurzen journalistischen Absatz (3-4 Sätze, Deutsch) über Austragungsort und ` +
    `Rahmenbedingungen des Darts-Turniers "${event.name}"${locationHint} — z.B. Atmosphäre der Location, ` +
    "Besonderheiten, TV-Übertragung, Bedeutung im Turnierkalender. Nur recherchierte, gesicherte " +
    'Informationen, keine erfundenen Details. Antworte NUR mit einem JSON-Objekt: {"preview": "..." ' +
    "oder null, falls nichts Verlässliches gefunden wird}.";

  const text = await callOpenRouter(prompt);
  return parseJsonObject(text);
}

async function processPlayers() {
  const snapshot = await db.collection("players").get();
  let updated = 0;

  for (const doc of snapshot.docs) {
    const player = doc.data();
    const needsProfile = !player.bio && !player.quote;
    const needsPhoto = !player.photoUrl;
    const stats = player.stats ?? {};
    const needsStats =
      !stats.average3Dart || !stats.checkoutPercentage || !stats.count180s || !stats.highFinish;
    if (!needsProfile && !needsPhoto && !needsStats) continue;

    const updates = {};

    if (needsProfile) {
      const profile = await fetchPlayerProfile(player.name);
      if (profile?.bio) updates.bio = profile.bio;
      if (profile?.quote) {
        updates.quote = profile.quote;
        updates.quoteSource = profile.quoteSource ?? null;
      }
    }

    if (needsPhoto) {
      const photo = await findWikimediaPhoto(`${player.name} darts`);
      if (photo) {
        updates.photoUrl = photo.url;
        updates.photoAttribution = photo.attribution;
      }
    }

    if (needsStats) {
      const applyStats = (result, sourceLabel) => {
        if (!result) return;
        for (const field of ["average3Dart", "checkoutPercentage", "count180s", "highFinish"]) {
          const value = result[field];
          if (typeof value !== "number" || stats[field] || updates[`stats.${field}`]) continue;
          if (!isPlausibleStat(field, value)) {
            console.warn(`    ${player.name}: ${field}=${value} (${sourceLabel}) außerhalb Plausibilitätsgrenze — verworfen.`);
            continue;
          }
          updates[`stats.${field}`] = value;
        }
      };

      const dartsNerdResult = await fetchDartsNerdStats(player.name);
      applyStats(dartsNerdResult, "darts-nerd.com");
      if (dartsNerdResult) console.log(`    (darts-nerd.com hatte Daten für ${player.name})`);

      // highFinish liefert darts-nerd.com nicht mit (siehe Kommentar oben),
      // und für Spieler ohne darts-nerd-Profil (z.B. Oceanic-Qualifikanten)
      // fehlt danach meist noch mehr — Websuche füllt nur die echten Lücken.
      const stillMissing = ["average3Dart", "checkoutPercentage", "count180s", "highFinish"].some(
        (field) => !stats[field] && !updates[`stats.${field}`],
      );
      if (stillMissing) {
        const result = await fetchPlayerStats(player.name);
        applyStats(result, "Websuche");
        if (result?.source) console.log(`    (Websuche-Quelle für ${player.name}: ${result.source})`);
      }
    }

    if (Object.keys(updates).length > 0) {
      await doc.ref.update(updates);
      updated += 1;
      console.log(`  ${player.name}: ${Object.keys(updates).join(", ")} ergänzt`);
    }
  }

  console.log(`Spieler-Profile: ${updated} von ${snapshot.size} aktualisiert.`);
}

async function processEvents() {
  const snapshot = await db.collection("events").where("status", "in", ["upcoming", "live"]).get();
  let updated = 0;

  for (const doc of snapshot.docs) {
    const event = doc.data();
    if (event.preview) continue;

    const result = await fetchEventPreview(event);
    if (result?.preview) {
      await doc.ref.update({ preview: result.preview });
      updated += 1;
      console.log(`  Event "${event.name}": Preview ergänzt`);
    }
  }

  console.log(`Event-Previews: ${updated} von ${snapshot.size} aktualisiert.`);
}

async function main() {
  await processPlayers();
  await processEvents();
}

main().catch((error) => {
  console.error("Profile-Agent fehlgeschlagen:", error);
  process.exitCode = 1;
});
