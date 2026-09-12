# DartsApp — an OchePulse reference implementation

DartsApp is an open-source Flutter reference implementation that grew out of the early development of **OchePulse**, a darts-focused product exploring reliable live-data workflows, source-aware automation, and AI-assisted editorial tooling.

This repository is intentionally **not a mirror of the current production OchePulse codebase**. It preserves a real, runnable stage of the project and selected engineering patterns that are useful to study, test, and improve in public.

## What is in this repository

- a Flutter/Dart Android application using Riverpod
- Firebase/Firestore repository abstractions and authentication flows
- real-time match-state handling and live-score polling
- resilient player-name matching for external sports data
- GitHub Actions-based match, news, and player-profile agents
- AI-assisted news discovery with explicit date/source validation
- offline-friendly repository mocks and widget tests
- examples of keeping credentials in GitHub Secrets or local ignored files instead of source control

The scheduled agent workflows are currently **manual-only** in this public reference repository. They are kept as inspectable examples rather than unattended production jobs.

## Why this may be useful beyond darts

The sports domain is only the concrete test bed. Several patterns here generalize to other data-heavy or AI-assisted systems:

- **structured data before model inference** — prefer deterministic provider data where available and use model-based discovery only as a bounded fallback
- **validate model output before persistence** — dates, source URLs, numeric ranges, and expected structure are checked before data is accepted
- **separate retrieval from presentation** — app screens consume repository contracts rather than provider-specific response formats
- **degrade safely** — missing credentials or upstream failures fall back to stored data instead of breaking the UI
- **keep automation inspectable** — scheduled work is represented as ordinary scripts and CI workflows that can be reviewed and tested

These ideas later informed deeper OchePulse work around deterministic projections, provenance, bounded automation, and clearer trust boundaries.

## Architecture at a glance

```text
Flutter app
  ├─ Riverpod providers
  ├─ repository interfaces
  │    ├─ Firestore implementations
  │    └─ offline/mock implementations
  └─ optional live-score client

GitHub Actions / scripts
  ├─ match agent        -> structured sports data + bounded fallback
  ├─ news agent         -> AI-assisted discovery + validation
  └─ profile agent      -> enrichment with source/licensing checks

Firebase / Firestore
  └─ application state consumed by the Flutter client
```

## Trust and security boundaries

No production credentials are committed to this repository. Provider keys, Firebase service-account material, and local build-time values are expected through GitHub Secrets or ignored local configuration files.

The historical prototype experimented with a client-embedded low-value API key for direct live polling. That pattern is documented in code as a trade-off, **not as a recommended security design**. For production systems, secrets should remain behind a server-side boundary.

See [SECURITY.md](SECURITY.md) for the public-repository security policy.

## Build and test

### Prerequisites

- Flutter stable with Dart compatible with `sdk: ^3.13.0`
- Android tooling for device/emulator builds
- a Firebase project only if you want to run the Firestore-backed app locally

Install dependencies and run the checks:

```bash
flutter pub get
flutter analyze
flutter test
```

The repository's CI creates a non-secret Firebase placeholder file for static analysis and tests. For a real local Firebase-backed run, generate your own project configuration as described in [FIREBASE_SETUP.md](FIREBASE_SETUP.md).

The match-agent's deterministic matching tests can also be run independently:

```bash
cd scripts/match-agent
npm ci
node test-matching.mjs
```

## External services and content

This project demonstrates integrations with Firebase, OpenRouter, and a third-party darts data provider. Their services, APIs, data, trademarks, and terms are **not** covered by this repository's software license.

Likewise, player photos, news articles, tournament branding, and other third-party media remain subject to their original rights and licenses. The code license does not grant rights to external content.

## Project status

This is an **early public reference implementation**, not the current production OchePulse repository. It is useful as a concrete record of working architecture, failure modes, validation approaches, and AI-assisted engineering experiments.

The project is maintained by [DonDuckos](https://github.com/DonDuckos), who is responsible for the architecture and implementation and has roughly 15 years of full-stack development and UX experience. Codex and other AI coding tools are used as part of the engineering workflow for repository analysis, implementation, debugging, testing, and review; changes remain subject to human review and explicit validation.

## Contributing

Issues and focused pull requests are welcome. Please read [CONTRIBUTING.md](CONTRIBUTING.md) first.

For security-sensitive findings, follow [SECURITY.md](SECURITY.md) rather than opening a public issue.

## License

Source code in this repository is licensed under the [Apache License 2.0](LICENSE), unless a file states otherwise.

External APIs, data, media, names, logos, and trademarks are not relicensed by this repository.