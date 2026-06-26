import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'dart:io' show Platform;
import 'package:device_info_plus/device_info_plus.dart';

class UserIdService {
  static const String _uuidKey = 'user_uuid';
  static const String _deviceIdKey = 'device_id';

  static Future<String> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString(_uuidKey);

    if (userId == null) {
    userId = const Uuid().v4();
    await prefs.setString(_uuidKey, userId);
    }
    return userId;
  }

  static Future<String> getDeviceId() async {
    if (kIsWeb) {
      return await _getWebDeviceId();
    }
    if (Platform.isAndroid) {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      return androidInfo.id;
    }
    if (Platform.isIOS) {
      final deviceInfo = DeviceInfoPlugin();
      final iosInfo = await deviceInfo.iosInfo;
      return iosInfo.identifierForVendor ?? 'ios_unknown';
    }
    return 'unknown_device';
  }

  static Future<String> _getWebDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    String? deviceId = prefs.getString(_deviceIdKey);

    if (deviceId == null) {
      deviceId = 'web_${const Uuid().v4()}';
      await prefs.setString(_deviceIdKey, deviceId);
    }
    return deviceId;
  }
  static Future<Map<String, String>> getUserInfo() async {
    final userId = await getUserId();
    final deviceId = await getDeviceId();
    return {
      'userId': userId,
      'deviceId': deviceId,
    };
  }
}
