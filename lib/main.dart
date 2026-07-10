import 'package:wheel_of_fortune/wheel/wheel_screen.dart';
import 'package:wheel_of_fortune/services/sync_service.dart';
import 'package:wheel_of_fortune/services/user_id_service.dart';
import 'package:wheel_of_fortune/services/notification_service.dart';
import 'package:wheel_of_fortune/services/app_config_service.dart';
import 'package:wheel_of_fortune/services/music_service.dart';
import 'package:wheel_of_fortune/services/game_events.dart'; 
import 'package:wheel_of_fortune/services/routing.dart'; 
import 'package:wheel_of_fortune/screen/welcome.dart';
import 'package:wheel_of_fortune/screen/splash_screen.dart';
import 'package:wheel_of_fortune/services/logger.dart';
import 'package:wheel_of_fortune/services/log_overlay.dart';

import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:bee_dynamic_launcher/bee_dynamic_launcher.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint, kReleaseMode;
import 'package:bot_toast/bot_toast.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart';

// Глобальный доступ к navigatorKey
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 👇 СНАЧАЛА ИНИЦИАЛИЗИРУЕМ ВСЕ СЕРВИСЫ
  await _initServices();
  
  // 👇 ПОТОМ ЗАПУСКАЕМ ПРИЛОЖЕНИЕ
  runApp(const MyApp());
}

Future<void> _initServices() async {
  try {
    await Firebase.initializeApp();
    Log.i('Firebase initialized successfully');
  } catch (e, st) {
    Log.h(e, st, 'Firebase init failed');
  }
  
  // Настройки системы
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarDividerColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  
  // ИНИЦИАЛИЗИРУЕМ ВСЕ СЕРВИСЫ ПО ПОРЯДКУ
  await RoutingService().init();      // 1. Роутинг
  await AppConfigService().init();    // 2. Конфиг с сервера
  await GameEventsService().init();   // 3. События
  
  // Инициализация других сервисов в фоне
  unawaited(_initOtherServices());
}

Future<void> _initOtherServices() async {
  if (kReleaseMode) {
  Log.d('Release mode started');

//    Log.d(String? message, {int? wrapWidth}) {};
  }

  // Launcher
  if (!kIsWeb && Platform.isAndroid) {
    try {
      await BeeDynamicLauncher.initializeFromCatalog();
      Log.i('Launcher initialized');
    } catch (e, st) {
      Log.h(e, st, 'Init error');
    }
  }

  // User ID
  final userInfo = await UserIdService.getUserInfo();
    Log.i('✅ USER INIT: ${userInfo['nickname']} | ${userInfo['userId']}');
//  final deviceId = await UserIdService.getDeviceId();
 // debugPrint('User ID: $userId');
 // debugPrint('Device Id: $deviceId');

  // FCM
  String? fcmToken;
  try {
    fcmToken = await FirebaseMessaging.instance.getToken();
    Log.i('FCM initializad');
   // debugPrint('FCM TOKEN: $fcmToken');
  } catch (e, st) {
    Log.h(e, st, "Failed to get FCM Token");
  }
  if (fcmToken != null) {
    await NotificationService.registerDevice(fcmToken);
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMusic();
    });
  }

  Future<void> _loadMusic() async {
    try {
      final context = navigatorKey.currentContext;
      if (context != null) {
        await MusicService.initialize(context: context);
      }
    } catch (e, st) {
      Log.h(e, st,'Failed to load music');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    MusicService.setAppLifecycleState(state);
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      GameEventsService().endSession();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    GameEventsService().dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
       // showPerformanceOverlay: true,
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      theme: ThemeData.dark(),
      home: const SplashScreen(), 
      builder: (context, child) {
        child = BotToastInit()(context, child);
        return LogOverlay(child:child!);
      },
      navigatorObservers: [BotToastNavigatorObserver()],
    );
  }
}
