import 'dart:ui';
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';


class ConfigService {
  static const String _configUrl = 'my future ip server(netbook)(https)/config'; //add later
  static const String _cachedConfigKey = '_cachedConfigKey';
  static const String _cachedVersionKey = '_cachedVersionKey';

  Map<String, dynamic> _currentConfig = {};
  late HttpClient httpClient;
  bool _isInitialiazed = false;

  Future<void> _initHttps() async {
    if (_isInitialiazed) return;
    httpClient = HttpClient();

    try {
      final cerData = await rootBundle.load('assets/certificates/server.crt');
      final bytes = cerData.buffer.asUint8List();

      final fingerprint = await _calculateFingerprint(bytes);
      print('Certificate fingerprint: $fingerprint');

      _httpClient.badCertificateCallback = (X509Certificate cert, String host, int port) {
        final serverFingerprint = _certToFingerprint(cert);

        final isValid = (serverFingerprint == fingerprint);
        if (!isValid) {
          print('Certificate mismatch. Expected: $fingerprint, Got: $serverFingerprint');
        } else {
          print('✅ Certificate verified');
        }
        return isValid;
      };
      _isInitialiazed = true;
      print('https client Initialiazed');
    } catch (e) {
      print('failed to load certificate: $e');
    }
  }
  
  Future<String>  _calculateFingerprint(Uint8List certBytes) async {
    final digest = await _sha256(certBytes);
    return _bytesToHex(digest);
  }
  String _certToFingerprint(X509Certificate cert) {
    final derBytes = cert.der;
    final digest = _sha256Sync(derBytes);
    return _bytesToHex(digest);
  }
  Future<Uint8List> _sha256(Uint8List bytes) async {
    return _sha256Sync(bytes);
  }
  Uint8List _sha256Sync(Uint8List bytes) {
    print('⚠️ SHA256 calculation needs crypto package');
    print('Later do that');
    return Uint8List(32);
  }
  String _bytesToHex(Uint8List bytes) {
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }
  Future<void> loadConfig() async {
    await  _initHttps();
    final prefs = await SharedPreferences.getInstance();

    final cached = prefs.getString(_cachedConfigKey);
    if (cached != null) {
    _currentConfig = jsonDecode(cached);
    print('use load cahce');
    } else {
    _currentConfig = getDefaultConfig();
    print('use default cache')
    }

    await _checkServerForUpdate();
  }

  Future<void> _checkServerForUpdate() async {
    try {
      final request = await _httpClient.getUrl(Uri.parse(_configUrl));
      final response = await request.close();

      if (response.statusCode == 200) {
        final responseBody = await response.transform(utf8.decoder).join();
        final serverConfig = jsonDecode(response.body);
        final prefs = await SharedPreferences.getInstance();

        final cachedVersion = prefs.getInt(_cachedVersionKey) ?? 0;
        final serverVersion = serverConfig['version'] ?? 0;

        if (serverVersion != cachedVersion) {
        await prefs.setString(_cachedConfigKey, response.body);
        await prefs.setInt(_cachedVersionKey, serverVersion);
        _currentConfig = serverConfig;
        print('Update config from server: version &serverVersion');
        } else {
        print('config is update to date( version $serverVersion)');
        }
      } else {
      print('server returned $(response.statusCode)');
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
  void dispose() {
    _httpClient.close();
  }
}
