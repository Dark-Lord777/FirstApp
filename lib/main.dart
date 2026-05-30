import 'package:flutter/material.dart';
import 'package:wheel_of_fortune/wheel/wheel_screen.dart';
import 'package:wheel_of_fortune/services/config_service.dart';  
import 'package:wheel_of_fortune/services/config_service_interface.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();


  final configService = createConfigService();
  await configService.loadConfig();

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

