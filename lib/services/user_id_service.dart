import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'dart:io' show NetworkInterface, InternetAddressType, Platform;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:wheel_of_fortune/services/logger.dart'; // ПОДСТАВЬ СВОЙ ИМПОРТ ТАЛКЕРА

class UserIdService {
  static const String _uuidKey = 'user_uuid';
  static const String _nickKey = 'user_nikname';

  // 1. Метод получения ТОЛЬКО уникального UUID пользователя
  static Future<String> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString(_uuidKey);

    if (userId == null) {
      userId = const Uuid().v4();
      await prefs.setString(_uuidKey, userId);
      Log.d('Generated new fixed UUID: $userId');
    }
    return userId;
  }

  // 2. Метод получения ВСЕЙ жирной инфы для отправки на Cloudflare воркер
  static Future<Map<String, String>> getUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Получаем UUID и ник
    final userId = await getUserId();
    final nickname = prefs.getString(_nickKey) ?? 'Guest';

    String manufacturer = 'Unknown';
    String model = 'Unknown';
    String osVersion = 'Unknown';
    String localIp = 'Unknown';
    
    try {
      // Собираем данные устройства
      if (!kIsWeb) {
        final deviceInfo = DeviceInfoPlugin();
        if (Platform.isAndroid) {
          final androidInfo = await deviceInfo.androidInfo;
          manufacturer = androidInfo.manufacturer; 
          model = androidInfo.model;               
          osVersion = 'Android ${androidInfo.version.release}'; 
        } else if (Platform.isIOS) {
          final iosInfo = await deviceInfo.iosInfo;
          manufacturer = 'Apple';
          model = iosInfo.utsname.machine;
          osVersion = 'iOS ${iosInfo.systemVersion}';
        }
      } else {
        manufacturer = 'Web';
        model = 'Browser';
      }

      // Вытаскиваем локальный IP
      final interfaces = await NetworkInterface.list(
        includeLoopback: false,
        type: InternetAddressType.IPv4 // IPv6 тут вызовет кашу, оставляем IPv4
      );
      if (interfaces.isNotEmpty && interfaces.first.addresses.isNotEmpty) {
        localIp = interfaces.first.addresses.first.address;
      }
    } catch (e, st) {
      Log.h(e, st, 'Device data collection error');
    }

    final userInfo = {
      'userId': userId,
      'nickname': nickname,
      'deviceManufacturer': manufacturer,
      'deviceModel': model,
      'osVersion': osVersion,
      'localIp': localIp,
      'appVersion': '1.0.1',
    };
    Log.d('USER INFO: $userInfo');
    return userInfo;
  }

  // 3. Работа с Никнеймами
  static Future<String> getNickname() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_nickKey) ?? 'Guest';
  }

  static Future<void> setNickname(String nick) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_nickKey, nick);
    Log.i('Nickname changed on: $nick');
  }
}
