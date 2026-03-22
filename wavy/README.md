# Wavy — Flutter App

> See the [root README](../README.md) for full project overview.

## Run Locally

```bash
flutter pub get
flutter run
```

## Build APK

```bash
flutter build apk --release
```

## Environment

Copy `.env.example` to `.env` and set your API base URL.

## Architecture

- **State Management:** Riverpod
- **Routing:** GoRouter
- **Local Storage:** Hive (offline event queue)
- **Localization:** Flutter l10n (English + Amharic)
