# Wavy App

A "Tinder-for-thrift" Flutter application built for the Addis Ababa market, focusing on secondhand fashion discovery. 

## Features
- **Swipe Discovery:** Tinder-like swipe feed (Left: Pass, Right: Save)
- **Seller Flow:** Easily upload and sell items
- **I Want This:** Tap to reveal verified seller's phone and log interests
- **Bilingual Support:** Full English and Amharic interface
- **Offline Resiliency:** Event queue backed by Hive for networking gracefully under poor connections.

## Local Setup & Development

### 1. Mock Server Setup
The app currently relies on a `json-server` mock backend to simulate the API and database.

```bash
cd mock-server
npm install
npm start
```
This will start the mock server on `http://0.0.0.0:3000`.

### 2. Run the App
With the mock server running, launch the app on your preferred destination (Android Emulator, iOS Simulator, or Web):

```bash
flutter pub get
flutter run
```

### Environment Notes
- **Web Demo:** The Flutter web build is optimized to be a clickable prototype pointing at the same mock backend.
- **Android APK:** Can be generated via `flutter build apk --debug` for local testing on physical devices or emulators.
