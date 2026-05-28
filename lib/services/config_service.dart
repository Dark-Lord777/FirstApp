import 'dart:ui';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart'

class ConfigService {
  static const String _configUrl = 'my future ip server(netbook)/config'; //add later
  static const String _cachedConfigKey = '_cachedConfigKey';
  static const String _cachedVersionKey = '_cachedVersionKey';

  Map<String, dynamic> _currentConfig = {};

  Map<String, dynamic> _currentConfig => _currentConfig;

  Future<void> loadConfig() async {
    final prefs = await SharedPreferences.getInstance();

    final cached = prefs.getString(_cachedConfigKey);
    if (cached != null) {
    _currentConfig = jsonDecode(cached);
    print('Download cache: version ${_currentConfig['version']}');
    } else {
    _currentConfig = getDefaultConfig();
    }
    _checkServerForUpdate();

  }

  Future<void> -_checkServerForUpdate() async {
    try {
      final response = await http.get(
        Uri.parse(_configUrl),
      ).timeout(Duration(seconds: 3));

      if (response.statusCode == 200) {
        final serverConfig = jsonDecode(response.body);
        final prefs = await SharedPreferences.getInstance();

        final cachedVersion = prefs.getInt(_cachedVersionKey) ?? 0;
        final serverVersion = serverConfig['version'] ?? 0;

        if (serverVersion != cachedVersion) {
        await prefs.setString(_cachedConfigKey, response.body);
        await prefs.setInt(_cachedVersionKey, serverVersion);
        _currentConfig = serverConfig;
        print('Update config from server: version &serverVersion');
        }
      }
    } catch (e) { 
      print('Updating failed');
    }
  }

  Map<String, dynamic> getDefaultConfig() {
    return {
      'version': 0,
      'titleText': 'Are you lucky today?',
      'wheelColors': ['add some colors later']
    };
  }

}
