import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

// ─── Auth Provider ─────────────────────────────────────────
class AuthState {
  final String? phone;
  final String? token;
  final bool isVerified;
  final bool isLoading;
  final String? error;
  final WavyUser? user;

  const AuthState({
    this.phone,
    this.token,
    this.isVerified = false,
    this.isLoading = false,
    this.error,
    this.user,
  });

  AuthState copyWith({
    String? phone,
    String? token,
    bool? isVerified,
    bool? isLoading,
    String? error,
    WavyUser? user,
  }) {
    return AuthState(
      phone: phone ?? this.phone,
      token: token ?? this.token,
      isVerified: isVerified ?? this.isVerified,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      user: user ?? this.user,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiService _api;
  final HiveService _hive;

  AuthNotifier(this._api, this._hive) : super(const AuthState()) {
    _loadPersistedAuth();
  }

  Future<void> _loadPersistedAuth() async {
    final token = _hive.getAuthToken();
    final userId = _hive.getUserId();
    if (token != null && userId != null) {
      state = state.copyWith(token: token, isVerified: true);
      final user = await _api.getUser(userId);
      if (user != null) {
        state = state.copyWith(user: user);
      }
    }
  }

  Future<void> sendOtp(String phone) async {
    state = state.copyWith(isLoading: true, phone: phone, error: null);
    try {
      await _api.sendOtp(phone);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> verifyOtp(String otp) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await _api.verifyOtp(state.phone!, otp);
      final token = result['token'] as String?;
      state = state.copyWith(
        isLoading: false,
        isVerified: true,
        token: token,
      );
      // Persist
      if (token != null) _hive.saveAuthToken(token);
      
      // Try to find or create user
      final userId = result['id'] as String?;
      if (userId != null) {
        _hive.saveUserId(userId);
        final user = await _api.getUser(userId);
        if (user != null) {
          state = state.copyWith(user: user);
        }
      }
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  void setUser(WavyUser user) {
    state = state.copyWith(user: user);
  }

  void setPhone(String phone) {
    state = state.copyWith(phone: phone);
  }

  /// Demo-mode: accepts any code, marks user as verified immediately
  void mockVerify(String phone) {
    const mockToken = 'demo_token_wavy_2024';
    const mockUserId = 'usr_001';
    _hive.saveAuthToken(mockToken);
    _hive.saveUserId(mockUserId);
    state = state.copyWith(
      phone: phone,
      token: mockToken,
      isVerified: true,
      error: null,
      isLoading: false,
      user: const WavyUser(
        id: mockUserId,
        name: 'Wavy User',
        phone: '',
        preferences: UserPreferences(),
      ),
    );
  }

  void logout() {
    _hive.clearAuth();
    state = const AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    ref.watch(apiServiceProvider),
    ref.watch(hiveServiceProvider),
  );
});

// ─── Feed Provider ─────────────────────────────────────────
class FeedState {
  final List<WavyItem> items;
  final bool isLoading;
  final String? error;
  final int currentPage;

  const FeedState({
    this.items = const [],
    this.isLoading = false,
    this.error,
    this.currentPage = 1,
  });

  FeedState copyWith({
    List<WavyItem>? items,
    bool? isLoading,
    String? error,
    int? currentPage,
  }) {
    return FeedState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      currentPage: currentPage ?? this.currentPage,
    );
  }
}

class FeedNotifier extends StateNotifier<FeedState> {
  final ApiService _api;

  FeedNotifier(this._api) : super(const FeedState());

  Future<void> loadFeed() async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final items = await _api.getFeed(page: 1);
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
      final items = await _api.getFeed(page: nextPage);
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

  SavedNotifier(this._api) : super([]);

  void addItem(WavyItem item) {
    if (!state.any((i) => i.id == item.id)) {
      state = [...state, item];
    }
  }

  void removeItem(String itemId) {
    state = state.where((i) => i.id != itemId).toList();
  }

  bool isSaved(String itemId) {
    return state.any((i) => i.id == itemId);
  }

  Future<void> loadSavedItems(List<String> itemIds) async {
    try {
      final items = await _api.getSavedItems(itemIds);
      state = items;
    } catch (_) {}
  }
}

final savedProvider =
    StateNotifierProvider<SavedNotifier, List<WavyItem>>((ref) {
  return SavedNotifier(ref.watch(apiServiceProvider));
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
