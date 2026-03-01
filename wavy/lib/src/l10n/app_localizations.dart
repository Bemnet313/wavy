import 'dart:convert';
import 'package:flutter/services.dart';

class AppLocalizations {
  final String locale;
  late Map<String, String> _strings;

  AppLocalizations(this.locale);

  static AppLocalizations? _instance;
  static AppLocalizations get instance => _instance!;

  static Future<AppLocalizations> load(String locale) async {
    final localizations = AppLocalizations(locale);
    final jsonString = await rootBundle.loadString('assets/l10n/$locale.json');
    final Map<String, dynamic> jsonMap = json.decode(jsonString);
    localizations._strings =
        jsonMap.map((key, value) => MapEntry(key, value.toString()));
    _instance = localizations;
    return localizations;
  }

  String tr(String key) => _strings[key] ?? key;

  // Convenience getters for frequently used strings
  String get appName => tr('app_name');
  String get appTagline => tr('app_tagline');
  String get ctaIWantThis => tr('cta_i_want_this');
  String get ctaShowPhone => tr('cta_show_phone');
  String get ctaCallSeller => tr('cta_call_seller');
  String get ctaMarkSold => tr('cta_mark_sold');
  String get ctaPublish => tr('cta_publish');
  String get ctaSave => tr('cta_save');
  String get ctaSell => tr('cta_sell');
  String get ctaContinue => tr('cta_continue');
  String get ctaGetStarted => tr('cta_get_started');
  String get ctaVerify => tr('cta_verify');
  String get ctaSendOtp => tr('cta_send_otp');
  String get navFeed => tr('nav_feed');
  String get navSaved => tr('nav_saved');
  String get navSell => tr('nav_sell');
  String get navProfile => tr('nav_profile');
  String get noInternet => tr('no_internet');
}
