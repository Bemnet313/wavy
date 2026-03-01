import 'package:hive_flutter/hive_flutter.dart';

class HiveService {
  static const String _authBoxName = 'auth';
  static const String _eventsBoxName = 'events_queue';
  static const String _prefsBoxName = 'preferences';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(_authBoxName);
    await Hive.openBox<Map>(_eventsBoxName);
    await Hive.openBox(_prefsBoxName);
  }

  // ─── Auth Persistence ──────────────────────────────────
  Box get _authBox => Hive.box(_authBoxName);

  String? getAuthToken() => _authBox.get('token') as String?;
  void saveAuthToken(String token) => _authBox.put('token', token);

  String? getUserId() => _authBox.get('userId') as String?;
  void saveUserId(String userId) => _authBox.put('userId', userId);

  void clearAuth() {
    _authBox.delete('token');
    _authBox.delete('userId');
    _prefsBox.delete('has_seen_tutorial');
  }

  // ─── Offline Event Queue ───────────────────────────────
  Box<Map> get _eventsBox => Hive.box<Map>(_eventsBoxName);

  Future<void> enqueueEvent(Map<String, dynamic> event) async {
    final key = DateTime.now().millisecondsSinceEpoch.toString();
    await _eventsBox.put(key, event);
  }

  List<MapEntry<dynamic, Map>> getPendingEvents() {
    return _eventsBox.toMap().entries.toList();
  }

  Future<void> removeEvent(dynamic key) async {
    await _eventsBox.delete(key);
  }

  Future<void> clearEvents() async {
    await _eventsBox.clear();
  }

  // ─── Preferences ───────────────────────────────────────
  Box get _prefsBox => Hive.box(_prefsBoxName);

  String getLocale() => _prefsBox.get('locale', defaultValue: 'en') as String;
  Future<void> setLocale(String locale) => _prefsBox.put('locale', locale);

  bool getOnboardingComplete() =>
      _prefsBox.get('onboarding_complete', defaultValue: false) as bool;
  Future<void> setOnboardingComplete(bool complete) =>
      _prefsBox.put('onboarding_complete', complete);

  bool getHasSeenTutorial() =>
      _prefsBox.get('has_seen_tutorial', defaultValue: false) as bool;
  Future<void> setHasSeenTutorial(bool seen) =>
      _prefsBox.put('has_seen_tutorial', seen);
}
