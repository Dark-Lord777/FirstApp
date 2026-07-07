import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:wheel_of_fortune/services/user_id_service.dart';
import 'package:wheel_of_fortune/services/logger.dart';


class NotificationService {
  static Future<void> registerDevice(String fcmToken) async {
    final userInfo = await UserIdService.getUserInfo();
    final response = await http.post(
      Uri.parse('https://firstapp-backend.dark-lord.workers.dev/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'userId': userInfo['userId'],
        'deviceId': userInfo['deviceId'],
        'fcmToken': fcmToken,
      }),
    );
    Log.i(' Registration response: ${response.statusCode}');
  }
}
