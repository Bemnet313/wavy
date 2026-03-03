import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:firebase_messaging/firebase_messaging.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../local_storage/hive_service.dart';
import '../l10n/app_localizations.dart';

// ─── API Service Provider ──────────────────────────────────
final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});

// ─── Hive Service Provider ─────────────────────────────────
final hiveServiceProvider = Provider<HiveService>((ref) {
  return HiveService();
});

class AuthState {
  final String? phone;
  final String? verificationId;
  final bool isVerified;
  final bool isLoading;
  final String? error;
  final WavyUser? user;
  final fb.User? fbUser;

  const AuthState({
    this.phone,
    this.verificationId,
    this.isVerified = false,
    this.isLoading = false,
    this.error,
    this.user,
    this.fbUser,
  });

  AuthState copyWith({
    String? phone,
    String? verificationId,
    bool? isVerified,
    bool? isLoading,
    String? error,
    WavyUser? user,
    fb.User? fbUser,
  }) {
    return AuthState(
      phone: phone ?? this.phone,
      verificationId: verificationId ?? this.verificationId,
      isVerified: isVerified ?? this.isVerified,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      user: user ?? this.user,
      fbUser: fbUser ?? this.fbUser,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiService _api;
  final HiveService _hive;
  final Ref _ref;
  StreamSubscription? _authSubscription;

  AuthNotifier(this._api, this._hive, this._ref) : super(const AuthState()) {
    _initAuthListener();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  void _initAuthListener() {
    _authSubscription = _api.authStateChanges.listen((fbUser) async {
      if (fbUser != null) {
        state = state.copyWith(
          fbUser: fbUser,
          isVerified: true,
          isLoading: true,
        );
        
        // Load user from Firestore
        final user = await _api.getUser(fbUser.uid);
        state = state.copyWith(
          user: user,
          isLoading: false,
        );
        
        // Persist local UID just in case
        _hive.saveUserId(fbUser.uid);

        // Sync FCM token
        _syncFcmToken(fbUser.uid);

        // Load saved items
        _ref.read(savedProvider.notifier).loadSavedItems();
      } else {
        state = const AuthState();
      }
    });
  }

  Future<void> _syncFcmToken(String userId) async {
    try {
      final messaging = FirebaseMessaging.instance;
      // Request permission (standard practice)
      await messaging.requestPermission();
      final token = await messaging.getToken();
      if (token != null) {
        await _api.updateFcmToken(userId, token);
      }
    } catch (_) {
      // Silent fail in dev
    }
  }

  Future<void> sendOtp(String phone) async {
    state = state.copyWith(isLoading: true, phone: phone, error: null);
    try {
      await _api.verifyPhoneNumber(
        phoneNumber: phone,
        onCodeSent: (verId, resendToken) {
          state = state.copyWith(isLoading: false, verificationId: verId);
        },
        onVerificationFailed: (e) {
          state = state.copyWith(isLoading: false, error: e.message);
        },
        onVerificationCompleted: (credential) async {
          await _api.signInWithCredential(credential);
        },
        onCodeAutoRetrievalTimeout: (verId) {
          state = state.copyWith(verificationId: verId);
        },
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> verifyOtp(String otp) async {
    if (state.verificationId == null) {
      state = state.copyWith(error: 'Verification session expired');
      return false;
    }

    state = state.copyWith(isLoading: true, error: null);
    try {
      final credential = fb.PhoneAuthProvider.credential(
        verificationId: state.verificationId!,
        smsCode: otp,
      );
      await _api.signInWithCredential(credential);
      // initAuthListener handles the rest
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Invalid verification code');
      return false;
    }
  }

  void setUser(WavyUser user) {
    state = state.copyWith(user: user);
  }

  void setPhone(String phone) {
    state = state.copyWith(phone: phone);
  }

  void logout() async {
    await _api.signOut();
    _hive.clearAuth();
    state = const AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    ref.watch(apiServiceProvider),
    ref.watch(hiveServiceProvider),
    ref,
  );
});

// ─── Feed Provider ─────────────────────────────────────────
class FeedState {
  final List<WavyItem> items;
  final bool isLoading;
  final String? error;
  final int currentPage;
  final String? gender;
  final String? category;
  final List<String>? sizes;

  const FeedState({
    this.items = const [],
    this.isLoading = false,
    this.error,
    this.currentPage = 1,
    this.gender,
    this.category,
    this.sizes,
  });

  FeedState copyWith({
    List<WavyItem>? items,
    bool? isLoading,
    String? error,
    int? currentPage,
    String? gender,
    String? category,
    List<String>? sizes,
  }) {
    return FeedState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      currentPage: currentPage ?? this.currentPage,
      gender: gender ?? this.gender,
      category: category ?? this.category,
      sizes: sizes ?? this.sizes,
    );
  }
}

class FeedNotifier extends StateNotifier<FeedState> {
  final ApiService _api;

  FeedNotifier(this._api) : super(const FeedState());

  Future<void> loadFeed({String? gender, String? category, List<String>? sizes}) async {
    if (state.isLoading) return;
    state = state.copyWith(
      isLoading: true, 
      error: null, 
      gender: gender, 
      category: category, 
      sizes: sizes
    );
    try {
      final items = await _api.getFeed(
        limit: 20,
        gender: state.gender,
        category: state.category,
        sizes: state.sizes,
      );
      state = state.copyWith(items: items, isLoading: false, currentPage: 1);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true);
    try {
      final nextPage = state.currentPage + 1;
      final startAfterId = state.items.isNotEmpty ? state.items.last.id : null;
      final items = await _api.getFeed(
        limit: 20, 
        startAfterId: startAfterId,
        gender: state.gender,
        category: state.category,
        sizes: state.sizes,
      );
      state = state.copyWith(
        items: [...state.items, ...items],
        isLoading: false,
        currentPage: nextPage,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void removeItem(String itemId) {
    state = state.copyWith(
      items: state.items.where((i) => i.id != itemId).toList(),
    );
  }

  Future<void> recordSwipe(String itemId, String userId, String action) async {
    try {
      await _api.recordSwipe(itemId, userId, action);
    } catch (_) {
      // Queue offline
    }
  }
}

final feedProvider = StateNotifierProvider<FeedNotifier, FeedState>((ref) {
  return FeedNotifier(ref.watch(apiServiceProvider));
});

// ─── Saved Items Provider ──────────────────────────────────
class SavedNotifier extends StateNotifier<List<WavyItem>> {
  final ApiService _api;
  final Ref _ref;

  SavedNotifier(this._api, this._ref) : super([]);

  Future<void> addItem(WavyItem item) async {
    final userId = _ref.read(authProvider).fbUser?.uid;
    if (userId == null) return;

    if (!state.any((i) => i.id == item.id)) {
      try {
        await _api.saveItem(userId, item.id);
        state = [...state, item];
      } catch (e) {
        rethrow;
      }
    }
  }

  Future<void> removeItem(String itemId) async {
    final userId = _ref.read(authProvider).fbUser?.uid;
    if (userId == null) return;

    state = state.where((i) => i.id != itemId).toList();
    await _api.unsaveItem(userId, itemId);
  }

  bool isSaved(String itemId) {
    return state.any((i) => i.id == itemId);
  }

  Future<void> loadSavedItems() async {
    final userId = _ref.read(authProvider).fbUser?.uid;
    if (userId == null) return;

    try {
      final items = await _api.getSavedItems(userId);
      state = items;
    } catch (_) {}
  }
}

final savedProvider =
    StateNotifierProvider<SavedNotifier, List<WavyItem>>((ref) {
  return SavedNotifier(ref.watch(apiServiceProvider), ref);
});

// ─── Seller Provider ───────────────────────────────────────
class SellerState {
  final Seller? seller;
  final List<WavyItem> listings;
  final bool isLoading;

  const SellerState({
    this.seller,
    this.listings = const [],
    this.isLoading = false,
  });

  SellerState copyWith({
    Seller? seller,
    List<WavyItem>? listings,
    bool? isLoading,
  }) {
    return SellerState(
      seller: seller ?? this.seller,
      listings: listings ?? this.listings,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class SellerNotifier extends StateNotifier<SellerState> {
  final ApiService _api;

  SellerNotifier(this._api) : super(const SellerState());

  Future<void> loadDashboard(String sellerId) async {
    state = state.copyWith(isLoading: true);
    try {
      final seller = await _api.getSeller(sellerId);
      final listings = await _api.getSellerListings(sellerId);
      state = state.copyWith(
        seller: seller,
        listings: listings,
        isLoading: false,
      );
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> markSold(String itemId) async {
    try {
      await _api.markSold(itemId);
      state = state.copyWith(
        listings: state.listings
            .map((i) => i.id == itemId ? i.copyWith(status: 'sold') : i)
            .toList(),
      );
    } catch (_) {}
  }
}

final sellerProvider =
    StateNotifierProvider<SellerNotifier, SellerState>((ref) {
  return SellerNotifier(ref.watch(apiServiceProvider));
});

// ─── Preferences Provider ──────────────────────────────────
final preferencesProvider =
    StateNotifierProvider<PreferencesNotifier, UserPreferences>((ref) {
  return PreferencesNotifier(ref.watch(hiveServiceProvider));
});

class PreferencesNotifier extends StateNotifier<UserPreferences> {
  final HiveService _hive;
  PreferencesNotifier(this._hive) : super(UserPreferences(hasSeenTutorial: _hive.getHasSeenTutorial()));

  void markTutorialSeen() {
    _hive.setHasSeenTutorial(true);
    state = UserPreferences(
      gender: state.gender,
      sizes: state.sizes,
      styles: state.styles,
      age: state.age,
      hasSeenTutorial: true,
    );
  }

  void setGender(String gender) {
    state = UserPreferences(
        gender: gender, sizes: state.sizes, styles: state.styles, age: state.age, hasSeenTutorial: state.hasSeenTutorial);
  }

  void setAge(int age) {
    state = UserPreferences(
        gender: state.gender, sizes: state.sizes, styles: state.styles, age: age, hasSeenTutorial: state.hasSeenTutorial);
  }

  void toggleSize(String size) {
    final sizes = List<String>.from(state.sizes);
    if (sizes.contains(size)) {
      sizes.remove(size);
    } else {
      sizes.add(size);
    }
    state =
        UserPreferences(gender: state.gender, sizes: sizes, styles: state.styles, age: state.age, hasSeenTutorial: state.hasSeenTutorial);
  }

  void toggleStyle(String style) {
    final styles = List<String>.from(state.styles);
    if (styles.contains(style)) {
      styles.remove(style);
    } else {
      styles.add(style);
    }
    state =
        UserPreferences(gender: state.gender, sizes: state.sizes, styles: styles, age: state.age, hasSeenTutorial: state.hasSeenTutorial);
  }
}

// ─── Chat Providers ───────────────────────────────────────
final conversationsProvider = StreamProvider<List<ChatConversation>>((ref) {
  final userId = ref.watch(authProvider).fbUser?.uid;
  if (userId == null) return Stream.value([]);
  return ref.watch(apiServiceProvider).getConversations(userId);
});

final messagesProvider = StreamProvider.family<List<ChatMessage>, String>((ref, conversationId) {
  return ref.watch(apiServiceProvider).getMessages(conversationId);
});

final sellerListingsProvider = FutureProvider.family<List<WavyItem>, String>((ref, sellerId) {
  return ref.watch(apiServiceProvider).getSellerListings(sellerId);
});

// ─── Locale Provider ───────────────────────────────────────
final localeProvider = StateNotifierProvider<LocaleNotifier, String>((ref) {
  return LocaleNotifier();
});

class LocaleNotifier extends StateNotifier<String> {
  LocaleNotifier() : super('en');

  Future<void> setLocale(String locale) async {
    await AppLocalizations.load(locale);
    state = locale;
  }
}

// ─── Onboarding complete provider ──────────────────────────
final onboardingCompleteProvider = StateProvider<bool>((ref) => false);
