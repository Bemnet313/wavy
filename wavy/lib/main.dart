import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'src/router/app_router.dart';
import 'src/ui/theme/app_theme.dart';
import 'src/l10n/app_localizations.dart';
import 'src/local_storage/hive_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive for local storage
  await HiveService.init();
  
  // Load default locale
  await AppLocalizations.load('en');
  
  runApp(const ProviderScope(child: WavyApp()));
}

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
