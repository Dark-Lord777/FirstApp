import 'package:wheel_of_fortune/wheel/wheel_screen.dart';
import 'package:wheel_of_fortune/services/config_service.dart';
import 'package:wheel_of_fortune/services/sync_service.dart';

import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:bee_dynamic_launcher/bee_dynamic_launcher.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Инициализация bee_dynamic_launcher
  if (!kIsWeb && Platform.isAndroid) {
    try {
      await BeeDynamicLauncher.initializeFromCatalog();
      debugPrint(' Launcher initialized');
    } catch (e) {
      debugPrint(' Init error: $e');
    }
  }

  final configService = ConfigService();
  await configService.loadConfig();

  // Смена иконки (только Android)
  if (!kIsWeb && Platform.isAndroid) {
    try {
      final variants = await BeeDynamicLauncher.getAvailableVariants();
      debugPrint('Available variants: $variants');

      final iconName = configService.currentConfig['currentIcon'] ?? 'default';

      if (variants.contains(iconName)) {
        await BeeDynamicLauncher.applyVariant(iconName);
        debugPrint(' Icon changed to $iconName');
      } else {
        debugPrint(' Variant $iconName not available');
      }
    } catch (e) {
      debugPrint(' Icon error: $e');
    }
  } else if (kIsWeb) {
    debugPrint(' Web mode: icons disabled');
  } else if (Platform.isIOS) {
    debugPrint(' iOS: dynamic icons supported with catalog setup');
  }

  Future.delayed(const Duration(seconds: 5), () async {
    try {
      await SyncService.syncData();
      debugPrint(' Sync completed');
    } catch (e) {
      debugPrint(' Sync error: $e');
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
    theme: ThemeData.dark(),
    home: WheelScreen(configService: configService),
  );
}
}
