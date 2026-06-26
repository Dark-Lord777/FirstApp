import 'package:wheel_of_fortune/services/database_service.dart';
import 'package:wheel_of_fortune/services/user_id_service.dart';

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;

class SyncService {
  static bool _isSyncing = false;
  static const String serverUrl = 'https://deploy-boss.dark-lord.workers.dev/analytics';

  static Future<void> syncData() async {
    if (_isSyncing) return;
    _isSyncing = true;

    if (kIsWeb) {
    debugPrint("Web sync disabled");
    _isSyncing = false;
    return;
    }

    try {
      final data = await DatabaseService.instance.getAllAnalytics();
      
      if (data['spins'].isEmpty && data['sectors'].isEmpty && data['events'].isEmpty) {
        debugPrint(' Nothing to sync');
        return;
      }
      
      final userInfo = await UserIdService.getUserInfo();
      data['userId'] = userInfo['userId'];
      data['deviceId'] = userInfo['deviceId'];

      final jsonString = jsonEncode(data);
      final bytes = utf8.encode(jsonString);
      final compressed = gzip.encode(bytes);

      
      debugPrint('📤 Sending ${data['spins'].length} spins, ${data['sectors'].length} sectors...');

      final response = await http.post(
        Uri.parse(serverUrl),
        headers: {
          'Content-Type': 'application/octet-stream',
          'Content-Encoding': 'gzip',
        },
        body: compressed,
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        await DatabaseService.instance.clearAfterSync();
        debugPrint(' Analytics synced and cleared');
        //now i write return here because when i commented print for release app i think this function ma broke my app
        return;
      } else {
        debugPrint(' Server returned ${response.statusCode}');
        return;
      }
    } catch (e) {
      debugPrint(' Sync failed: $e');
      return;
    }
  }

  static Future<void> forceSync() async {
    debugPrint(' Force syncing...');
    await syncData();
  }
}
