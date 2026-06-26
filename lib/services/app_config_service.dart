import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http; 
import 'package:shared_preferences/shared_preferences.dart';

class AppConfigService {
  static final AppConfigService _instance = AppConfigService._internal();
  factory AppConfigService() => _instance;
  AppConfigService._internal();

  String _workerUrl = ''; //main andress 
  String _syncUrl = ''; //worker with /analytics on the future maybe i woukd use 

  String _termsUrl = ''; //my site 
  String _privacyUrl = ''; //my site 
  String _shareUrl = '';
  String _appVersion = '';
  String _titleText = ''; //by default "Are you lucky today?"
  //for massive of value you can use // List<String> _your_value 

  //getters/ for read 
  String get workerUrl => _workerUrl;
  String get syncUrl => _syncUrl;
  String get termsUrl => _termsUrl;
  String get privacyUrl => _privacyUrl;
  String get shareUrl => _shareUrl;
  String get appVersion => _appVersion;
  String get titleText => _titleText;

  Future<void> init() async {
    await _loadFromLocalPrefs();
    await _fetchRemoteConfig();
  }

  Future<void> _loadFromLocalPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      //you should use ?? this function do the next step/ when the last right value are empty 
      //or null this function use left value
      _termsUrl = prefs.getString('cached_terms_url') ?? termsUrl;
      _privacyUrl = prefs.getString('cached_privacy_url') ?? _privacyUrl;
      _shareUrl = prefs.getString('cached_share_url') ?? _shareUrl;
      _titleText = prefs.getString('cached_title_text') ?? _titleText;
      _workerUrl = prefs.getString('cached_worker_url') ?? _workerUrl;


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

        _titleText = config['titleText'] ?? _titleText;
        _termsUrl = config['termsUrl'] ?? _termsUrl;
        _privacyUrl = config['privacyUrl'] ?? _privacyUrl;
        _shareUrl = config['shareUrl'] ?? _shareUrl;

        final prefs = await SharedPreferences.getInstance();
          await prefs.setString('cached_terms_url', _termsUrl);
          await prefs.setString('cached_privacy_url', _privacyUrl);
          await prefs.setString('cached_share_url', _shareUrl);

          await prefs.setString('cached_title_text', _titleText);


        debugPrint('Config was update from server');
         } 
    } catch (e) {
      debugPrint('Failed to get config: $e');
    }
  }
}
