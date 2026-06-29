import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http; 
import 'package:shared_preferences/shared_preferences.dart';

class AppConfigService {
  static final AppConfigService _instance = AppConfigService._internal();
  factory AppConfigService() => _instance;
  AppConfigService._internal();

//config .json which have on server 
  String _workerUrl = 'https://firstapp-backend.dark-lord.workers.dev';
  String _syncUrl = '';
  String _termsUrl = 'https://dark-lord.pages.dev/projects/fortune/terms';
  String _privacyUrl = 'https://dark-lord.pages.dev/projects/fortune/privacy';
  String _shareUrl = '';
  String _appVersion = '0';
  String _titleText = 'Are you lucky today?';
  String _tgChannel = '';
  String _donateUrl = '';
  bool _musicEnabled = false;
  List<String> _musicTracks = [];
  String _spinSound = '';
  String _winSound = '';
  bool _forceUpdate = false;
  String _musicReason = '';

  bool _spinSoundEnabled = true;
  bool _winSoundEnabled = true;
  bool _backgroundMusicEnabled = true;
  
  // getters 
  String get workerUrl => _workerUrl;
  String get syncUrl => _syncUrl;
  String get termsUrl => _termsUrl;
  String get privacyUrl => _privacyUrl;
  String get shareUrl => _shareUrl;
  String get appVersion => _appVersion;
  String get titleText => _titleText;
  String get tgChannel => _tgChannel;
  String get donateUrl => _donateUrl;
  bool get musicEnabled => _musicEnabled;
  List<String> get musicTracks => _musicTracks;
  String get spinSound => _spinSound;
  String get winSound => _winSound;
  
  bool get spinSoundEnabled => _spinSoundEnabled;
  bool get winSoundEnabled => _winSoundEnabled;
  bool get backgroundMusicEnabled => _backgroundMusicEnabled;
  bool get forceUpdate => _forceUpdate;
  String get musicReason => _musicReason;
  bool _starsEnabled = false;
  bool get starsEnabled => _starsEnabled;

//setters 

  set starsEnabled(bool value) {
    _starsEnabled = value;
    SharedPreferences.getInstance().then((prefs) {
      prefs.setBool('stars_enabled', value);
    });
  }
  
  set spinSoundEnabled(bool value) {
    _spinSoundEnabled = value;
    SharedPreferences.getInstance().then((prefs) {
      prefs.setBool('spin_sound_enabled', value);
    });
  }
  set winSoundEnabled(bool value) {
    _winSoundEnabled = value;
    SharedPreferences.getInstance().then((prefs) {
      prefs.setBool('win_sound_enabled', value);
    });
  }
  set backgroundMusicEnabled(bool value) {
    _backgroundMusicEnabled = value;
    SharedPreferences.getInstance().then((prefs) {
      prefs.setBool('background_music_enabled', value);
    });
  }
  set forceUpdate(bool value) {
    _forceUpdate = value;
    SharedPreferences.getInstance().then((prefs) {
      prefs.setBool('force_update', value);
    });
  }
  set musicReason(String value) {
    _musicReason = value;
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString('music_reason', value);
    });
  }

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
      _starsEnabled = prefs.getBool('stars_enabled') ?? false;
      _spinSoundEnabled = prefs.getBool('spin_sound_enabled') ?? true;
      _winSoundEnabled = prefs.getBool('win_sound_enabled') ?? true;
      _backgroundMusicEnabled = prefs.getBool('background_music_enabled') ?? true;
      _forceUpdate = prefs.getBool('force_update') ?? false;
      _musicReason = prefs.getString('music_reason') ?? '';
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
