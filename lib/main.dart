import 'package:wheel_of_fortune/wheel/wheel_screen.dart';
import 'package:wheel_of_fortune/services/config_service.dart';  
import 'package:wheel_of_fortune/services/config_service_interface.dart';
import 'package:wheel_of_fortune/services/sync_service.dart';

import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:bee_dynamic_launcher/bee_dynamic_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'dart:async';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final configService = ConfigService();
  await configService.loadConfig();

  // Только для Android, НЕ для Web/ios 
  if (!kIsWeb && Platform.isAndroid) {
    try {
      final isSupported = await BeeDynamicLauncher.isSupported();
      if (isSupported) {
      final iconName = configService.currentConfig['currentIcon'] ?? 'default';
      final result = await BeeDynamicLauncher.setIcon(iconName);
      if (result == true) {
      debugPrint("Icon changed to $iconName");
        } else {
      debugPrint("Failed to change icon");
        }
       } else {
      debugPrint("Dynamic icon not supported in this device hah loh");
        }
      } catch(e) {
      debugPrint("Icon error: $e");
        }
       } else if (kIsWeb) {
      debugPrint("web mode icons disabled");
        } else if (Platform.isIOS) {
      debugPrint("I don't have a mackbook, so i don't know how to fix");
       }

      
  Future.delayed(const Duration(seconds: 5), () async {
    try {
    await SyncService.syncData();
      debugPrint("Sync completed");
    } catch(e) {
      debugPrint("Sync error: $e");
    }
  });

  runApp(MyApp(configService: configService));
}

class MyApp extends StatelessWidget {
  final ConfigService configService;

  const MyApp({required this.configService, super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: WheelScreen(configService: configService),
    );
  }
}
