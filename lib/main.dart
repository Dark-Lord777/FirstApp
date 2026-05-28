import 'package:flutter/material.dart';
import 'services/config_service.dart';
import 'wheel/wheel_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
      home: WheelScreen(configService: configService),
    );
  }
}

