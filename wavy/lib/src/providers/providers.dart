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
        final isPhoneVerified = fbUser.phoneNumber != null || 
                               fbUser.providerData.any((p) => p.providerId == 'phone');
        state = state.copyWith(
          fbUser: fbUser,
          isVerified: isPhoneVerified,
          isLoading: true,
        );
        
        // Load user from Firestore with timeout
        try {
          final user = await _api.getUser(fbUser.uid).timeout(
            const Duration(seconds: 10),
            onTimeout: () => null,
          );
          state = state.copyWith(
            user: user,
            isLoading: false,
          );

          // Sync local onboarding state for returning users
          if (user != null) {
            _ref.read(onboardingCompleteProvider.notifier).complete();
          }
        } catch (e) {
          state = state.copyWith(
            isLoading: false,
            error: 'Failed to load profile: $e',
          );
        }
        
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

  Future<void> loginWithEmail(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _api.checkAuthRateLimit();
      await _api.signInWithEmail(email, password);
    } catch (e) {
      String message = e.toString().replaceFirst(RegExp(r'\[.*\] '), '');
      if (message.contains('TOO_MANY_ATTEMPTS')) {
        message = 'Too many attempts. Please try again in 1 minute.';
      }
      state = state.copyWith(isLoading: false, error: message);
    }
  }

  Future<void> registerWithEmail(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _api.checkAuthRateLimit();
      await _api.signUpWithEmail(email, password);
    } catch (e) {
      String message = e.toString().replaceFirst(RegExp(r'\[.*\] '), '');
      if (message.contains('TOO_MANY_ATTEMPTS')) {
        message = 'Too many attempts. Please try again in 1 minute.';
      }
      state = state.copyWith(isLoading: false, error: message);
    }
  }

  Future<void> loginWithGoogle() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _api.checkAuthRateLimit();
      await _api.signInWithGoogle();
    } catch (e) {
      String message = e.toString();
      if (message.contains('TOO_MANY_ATTEMPTS')) {
        message = 'Too many attempts. Please try again in 1 minute.';
      }
      state = state.copyWith(isLoading: false, error: message);
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
          // Auto-verification (Android only): link to existing account if signed in.
          // We never sign in via phone — OTP is for linking only.
          final fbUser = _ref.read(authProvider).fbUser;
          if (fbUser != null) {
            try {
              await fbUser.linkWithCredential(credential);
            } catch (_) {
              // Already linked or other non-critical error — ignore.
            }
          }
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
      
      if (state.fbUser != null) {
        // Link phone credential to the existing signed-in account.
        // This is the ONLY valid path — OTP is for verification, not sign-in.
        await state.fbUser!.linkWithCredential(credential);
      } else {
        // Guard: user must be signed in before verifying phone.
        // Direct phone-only sign-in is not permitted by product rules.
        state = state.copyWith(
          isLoading: false,
          error: 'Please sign in with email or Google first.',
        );
        return false;
      }
      
      return true;
    } catch (e) {
      String message = 'Invalid verification code';
      if (e.toString().contains('credential-already-in-use')) {
        message = 'This phone number is already linked to another account';
      }
      state = state.copyWith(isLoading: false, error: message);
      return false;
    }
  }

  void setUser(WavyUser user) {
    state = state.copyWith(user: user);
  }

  void setPhone(String phone) {
    state = state.copyWith(phone: phone);
  }

  Future<void> completeOnboarding({
    required String fullName,
    required String role,
    required String gender,
    required int age,
    required String language,
  }) async {
    final fbUser = state.fbUser;
    if (fbUser == null) return;

    state = state.copyWith(isLoading: true);
    try {
      // 1. Update Firebase display name
      await fbUser.updateDisplayName(fullName);

      // 2. Build WavyUser object
      final newUser = WavyUser(
        id: fbUser.uid,
        phone: fbUser.phoneNumber ?? state.phone ?? '',
        name: fullName,
        language: language,
        preferences: UserPreferences(
          gender: gender,
          age: age,
          role: role,
          hasSeenTutorial: false,
        ),
      );

      // 3. Persist to Firestore
      await _api.createUser(newUser);

      // 4. Update state
      state = state.copyWith(user: newUser, isLoading: false);
      
      // 5. Trigger navigation-ready state
      _ref.read(onboardingCompleteProvider.notifier).complete();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  void logout() async {
    state = state.copyWith(isLoading: true);
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
  final int? minPrice;
  final int? maxPrice;
  final int currentIndex;
  final bool canUndo;

  const FeedState({
    this.items = const [],
    this.isLoading = false,
    this.error,
    this.currentPage = 1,
    this.gender,
    this.category,
    this.sizes,
    this.minPrice,
    this.maxPrice,
    this.currentIndex = 0,
    this.canUndo = false,
  });

  FeedState copyWith({
    List<WavyItem>? items,
    bool? isLoading,
    String? error,
    int? currentPage,
    String? gender,
    String? category,
    List<String>? sizes,
    int? minPrice,
    int? maxPrice,
    int? currentIndex,
    bool? canUndo,
  }) {
    return FeedState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      currentPage: currentPage ?? this.currentPage,
      gender: gender ?? this.gender,
      category: category ?? this.category,
      sizes: sizes ?? this.sizes,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      currentIndex: currentIndex ?? this.currentIndex,
      canUndo: canUndo ?? this.canUndo,
    );
  }
}

class FeedNotifier extends StateNotifier<FeedState> {
  final ApiService _api;

  FeedNotifier(this._api) : super(const FeedState());

  Future<void> loadFeed({
    String? gender,
    String? category,
    List<String>? sizes,
    int? minPrice,
    int? maxPrice,
    bool clearFilters = false,
  }) async {
    if (state.isLoading) return;
    state = state.copyWith(
      isLoading: true,
      error: null,
      gender: clearFilters ? null : (gender ?? state.gender),
      category: clearFilters ? null : (category ?? state.category),
      sizes: clearFilters ? null : (sizes ?? state.sizes),
      minPrice: clearFilters ? null : (minPrice ?? state.minPrice),
      maxPrice: clearFilters ? null : (maxPrice ?? state.maxPrice),
      currentIndex: 0,
      canUndo: false,
    );
    try {
      final items = await _api.getFeed(
        limit: 20,
        gender: clearFilters ? null : state.gender,
        category: clearFilters ? null : state.category,
        sizes: clearFilters ? null : state.sizes,
        minPrice: clearFilters ? null : state.minPrice,
        maxPrice: clearFilters ? null : state.maxPrice,
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
        minPrice: state.minPrice,
        maxPrice: state.maxPrice,
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

  void setCurrentIndex(int index) {
    state = state.copyWith(currentIndex: index);
  }

  void setCanUndo(bool value) {
    state = state.copyWith(canUndo: value);
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
        gender: state.gender, sizes: state.sizes, styles: state.styles, age: age, hasSeenTutorial: state.hasSeenTutorial, role: state.role);
  }

  void setRole(String role) {
    state = UserPreferences(
        gender: state.gender, sizes: state.sizes, styles: state.styles, age: state.age, hasSeenTutorial: state.hasSeenTutorial, role: role);
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
final conversationsProvider = StreamProvider.autoDispose<List<ChatConversation>>((ref) {
  final userId = ref.watch(authProvider).fbUser?.uid;
  if (userId == null) return Stream.value([]);
  return ref.watch(apiServiceProvider).getConversations(userId);
});

final messagesProvider = StreamProvider.autoDispose.family<List<ChatMessage>, String>((ref, conversationId) {
  return ref.watch(apiServiceProvider).getMessages(conversationId);
});

final sellerListingsProvider = FutureProvider.autoDispose.family<List<WavyItem>, String>((ref, sellerId) {
  return ref.watch(apiServiceProvider).getSellerListings(sellerId);
});

final userProfileProvider = FutureProvider.autoDispose.family<WavyUser?, String>((ref, userId) {
  return ref.watch(apiServiceProvider).getUser(userId);
});

final itemProvider = FutureProvider.autoDispose.family<WavyItem, String>((ref, itemId) {
  return ref.watch(apiServiceProvider).getItem(itemId);
});

// ─── Locale Provider ───────────────────────────────────────
final localeProvider = StateNotifierProvider<LocaleNotifier, String>((ref) {
  final hive = ref.watch(hiveServiceProvider);
  return LocaleNotifier(hive);
});

class LocaleNotifier extends StateNotifier<String> {
  final HiveService _hive;
  LocaleNotifier(this._hive) : super(_hive.getLocale());

  Future<void> setLocale(String locale) async {
    await AppLocalizations.load(locale);
    await _hive.setLocale(locale);
    state = locale;
  }
}

// ─── Onboarding complete provider (persisted to Hive) ──────
class OnboardingNotifier extends StateNotifier<bool> {
  final HiveService _hive;
  OnboardingNotifier(this._hive) : super(_hive.getOnboardingComplete());

  void complete() {
    _hive.setOnboardingComplete(true);
    state = true;
  }

  void reset() {
    _hive.setOnboardingComplete(false);
    state = false;
  }
}

final onboardingCompleteProvider =
    StateNotifierProvider<OnboardingNotifier, bool>((ref) {
  return OnboardingNotifier(ref.watch(hiveServiceProvider));
});

// ─── Sell Draft Provider (persists form state across tab switches) ─
class SellDraftState {
  final String title;
  final String price;
  final String size;
  final String condition;
  final List<String> imagePaths;

  const SellDraftState({
    this.title = '',
    this.price = '',
    this.size = 'M',
    this.condition = 'Good',
    this.imagePaths = const [],
  });

  SellDraftState copyWith({
    String? title,
    String? price,
    String? size,
    String? condition,
    List<String>? imagePaths,
  }) {
    return SellDraftState(
      title: title ?? this.title,
      price: price ?? this.price,
      size: size ?? this.size,
      condition: condition ?? this.condition,
      imagePaths: imagePaths ?? this.imagePaths,
    );
  }
}

class SellDraftNotifier extends StateNotifier<SellDraftState> {
  SellDraftNotifier() : super(const SellDraftState());

  void updateTitle(String v) => state = state.copyWith(title: v);
  void updatePrice(String v) => state = state.copyWith(price: v);
  void updateSize(String v) => state = state.copyWith(size: v);
  void updateCondition(String v) => state = state.copyWith(condition: v);
  void addImage(String path) =>
      state = state.copyWith(imagePaths: [...state.imagePaths, path]);
  void removeImage(int index) {
    final paths = List<String>.from(state.imagePaths);
    paths.removeAt(index);
    state = state.copyWith(imagePaths: paths);
  }
  void clear() => state = const SellDraftState();
}

final sellDraftProvider =
    StateNotifierProvider<SellDraftNotifier, SellDraftState>((ref) {
  return SellDraftNotifier();
});
