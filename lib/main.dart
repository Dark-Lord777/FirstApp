import 'package:wheel_of_fortune/wheel/wheel_screen.dart';
import 'package:wheel_of_fortune/services/sync_service.dart';
import 'package:wheel_of_fortune/services/user_id_service.dart';
import 'package:wheel_of_fortune/services/notification_service.dart';
import 'package:wheel_of_fortune/services/app_config_service.dart';
import 'package:wheel_of_fortune/services/music_service.dart';

import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:bee_dynamic_launcher/bee_dynamic_launcher.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint, kReleaseMode;
import 'package:bot_toast/bot_toast.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:audioplayers/audioplayers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
 //   await FirebaseMessaging.ensureInitialized();
  try {
    await Firebase.initializeApp();
    debugPrint('Firebase initialized succesfully');
  } catch (e) {
    debugPrint('Firebase init failed $e');
  }

  await AppConfigService().init(); 

    if (kReleaseMode) {
      debugPrint = (String? message, {int? wrapWidth}) {};
    }

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
  /*
  final config = AppConfigService().currentConfig;
  await MusicService.loadMusic(config);
*/
  await MusicService.loadMusic(
    enabled: AppConfigService().musicEnabled,
    tracks: AppConfigService().musicTracks,
    spinSound: AppConfigService().spinSound,
    winSound: AppConfigService().winSound,
  );
  final userId = await UserIdService.getUserId();
  final deviceId = await UserIdService.getDeviceId();
  debugPrint('User ID: $userId');
  debugPrint('Device Id $deviceId');

  String? fcmToken;
  try {
    fcmToken = await FirebaseMessaging.instance.getToken();
    debugPrint('FCM TOKEN: $fcmToken');
  } catch (e) {
    debugPrint("Failed to get FCM Token: $e");
  }
  if (fcmToken != null) {
    await NotificationService.registerDevice(fcmToken);
  }


  runApp(const MyApp());
}

class MyApp extends StatelessWidget {

  const MyApp({ super.key});

  @override
Widget build(BuildContext context) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData.dark(),
    home: const WheelScreen(),
      builder: (context, child) {
        child = BotToastInit()(context, child);
        return child;
      },
      navigatorObservers: [BotToastNavigatorObserver()],
    );
  }
}
