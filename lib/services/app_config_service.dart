import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AppConfigService {
  AppConfigService._();
  static final AppConfigService _instance = AppConfigService._();
  factory AppConfigService() => _instance;

  static const _workerUrl =
      "https://firstapp-backend.dark-lord.workers.dev";

  final ValueNotifier<bool> starsNotifier = ValueNotifier(false);

  Map<String, dynamic> _config = {
    "version": "0",
    "titleText": "Are you lucky today?",
    "termsUrl": "https://dark-lord.pages.dev/projects/fortune/terms",
    "privacyUrl": "https://dark-lord.pages.dev/projects/fortune/privacy",
    "shareUrl": "",
    "tgChannel": "",
    "donateUrl": "",
    "music": <String, dynamic>{},
  };

  bool starsEnabled = false;
  bool spinSoundEnabled = true;
  bool winSoundEnabled = true;
  bool backgroundMusicEnabled = true;

  dynamic operator [](String key) => _config[key];

  String get version => _config["version"] ?? "0";
  String get workerUrl => _workerUrl;
  String get titleText => _config["titleText"] ?? "";
  String get termsUrl => _config["termsUrl"] ?? "";
  String get privacyUrl => _config["privacyUrl"] ?? "";
  String get shareUrl => _config["shareUrl"] ?? "";
  String get tgChannel => _config["tgChannel"] ?? "";
  String get donateUrl => _config["donateUrl"] ?? "";
  String get syncUrl => _config["syncUrl"] ?? ""; //hyi znaet dlya chego
  String get musicVersion => _config["music"]?["music_version"] ?? "0";
  String get musicArchiveUrl => _config["music"]?["archive_url"] ?? "";
  String get musicReason => _config["music"]?["reason"] ?? "";
  bool get showMusicUpdateMessage => _config["music"]?["show_update_message"] ?? false;


  Map<String, dynamic> get music =>
      Map<String, dynamic>.from(_config["music"] ?? {});

  Future<void> init() async {
    await _loadPrefs();
    await _loadConfig();
    starsNotifier.value = starsEnabled;
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();

    final cache = prefs.getString("cached_config");
    if (cache != null) {
      _config = Map<String, dynamic>.from(jsonDecode(cache));
    }

    starsEnabled =
        prefs.getBool("stars_enabled") ?? starsEnabled;
    spinSoundEnabled =
        prefs.getBool("spin_sound_enabled") ?? spinSoundEnabled;
    winSoundEnabled =
        prefs.getBool("win_sound_enabled") ?? winSoundEnabled;
    backgroundMusicEnabled =
        prefs.getBool("background_music_enabled") ??
        backgroundMusicEnabled;
  }

  Future<void> _loadConfig() async {
    try {
      final response = await http
          .get(
            Uri.parse("$_workerUrl/config"),
            headers: const {
              "Content-Type": "application/json",
            },
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode != 200) return;

      final config =
          Map<String, dynamic>.from(jsonDecode(response.body));

      if (config["version"] == _config["version"]) return;

      _config = config;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        "cached_config",
        jsonEncode(_config),
      );

      debugPrint("Config updated (${_config["version"]})");
    } catch (e) {
      debugPrint("Config error: $e");
    }
  }

  Future<void> setStarsEnabled(bool value) async {
    starsEnabled = value;
    starsNotifier.value = value;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("stars_enabled", value);
  }

  Future<void> setSpinSoundEnabled(bool value) async {
    spinSoundEnabled = value;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("spin_sound_enabled", value);
  }

  Future<void> setWinSoundEnabled(bool value) async {
    winSoundEnabled = value;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("win_sound_enabled", value);
  }

  Future<void> setBackgroundMusicEnabled(bool value) async {
    backgroundMusicEnabled = value;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(
      "background_music_enabled",
      value,
    );
  }

  Future<void> resetToDefaults() async {
    starsEnabled = false;
    spinSoundEnabled = true;
    winSoundEnabled = true;
    backgroundMusicEnabled = true;

    starsNotifier.value = false;

    final prefs = await SharedPreferences.getInstance();

    await prefs.remove("stars_enabled");
    await prefs.remove("spin_sound_enabled");
    await prefs.remove("win_sound_enabled");
    await prefs.remove("background_music_enabled");
  }
}
