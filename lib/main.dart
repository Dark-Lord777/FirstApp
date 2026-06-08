import 'package:flutter/material.dart';
import 'package:wheel_of_fortune/wheel/wheel_screen.dart';
import 'package:wheel_of_fortune/services/config_service.dart';  
import 'package:wheel_of_fortune/services/config_service_interface.dart';
import 'package:wheel_of_fortune/services/sync_service.dart';
import 'package:bee_dynamic_launcher/bee_dynamic_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'dart:async';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Только для Android/iOS, НЕ для Web
  if (!kIsWeb) {
    try {
      await BeeDynamicLauncher.initializeFromCatalog();
      
      final configService = createConfigService();
      await configService.loadConfig();
      
      final iconName = configService.currentConfig['currentIcon'] ?? 'default';
      final currentIcon = await BeeDynamicLauncher.getCurrentVariant();
      
      if (iconName != currentIcon) {
        await BeeDynamicLauncher.applyVariant(iconName);
        debugPrint(' Icon changed to: $iconName');
      }
    } catch (e) {
      debugPrint(' Icon error (non-critical): $e');
    }
  } else {
    debugPrint(' Web mode: icons disabled');
  }

  final configService = createConfigService();
  await configService.loadConfig();

  Timer(const Duration(seconds: 5), () async {
    await SyncService.syncData();
  });

  runApp(MyApp(configService: configService));
}

class MyApp extends StatelessWidget {
  final ConfigServiceInterface configService;

  const MyApp({required this.configService, super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: WheelScreen(configService: configService),
    );
  }
}
