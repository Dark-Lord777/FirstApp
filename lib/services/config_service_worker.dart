import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import './config_service_interface.dart';
import 'package:flutter/foundation.dart' show debugPrint; 

class ConfigServiceWorker implements ConfigServiceInterface {
  static const String _workerUrl = 'https://deploy-boss.dark-lord.workers.dev/config';
  static const String _cachedConfigKey = '_cachedConfigKey';
  static const String _cachedVersionKey = '_cachedVersionKey';

  Map<String, dynamic> _currentConfig = {};
  
  @override
  Map<String, dynamic> get currentConfig => _currentConfig;

  @override
  Future<void> loadConfig() async {
    final prefs = await SharedPreferences.getInstance();

    // Загружаем кэш
    final cached = prefs.getString(_cachedConfigKey);
    if (cached != null) {
      _currentConfig = jsonDecode(cached);
      debugPrint(' Loaded config from cache');
    } else {
      _currentConfig = getDefaultConfig();
      debugPrint(' Using default config');
    }

    // Проверяем обновления на сервере
    await _checkServerForUpdate();
  }
  
  Future<void> _checkServerForUpdate() async {
    try {
      final response = await http
          .get(Uri.parse(_workerUrl))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        await _processResponse(response.body);
      } else {
        debugPrint(' Server returned ${response.statusCode}');
      }
    } catch (e) {
      debugPrint(' Update check failed: $e');
    }
  }
  
  Future<void> _processResponse(String responseBody) async {
    final serverConfig = jsonDecode(responseBody);
    final prefs = await SharedPreferences.getInstance();

    final cachedVersion = prefs.getInt(_cachedVersionKey) ?? 0;
    final serverVersion = serverConfig['version'] ?? 0;

    if (serverVersion != cachedVersion) {
      await prefs.setString(_cachedConfigKey, responseBody);
      await prefs.setInt(_cachedVersionKey, serverVersion);
      _currentConfig = serverConfig;
      debugPrint('Updated config from worker: version $serverVersion');
    } else {
      debugPrint(' Config is up to date (version $serverVersion)');
    }
  }
  
  @override
  Map<String, dynamic> getDefaultConfig() {
    return {
      'version': 0,
      'titleText': 'Are you lucky today?',
      'wheelColors': ['#FF6B6B', '#4ECDC4', '#45B7D1', '#96CEB4', '#FFEAA7', '#DDA0DD'],
      'currentIcon': 'default',
    };
  }
  
  @override
  void dispose() {}
}
