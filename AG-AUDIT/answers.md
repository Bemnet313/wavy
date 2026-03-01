## 0) Quick repo metadata
1. Repo URL / branch you inspected: https://github.com/Bemnet313/wavy.git / main
2. Commit SHA you inspected: 593438e2505a9a92f6ca09f0d74aaa9fd8531712
3. Primary language / framework and SDK versions:
Flutter 3.41.2 • channel stable • https://github.com/flutter/flutter.git
Framework • revision 90673a4eef (10 days ago) • 2026-02-18 13:54:59 -0800
Engine • hash d96704abcce17ff165bbef9d77123407ef961017 (revision 6c0baaebf7) (10 days ago) • 2026-02-18 19:22:23.000Z
Tools • Dart 3.11.0 • DevTools 2.54.1

## 1) Can this build? (run locally)
**`flutter doctor -v`**
```
[✓] Flutter (Channel stable, 3.41.2, on Ubuntu 24.04.3 LTS 6.14.0-37-generic, locale en_US.UTF-8)
```
**`flutter pub get`**
```
Resolving dependencies... 
Got dependencies!
```
**`flutter analyze`**
```
warning • Unused import: '../../models/models.dart' • lib/src/ui/screens/seller_profile_screen.dart:7:8 • unused_import
[... 21 more issues found related to deprecated_member_use and prefer_interpolation_to_compose_strings]
22 issues found.
```
**`flutter test`**
```
Test directory "test" not found.
Exit code: 1
```

## 2) Where the UI screens live
- Splash / Welcome: `wavy/lib/src/ui/screens/splash_screen.dart`
- Language & Onboarding: `wavy/lib/src/ui/screens/language_screen.dart`
- Phone / OTP entry: `wavy/lib/src/ui/screens/phone_screen.dart`, `wavy/lib/src/ui/screens/otp_screen.dart`
- Feed / Swipe deck: `wavy/lib/src/ui/screens/feed_screen.dart`
- Item Detail (full/half screen): `wavy/lib/src/ui/screens/item_detail_screen.dart`
- Sell / Upload (camera + form): `wavy/lib/src/ui/screens/sell_screen.dart`
- Saved tab: `wavy/lib/src/ui/screens/saved_screen.dart`
- Seller Dashboard: `wavy/lib/src/ui/screens/seller_dashboard_screen.dart`
- Messages / Chat UI: `wavy/lib/src/ui/screens/messages_screen.dart`, `wavy/lib/src/ui/screens/chat_screen.dart`
- Profile / Settings: `wavy/lib/src/ui/screens/profile_screen.dart`, `wavy/lib/src/ui/screens/preferences_screen.dart`
- Filters modal: `wavy/lib/src/ui/screens/feed_screen.dart` (Inside `_FilterModal` class)
- Bottom nav: `wavy/lib/src/ui/screens/main_shell.dart`

