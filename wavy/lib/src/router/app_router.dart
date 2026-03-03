import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../ui/screens/splash_screen.dart';
import '../ui/screens/language_screen.dart';
import '../ui/screens/phone_screen.dart';
import '../ui/screens/otp_screen.dart';
import '../ui/screens/preferences_screen.dart';
import '../ui/screens/main_shell.dart';
import '../ui/screens/feed_screen.dart';
import '../ui/screens/item_detail_screen.dart';
import '../ui/screens/saved_screen.dart';
import '../ui/screens/sell_screen.dart';
import '../ui/screens/profile_screen.dart';

import '../ui/screens/messages_screen.dart';
import '../ui/screens/chat_screen.dart';
import '../ui/screens/seller_profile_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/splash',
  routes: [
    // ─── Onboarding ────────────────────────────────────
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/language',
      builder: (context, state) => const LanguageScreen(),
    ),
    GoRoute(
      path: '/phone',
      builder: (context, state) => const PhoneScreen(),
    ),
    GoRoute(
      path: '/otp',
      builder: (context, state) {
        final phone = state.extra as String? ?? '';
        return OtpScreen(phone: phone);
      },
    ),
    GoRoute(
      path: '/preferences',
      builder: (context, state) => const PreferencesScreen(),
    ),

    // ─── Main App Shell ────────────────────────────────
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) => MainShell(child: child),
      routes: [
        GoRoute(
          path: '/sell/new',
          builder: (context, state) => const SellScreen(),
        ),
        GoRoute(
          path: '/saved',
          builder: (context, state) => const SavedScreen(),
        ),
        GoRoute(
          path: '/feed',
          builder: (context, state) => const FeedScreen(),
        ),
        GoRoute(
          path: '/messages',
          builder: (context, state) => const MessagesScreen(),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileScreen(),
        ),
      ],
    ),

    // ─── Detail Routes ─────────────────────────────────
    GoRoute(
      path: '/item/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return ItemDetailScreen(itemId: id);
      },
    ),
    GoRoute(
      path: '/seller/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return SellerProfileScreen(sellerId: id);
      },
    ),
    GoRoute(
      path: '/chat/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        final attachItemId = state.uri.queryParameters['attachItemId'];
        return ChatScreen(chatId: id, attachItemId: attachItemId);
      },
    ),
  ],
);
