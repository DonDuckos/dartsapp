# AI-assisted development notes

This repository was built with substantial assistance from AI coding tools. This file is intentionally public and documents the expectations for any AI-assisted contribution.

## Repository role

`DonDuckos/dartsapp` is a public reference implementation originating from early OchePulse development. It is **not** the current production OchePulse repository and should not be treated as a source of production credentials, infrastructure state, or operational secrets.

## Principles for AI-assisted changes

1. **Prefer evidence over inference.** Use structured/provider data where available. Model-generated or web-derived information must not silently override deterministic data.
2. **Validate before persistence.** Dates, URLs, score fields, numeric ranges, identities, and expected response structure should be checked before writing data.
3. **Keep secrets out of source control.** Credentials belong in GitHub Secrets, environment variables, or ignored local files.
4. **Do not invent missing facts.** If reliable data cannot be established, keep the field empty or fall back to previously stored state.
5. **Keep changes reviewable.** Favor small, testable changes with explicit failure behavior.
6. **Preserve offline tests.** Repository abstractions and mock implementations should continue to support tests that do not require live services.
7. **Treat external content conservatively.** Do not copy third-party images, articles, or proprietary datasets into the repository unless their license clearly permits it.

## Useful areas in the codebase

- `lib/models/` — application data models
- `lib/repositories/` — provider-independent data contracts and Firestore/mock implementations
- `lib/providers/` — Riverpod state and application orchestration
- `lib/services/` — service clients such as optional live-score polling
- `scripts/match-agent/` — deterministic match lookup/matching with a bounded fallback path
- `scripts/news-agent/` — AI-assisted news discovery with date/source validation
- `scripts/profile-agent/` — profile enrichment and source/licensing checks
- `.github/workflows/` — manual public-reference automation workflows and CI

## Security note

The historical prototype includes an example of a low-value provider token being injected at build time for direct client polling. A mobile binary cannot protect such a secret. This remains visible as an architectural trade-off from the prototype and should **not** be copied into a production security design. Production secrets should stay behind a server-side boundary.

## Local checks

```bash
flutter pub get
flutter analyze
flutter test

cd scripts/match-agent
npm ci
node test-matching.mjs
```

If a change requires live Firebase or external-provider access, document that dependency clearly and keep credentials outside the repository.

## Maintainer workflow

The primary maintainer uses Codex and other AI coding tools for repository analysis, implementation, debugging, test design, and review. AI output is treated as proposed engineering work: it is inspected, tested where practical, and kept within explicit data and permission boundaries before being accepted.