import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

abstract class ConfigServiceInterface {
  Map<String, dynamic> get currentConfig;
  Future<void> loadConfig();
  void dispose();
}