## 3) Which features are **backend-wired** vs **local/mock**
- Authentication (OTP): LOCAL MOCK — `wavy/lib/src/services/api_service.dart` (accepts any code, `mockVerify`)
- User profile persistence: LOCAL MOCK / PARTIAL — `wavy/lib/src/local_storage/hive_service.dart` (locally caches to Hive)
- Items listing: LOCAL MOCK / PARTIAL — `wavy/lib/src/services/api_service.dart` calls a local json-server (`http://localhost:3000/items`) populated from `wavy/lib/src/data/dummy_data.dart`
- Item creation / image upload: LOCAL MOCK — `wavy/lib/src/ui/screens/sell_screen.dart` toggles local states to mimic photo upload but actual multipart logic is missing
- Saved items: LOCAL MOCK — `wavy/lib/src/providers/providers.dart` (`SavedNotifier` uses entirely in-memory array)
- Filters (server/client): LOCAL MOCK / CLIENT — `wavy/lib/src/ui/screens/feed_screen.dart` (`_FilterModal` prints an event but doesn't actually trigger filtering logic)
- Share links: LOCAL MOCK — `wavy/lib/src/ui/screens/item_detail_screen.dart` statically formats client-side share payload (`https://wavy.app/item/$itemId`)
- Messages / chat: LOCAL MOCK — `wavy/lib/src/ui/screens/chat_screen.dart` (`_messages` state list holds chat context per session)
- Phone reveal logic (I Want This): LOCAL MOCK — `wavy/lib/src/ui/screens/item_detail_screen.dart` (`_showSellerInfo` tracks access logic on tap)
- Notifications (push): MISSING
- Analytics events: LOCAL MOCK / PARTIAL — `wavy/lib/src/services/api_service.dart` has `logEvent()` pushing to mock server and optionally queueing via Hive `enqueueEvent`

## 4) External services & configuration
- Mock JSON server is targeted at `http://localhost:3000`.
- Firebase: An auto-generated project mapping file exists (`wavy/android/app/google-services.json`). However, there are no `firebase_core` or related flutter plugins installed via `pubspec.yaml` currently in use by the frontend.

## 5) Where runtime config / secrets live (paths only)
- `wavy/android/app/google-services.json`
- (There is no explicit `.env` or `key.properties` configuration visible.)

## 6) Image upload & storage
- LOCAL / PLACEHOLDER. 
- Currently loaded using `Image.asset()` referencing local dummy assets (e.g., `assets/images/dummy/item_1.jpg`) defined in `wavy/lib/src/data/dummy_data.dart`.
- `CachedNetworkImage` component is configured to render images starting with `http` if external URLs are returned, but NO underlying server infrastructure (e.g., Firebase Storage / AWS S3) is defined for uploading dynamically captured pictures (`_hasImage` toggle mimics successful capture in `wavy/lib/src/ui/screens/sell_screen.dart`). 
- No API path logic is being called for file uploads.

## 7) Chat / messaging persistence
- Is there a backend for chat? N (No).
- Mock logic: Inside `wavy/lib/src/ui/screens/chat_screen.dart` all message logs are injected and appended instantly into a widget state variable: `List<Map<String, dynamic>> _messages = []`. Because it relies on runtime widget state entirely, message history is cleared with app restarts. 

## 8) Saved / likes persistence
- Stored temporarily into application memory via StateNotifier. 
- The class `SavedNotifier` resides in `wavy/lib/src/providers/providers.dart`. No persistent cache logic (Hive/SQL/Firestore) backs this array — closing the app destroys the data.

## 9) Filters & search
- Filters are client-side only placeholders meant for mocking UI structure. 
- The functionality resides within the `_FilterModal` class inside `wavy/lib/src/ui/screens/feed_screen.dart`. When `APPLY` is touched, a snackbar notification executes, and the debug logger prints the state variables (`_selectedGender`, `_selectedSizes`, `_selectedCategory`) but no HTTP or dataset filter takes effect.

## 10) Share links
- It's hardcoded directly into the share bottom sheet in `wavy/lib/src/ui/screens/item_detail_screen.dart:496`: `final shareUrl = 'https://wavy.app/item/$itemId';`. Functionalities map directly back to items located in `wavy/lib/src/models/models.dart`.

## 11) Analytics & logging
- Custom "homemade" telemetry handles interactions inside the proxy HTTP client.
- Exists in: `wavy/lib/src/services/api_service.dart`. `logEvent()` transmits `WavyEvent` structures reflecting (`interest_event`, `call_event`, `swipe_event`, etc.) up to `/events` on the localhost REST proxy server. Unsent events fallback to local `HiveService.enqueueEvent`.
- No third-party analytics libraries (Firebase Analytics Core, Mixpanel, etc.) are currently defined.

## 12) Push notifications / FCM
- Not integrated. Only Google Play Service ID strings map exists via `wavy/android/app/google-services.json` setup, but `firebase_messaging` is completely absent from packages.

## 13) Unit/integration tests & test coverage
- None present.
- `flutter test` summary output returned: `Test directory "test" not found.`

## 14) CI/CD
- GitHub Actions pipeline is placed at: `wavy/.github/workflows/build.yml`.
- Role: Defines a minimal automated environment check executing on Ubuntu containing: `setup flutter`, `pub get`, `run analyzer`, `build web`, `build android apk` for pushes/pull requests originating around the `main` branch.

## 15) Build & release keys
- Android Key properties reference: Missing/Not configured (`android/key.properties` does not exist).
- iOS signing configs reference: No active release profiles or explicit distribution schemas identified in the codebase root mappings.

## 16) Security & secrets check
- `wavy/android/app/google-services.json` contains Google Cloud `project_info` configurations.
- Other than this explicit service map setup, no obvious hidden secrets, exposed PATs, Amazon AWS accesses, or leaked database credentials exist.

## 17) Runtime behaviors I need to test manually (list)
1. Verify phone numbers screen -> Input any characters into OTP text-boxes (auto-bypass triggered by `mockVerify`).
2. Swipe left to dismiss and right to "Heart/Save" entries on the Feed page.
3. Access the Favorites/Saved tab section to see saved item entries.
4. Try taking/uploading a proxy picture from Sell Page -> Verify simulated photo validation checks.
5. Search/Navigate toward a product detail section -> Copy canonical item share link mapping to clipboard.
6. Press the "GET THE FIT" intent CTA exposing a simulated seller's contact configuration.
7. Use in-app messaging context features — Attach specific item card parameters automatically onto empty chat session bodies.
8. Access User Configurations / Settings section to monitor/control localized language changes or dark/light modes.

## 18) Simple performance & scale notes
1. Images operate primarily as locally bundled files tracking `assets/images/dummy/`. As application items grow, static assets bloat payload distribution significantly.
2. The mock server dataset loader `_api.getFeed` grabs payload slices mapped directly down without optimized, robust lazy-loaded network limits, implying data congestion risks scaling into thousand-item collections.
3. The lack of offline relational database handlers (saving directly to memory limits instead of SQL arrays) creates RAM-heavy loads tracking unmanaged favorites/lists.

## 19) Short recommended backend stack
- **Supabase**
- **Reason**: Ideal migration vector converting local JSON REST objects safely over robust real-time SQL datasets, handles complex item sorting logic efficiently, and requires less boilerplate mapping edge storage structures alongside out-of-the-box user auth mechanisms.
- **Required Services**: Auth (SMS integration layer), PostgreSQL Database (User/Listings), Edge Storage Bucket (Imagery/Avatars), Realtime Web-Sockets (Messages/Chat).

## 20) Quick risks & blockers to production
1. **Empty Image Delivery**: Image uploads reflect toggled widgets on-screen and don't push encoded byte streams against a networked infrastructure blob handler.
2. **Fleeting Data Management**: Chats, message histories, and user ‘Saved’ list logs reset arbitrarily immediately off-app close functions as they solely depend upon RAM pointers.
3. **No Active Backend Context**: Almost the entirety of API routes run against a limited offline `json-server` port simulation, providing zero public/multiplayer functionality.
4. **Auth Is Ignored**: Bypassed entirely for fake validation paths. Phone verification must integrate SMS services (e.g. Twilio).
5. **No Alert / Push Notifications**: Essential networking feedback functionality necessary for marketplace communications is unconfigured. 
6. **Publishing Blockers**: The system lacks explicit keystores `key.properties`, iOS release configurations, and app bundle deployment capabilities needed before moving public versions beyond local beta execution phases.
