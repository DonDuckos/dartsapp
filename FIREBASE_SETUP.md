# Firebase setup for local development

The app can use Firebase/Firestore for live local development, but **no project-specific Firebase configuration or service-account credentials are included in this repository**.

You do not need a real Firebase project to read the code or run the repository's offline-oriented tests in CI. A personal Firebase project is only required if you want to exercise the Firestore-backed application locally.

## 1. Create your own Firebase project

Create a Firebase project in the Firebase console and enable the services you need, such as:

- Firestore
- Firebase Authentication
- Google Sign-In, if you want to test that flow

Use a project you control. Do not request or reuse the maintainer's production credentials.

## 2. Generate FlutterFire configuration

Install the FlutterFire CLI and configure the local checkout:

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

This normally generates project-specific files such as:

- `lib/firebase_options.dart`
- `android/app/google-services.json`

Both paths are ignored by this repository and should remain uncommitted.

## 3. Protect privileged credentials

Firebase client configuration is not the same thing as a Firebase Admin service-account credential.

**Never commit:**

- service-account JSON
- private keys
- API tokens
- `.env` files containing credentials
- local `dart_defines.local.json`

The agent workflows expect privileged values through GitHub Secrets/environment variables, for example `FIREBASE_SERVICE_ACCOUNT_JSON` or provider API keys.

## 4. Firestore rules

Design Firestore rules according to your own deployment and threat model. A useful baseline is:

- public read access only for collections intentionally meant to be public
- client writes restricted to authenticated users and their own user-scoped data
- privileged ingestion performed server-side with narrowly scoped credentials

Do not copy permissive prototype rules into a production deployment without reviewing them.

## 5. Local checks

After configuring Firebase, run:

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

The public CI workflow uses a non-secret placeholder Firebase options file so that static analysis and tests do not depend on a real Firebase project.

## Security reporting

If you discover a committed credential or another security-sensitive issue, do not post the secret in a public issue. Follow [SECURITY.md](SECURITY.md).