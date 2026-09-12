# Contributing

Thanks for your interest in improving this public DartsApp/OchePulse reference implementation.

## Scope

Good contributions are focused, reviewable improvements to the public reference code: bug fixes, tests, documentation, safer provider abstractions, validation logic, and maintainability improvements.

Please do not assume this repository mirrors the current private OchePulse production codebase. Avoid contributions that depend on unpublished infrastructure or private credentials.

## Before opening a pull request

1. Fork or branch from `main`.
2. Keep the change narrowly scoped.
3. Do not commit API keys, Firebase credentials, service-account JSON, `.env` files, or local build secrets.
4. Preserve deterministic/provider-backed data paths when possible.
5. Do not invent or hard-code factual sports/news data when reliable sourcing is unavailable.
6. Add or update tests for behavior changes when practical.

Run the standard checks:

```bash
flutter pub get
flutter analyze
flutter test

cd scripts/match-agent
npm ci
node test-matching.mjs
```

## AI-assisted contributions

AI coding tools are welcome, but generated changes remain the contributor's responsibility. Please review the output, verify claims, run relevant checks, and disclose material AI assistance in the PR description when it helps reviewers understand how the change was produced.

See [CLAUDE.md](CLAUDE.md) for the repository's AI-assisted engineering principles.

## External data and media

Do not add third-party articles, images, datasets, branding assets, or scraped content unless the repository has clear rights to redistribute them. Linking to an external source is not the same as having permission to copy its content.

## Security findings

Do not open a public issue containing a credential or exploit detail. Follow [SECURITY.md](SECURITY.md).

## Pull requests

A useful PR description should explain:

- what changed
- why it changed
- what checks were run
- any external services or assumptions involved
- whether the change was materially AI-assisted

By contributing, you agree that your contribution is licensed under the Apache License 2.0 used by this repository.