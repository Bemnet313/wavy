# Contributing to Wavy

Thanks for your interest in contributing! Here's how to get started.

## Setup

1. **Fork & clone** the repo
2. Copy Firebase config files (ask @Bemnet313 for `google-services.json` and `firebase_options.dart`)
3. Copy `.env.example` → `.env` and fill in values
4. Run `flutter pub get` inside `wavy/`
5. Start the mock server: `cd wavy/mock-server && npm start`
6. Run: `flutter run`

## Branching

- Branch from `main`
- Use prefixes: `feat/`, `fix/`, `chore/`, `docs/`
- Example: `feat/seller-ratings`

## Commits

Follow [Conventional Commits](https://www.conventionalcommits.org/):

```
feat: add seller rating UI
fix: resolve swipe card crash on empty feed
chore: update dependencies
docs: add API contract for chat endpoint
```

## Pull Requests

1. Open a PR against `main`
2. Fill in the PR template (what, why, how to test)
3. Ensure CI passes (`flutter analyze` + tests)
4. Wait for review from `@Bemnet313`

## Code Standards

- **Language:** Dart / Flutter
- **State:** Riverpod
- **Routing:** GoRouter
- **Linting:** `flutter analyze` must pass with zero issues
- **No hardcoded secrets** — use `.env` or Firebase config

## What NOT to Commit

- `.env` files
- `google-services.json` / `GoogleService-Info.plist`
- `firebase_options.dart`
- Build artifacts, screenshots, temp scripts

## Questions?

Open an issue or reach out to @Bemnet313.
