// Legt einen geteilten Test-Account für jemanden an, der (noch) kein
// Google-Konto für die App nutzen soll. Bewusst simpel gehalten: eine feste
// E-Mail-Adresse ohne echtes Postfach dahinter (nie für Verifizierung/Reset
// genutzt) plus ein einfaches Passwort — passt zum niedrig priorisierten
// Security-Anspruch des Projekts, siehe CLAUDE.md.
//
// Zugangsdaten kommen bewusst NICHT als Literal in dieses (öffentliche)
// Repo, sondern über Umgebungsvariablen:
//   TEST_ACCOUNT_USERNAME=dartsprofi TEST_ACCOUNT_PASSWORD=... \
//     FIREBASE_SERVICE_ACCOUNT_JSON="$(cat serviceAccountKey.json)" node create-test-account.mjs
import { cert, initializeApp } from "firebase-admin/app";
import { getAuth } from "firebase-admin/auth";

const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT_JSON);
initializeApp({ credential: cert(serviceAccount) });

const USERNAME = process.env.TEST_ACCOUNT_USERNAME;
const PASSWORD = process.env.TEST_ACCOUNT_PASSWORD;
if (!USERNAME || !PASSWORD) {
  console.error("TEST_ACCOUNT_USERNAME und TEST_ACCOUNT_PASSWORD müssen gesetzt sein.");
  process.exit(1);
}
const EMAIL = `${USERNAME}@dartsapp.app`;
const DISPLAY_NAME = USERNAME;

async function main() {
  const auth = getAuth();
  try {
    const existing = await auth.getUserByEmail(EMAIL);
    await auth.updateUser(existing.uid, { password: PASSWORD, displayName: DISPLAY_NAME });
    console.log(`Account existierte bereits, Passwort aktualisiert: ${existing.uid}`);
  } catch (error) {
    if (error.code !== "auth/user-not-found") throw error;
    const created = await auth.createUser({ email: EMAIL, password: PASSWORD, displayName: DISPLAY_NAME });
    console.log(`Account neu angelegt: ${created.uid}`);
  }
}

main().catch((error) => {
  console.error("Fehlgeschlagen:", error);
  process.exitCode = 1;
});
