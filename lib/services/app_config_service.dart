import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http; 
import 'package:shared_preferences/shared_preferences.dart';

class AppConfigService {
  static final AppConfigService _instance = AppConfigService._internal();
  factory AppConfigService() => _instance;
  AppConfigService._internal();

  String _workerUrl = 'https://firstapp-backend.dark-lord.workers.dev';
  String _syncUrl = '';
  String _termsUrl = 'https://dark-lord.pages.dev/projects/fortune/terms';
  String _privacyUrl = 'https://dark-lord.pages.dev/projects/fortune/privacy';
  String _shareUrl = '';
  String _appVersion = '0';
  String _titleText = 'Are you lucky today?';
  String _tgChannel = '';
  String _donateUrl = '';

  // Геттеры
  String get workerUrl => _workerUrl;
  String get syncUrl => _syncUrl;
  String get termsUrl => _termsUrl;
  String get privacyUrl => _privacyUrl;
  String get shareUrl => _shareUrl;
  String get appVersion => _appVersion;
  String get titleText => _titleText;
  String get tgChannel => _tgChannel;
  String get donateUrl => _donateUrl;

  Future<void> init() async {
    await _loadFromLocalPrefs();
    await _fetchRemoteConfig();
  }

  Future<void> _loadFromLocalPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _appVersion = prefs.getString('cached_app_version') ?? '0';
      _termsUrl = prefs.getString('cached_terms_url') ?? _termsUrl;
      _privacyUrl = prefs.getString('cached_privacy_url') ?? _privacyUrl;
      _shareUrl = prefs.getString('cached_share_url') ?? _shareUrl;
      _titleText = prefs.getString('cached_title_text') ?? _titleText;
      _workerUrl = prefs.getString('cached_worker_url') ?? _workerUrl;
      _tgChannel = prefs.getString('cached_tg_channel') ?? _tgChannel;
      _donateUrl = prefs.getString('cached_donate_url') ?? _donateUrl;
    } catch (e) {
      debugPrint('Error when readed a cache: $e');
    }
  }

  Future<void> _fetchRemoteConfig() async {
    try {
      final response = await http.get(
        Uri.parse('$_workerUrl/config'),
        headers: {'Content-Type': "application/json"},
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final Map<String, dynamic> config = jsonDecode(response.body);
        
        final String serverVersion = config['version']?.toString() ?? '0';

        if (serverVersion != _appVersion) {
          _titleText = config['titleText'] ?? _titleText;
          _termsUrl = config['termsUrl'] ?? _termsUrl;
          _privacyUrl = config['privacyUrl'] ?? _privacyUrl;
          _shareUrl = config['shareUrl'] ?? _shareUrl;
          _tgChannel = config['tgChannel'] ?? _tgChannel;
          _donateUrl = config['donateUrl'] ?? _donateUrl;
          _appVersion = serverVersion;

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('cached_terms_url', _termsUrl);
          await prefs.setString('cached_privacy_url', _privacyUrl);
          await prefs.setString('cached_share_url', _shareUrl);
          await prefs.setString('cached_title_text', _titleText);
          await prefs.setString('cached_tg_channel', _tgChannel);
          await prefs.setString('cached_donate_url', _donateUrl);
          await prefs.setString('cached_app_version', _appVersion);

          debugPrint(' Config updated from server (version: $_appVersion)');
        } else {
          debugPrint(' Config is up to date (version $_appVersion)');
        }
      } else {
        debugPrint(' Server returned ${response.statusCode}');
      }
    } catch (e) {
      debugPrint(' Failed to get config: $e');
    }
  }
}
