import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

class ConfigService {
  static const String _host = 'landfall-platypus-truck.ngrok-free.dev';
  static const String _configUrl = 'https://$_host/config';
  
  static const String _cachedConfigKey = '_cachedConfigKey';
  static const String _cachedVersionKey = '_cachedVersionKey';

  Map<String, dynamic> _currentConfig = {};
  late HttpClient _httpClient;
  bool _isInitialized = false;  

  Map<String, dynamic> get currentConfig => _currentConfig;

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

    if (kIsWeb) {
      print('skip native Https');
      return;
    }

    await _initHttps();
    await _checkServerForUpdate();
  }

  Future<void> _initHttps() async {
    if (_isInitialized) return; 

    try {
      final certData = await rootBundle.load('assets/certificates/server.crt');
      final bytes = certData.buffer.asUint8List();

      final SecurityContext context = SecurityContext();
      context.setTrustedCertificatesBytes(bytes);
      _httpClient = HttpClient(context: context);

      _httpClient.badCertificateCallback = (X509Certificate cert, String host, int port) {
        print('certificate accepted');
        return true;
      };

      _isInitialized = true; 
      print('Https client with embedded certificate');
    } catch (e) {  
      print('failed to load certificate: $e');
    }
  }

  Future<void> _checkServerForUpdate() async {
    try {
      final request = await _httpClient.getUrl(Uri.parse(_configUrl));
      final response = await request.close();

      if (response.statusCode == 200) {
        final responseBody = await response.transform(utf8.decoder).join();
        await _processResponse(responseBody);
      } else {
        print('Server returned ${response.statusCode}');
      }
    } catch (e) {
      print('update check failed $e');
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
      print('Update config from server: version $serverVersion');
    } else {
      print('config is up to date (version $serverVersion)');
    }
  }  

  Map<String, dynamic> getDefaultConfig() {
    return {
      'version': 0,
      'titleText': 'Are you lucky today?',
      'wheelColors': ['add some colors later']
    };
  }

  void dispose() {
    _httpClient.close();
  }
}
