import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import './config_service_interface.dart';

class ConfigServiceWeb implements ConfigServiceInterface {
  static const String _host = 'landfall-platypus-truck.ngrok-free.dev';
  static const String _configUrl = 'https://$_host/config';
  
  static const String _cachedConfigKey = '_cachedConfigKey';
  static const String _cachedVersionKey = '_cachedVersionKey';

  Map<String, dynamic> _currentConfig = {};
  
  @override 
  Map<String, dynamic> get currentConfig => _currentConfig;

  @override 
  Future<void> loadConfig() async {
    final prefs = await SharedPreferences.getInstance();

    final cached = prefs.getString(_cachedConfigKey);
    if (cached != null) {
      _currentConfig = jsonDecode(cached);
      print('use load cache');
    } else {
      _currentConfig = getDefaultConfig();
      print('use default cache');
    }

    await _checkServerForUpdate();
  }
  
  @override 
  Future<void> _checkServerForUpdate() async {
    try {
      final response = await http
      .get(Uri.parse(_configUrl))
      .timeout(const Duration(seconds: 3));


      if (response.statusCode == 200) {
        await _processResponse(response.body);
      } else {
        print('Server returned ${response.statusCode}');
      }
    } catch (e) {
      print('update check failed $e');
    }
  }
  
  @override 
  Future<void> _processResponse(String responseBody) async {
    final serverConfig = jsonDecode(responseBody);
    final prefs = await SharedPreferences.getInstance();

    final cachedVersion = prefs.getInt(_cachedVersionKey) ?? 0;
    final serverVersion = serverConfig['version'] ?? 0;

    if (serverVersion != cachedVersion) {
      await prefs.setString(_cachedConfigKey, responseBody);
      await prefs.setInt(_cachedVersionKey, serverVersion);
      _currentConfig = serverConfig;
      print('Update config from server: version $serverVersion');
    } else {
      print('config is up to date (version $serverVersion)');
    }
  }  
  @override 
  Map<String, dynamic> getDefaultConfig() {
    return {
      'version': 0,
      'titleText': 'Are you lucky today?',
      'wheelColors': ['add some colors later']
    };
  }
  
  @override 
  void dispose() {
  }
}
