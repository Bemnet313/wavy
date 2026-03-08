
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'src/router/app_router.dart';
import 'src/ui/theme/app_theme.dart';
import 'src/l10n/app_localizations.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';
import 'src/local_storage/hive_service.dart';
import 'src/services/api_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  // Initialize App Check
  await FirebaseAppCheck.instance.activate(
    androidProvider: kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity,
    appleProvider: kDebugMode ? AppleProvider.debug : AppleProvider.deviceCheck,
    webProvider: ReCaptchaV3Provider('6LeIxAcTAAAAAJcZVRqyHh71UMIEGNQ_MXjiZKhI'),
  );

  // Initialize Crashlytics
  // Per cc-skill-security-review: "Error tracking with Sentry/Crashlytics"
  FlutterError.onError = (errorDetails) {
    FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
  };
  // Catch async errors that escape the Flutter framework
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };
  // Opt out of Crashlytics collection in debug mode
  await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(!kDebugMode);

  // Initialize Hive for local storage
  await HiveService.init();

  // Load default locale
  await AppLocalizations.load('en');

  // ─── FCM: Request notification permission & save token ──────────────────
  // Per firebase skill: request permissions once at startup, store token
  // so the server-side Cloud Function can reach the device.
  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );
  FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
    ApiService().saveFcmToken();
  });

  // Override ErrorWidget to prevent red flash in debug mode
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return const SizedBox.shrink();
  };

  runApp(const ProviderScope(child: WavyApp()));
}

final FirebaseAnalytics analytics = FirebaseAnalytics.instance;

class WavyApp extends ConsumerWidget {
  const WavyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Wavy',
      debugShowCheckedModeBanner: false,
      theme: WavyTheme.lightTheme,
      darkTheme: WavyTheme.darkTheme,
      themeMode: ThemeMode.dark,
      routerConfig: appRouter,
    );
  }
}
