# 🌊 Wavy

**Tinder-for-thrift** — Swipe, discover, and buy secondhand fashion in Addis Ababa.

A Flutter mobile app that connects secondhand fashion buyers with sellers through a swipe-based discovery feed, built for the Ethiopian market.

---

## ✨ Features

- **Swipe Discovery** — Tinder-like card feed (right = save, left = pass)
- **Seller Dashboard** — Upload, manage, and track your listings
- **"I Want This"** — Tap to reveal verified seller contact & log interest
- **Bilingual UI** — Full English 🇬🇧 and Amharic 🇪🇹 support
- **Offline-First** — Hive-backed event queue for graceful offline operation
- **Real-time Chat** — In-app messaging between buyers and sellers

---

## 🛠 Tech Stack

| Layer | Technology |
|-------|-----------|
| **Frontend** | Flutter 3 · Dart · Riverpod |
| **Backend** | Firebase (Auth, Firestore, Storage, Functions, Crashlytics) |
| **Local Storage** | Hive |
| **Routing** | GoRouter |
| **CI/CD** | GitHub Actions |

---

## 🚀 Quick Start

### 1. Clone & install

```bash
git clone https://github.com/Bemnet313/wavy.git
cd wavy/wavy
flutter pub get
```

### 2. Mock server (optional, for local dev)

```bash
cd wavy/mock-server
npm install && npm start
# Runs on http://0.0.0.0:3000
```

### 3. Run the app

```bash
cd wavy/wavy
flutter run
```

> **Note:** You'll need a `wavy/.env` file with your API base URL. See `wavy/.env.example`.

---

## 📁 Project Structure

```
wavy/
├── .github/workflows/   # CI: Flutter analysis + Android build
├── docs/                # API contract & data models
├── functions/           # Firebase Cloud Functions
├── firebase.json        # Firebase project config
│
└── wavy/                # Flutter app
    ├── lib/
    │   ├── main.dart
    │   └── src/
    │       ├── data/        # Data layer
    │       ├── models/      # Domain models
    │       ├── providers/   # Riverpod state management
    │       ├── services/    # API & Firebase services
    │       ├── router/      # GoRouter config
    │       ├── l10n/        # Localization (EN/AM)
    │       └── ui/          # Screens & widgets
    ├── assets/              # Images, l10n files
    ├── android/             # Android platform
    ├── ios/                 # iOS platform
    └── test/                # Unit & widget tests
```

---

## 🔥 Firebase Setup

This project uses Firebase. The config points to:
- **Firestore rules** → `wavy/firestore.rules`
- **Storage rules** → `wavy/storage.rules`
- **Cloud Functions** → `functions/`

Deploy with:
```bash
firebase deploy
```

---

## 📄 License

MIT