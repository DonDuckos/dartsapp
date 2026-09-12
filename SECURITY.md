# Security policy

## Supported code

This repository is an early public reference implementation rather than the current production OchePulse codebase. Security reports are still welcome when they affect code or configuration present here.

## Reporting a vulnerability

Please **do not open a public GitHub issue** if your report includes:

- an exposed credential or token
- private user data
- a practical authentication/authorization bypass
- a provider key that appears to be active
- exploit instructions that would put a deployed instance at immediate risk

Instead, use GitHub's private vulnerability reporting feature for this repository if it is available. If private reporting is not available, contact the maintainer privately through the contact method listed on the GitHub profile without including secrets in a public message.

When reporting, include the affected file/commit, impact, reproduction steps where safe, and a suggested remediation if you have one.

## Credential policy

The repository is designed so privileged values come from GitHub Secrets, environment variables, or ignored local files. In particular, never commit:

- Firebase Admin service-account JSON
- API/provider tokens
- private keys
- `.env` files containing credentials
- `android/app/google-services.json`
- `lib/firebase_options.dart`
- `dart_defines.local.json`

If a real secret is ever committed, removing it in a later commit is not sufficient: the credential should be revoked/rotated and the Git history assessed.

## Prototype trade-off

The codebase contains a historical example of injecting a low-value provider key into a mobile build for direct live-score polling. Mobile binaries cannot reliably protect embedded secrets. This is retained as a documented prototype trade-off, not a recommended production pattern. Production secrets should remain behind a server-side boundary.

## External services

Deployments may depend on Firebase, OpenRouter, or third-party sports-data services. Their own security policies, terms, and credential-management requirements also apply.