import 'package:wheel_of_fortune/wheel/wheel_screen.dart';
import 'package:wheel_of_fortune/services/config_service.dart';
import 'package:wheel_of_fortune/services/sync_service.dart';

import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:bee_dynamic_launcher/bee_dynamic_launcher.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:bot_toast/bot_toast.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // initialisation bee_dynamic_launcher
  if (!kIsWeb && Platform.isAndroid) {
    try {
      await BeeDynamicLauncher.initializeFromCatalog();
      debugPrint(' Launcher initialized');
      final variants = await BeeDynamicLauncher.getAvailableVariants();
      debugPrint('Available variants: $variants');
      
      final current = await BeeDynamicLauncher.getCurrentVariant();
      debugPrint("Current cariant: $current");

    } catch (e) {
      debugPrint(' Init error: $e');
    }
  }

  final configService = ConfigService();
  await configService.loadConfig();


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
      builder: (context, child) {
        child = BotToastInit()(context, child);
        return child;
      },
      navigatorObservers: [BotToastNavigatorObserver()],
    );
  }
}
