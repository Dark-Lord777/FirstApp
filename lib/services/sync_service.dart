import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:wheel_of_fortune/services/database_service.dart';

class SyncService {
  static const String serverUrl = 'https://deploy-boss.dark-lord.workers.dev/analytics';

  static Future<void> syncData() async {
    try {
      final data = await DatabaseService.instance.getAllAnalytics();
      
      if (data['spins'].isEmpty && data['sectors'].isEmpty && data['events'].isEmpty) {
        print('📭 Nothing to sync');
        return;
      }

      // Сжимаем с помощью gzip (встроенный в Dart)
      final jsonString = jsonEncode(data);
      final bytes = utf8.encode(jsonString);
      final compressed = gzip.encode(bytes);
      
      print('📤 Sending ${data['spins'].length} spins, ${data['sectors'].length} sectors...');

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
        print('✅ Analytics synced and cleared');
      } else {
        print('❌ Server returned ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Sync failed: $e');
    }
  }

  static Future<void> forceSync() async {
    print('🔄 Force syncing...');
    await syncData();
  }
}
