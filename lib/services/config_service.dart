import 'package:flutter/foundation.dart' show kIsWeb; 
import 'package:wheel_of_fortune/services/config_service_interface.dart';
import 'package:wheel_of_fortune/services/config_service_worker.dart'; 


class ConfigService implements ConfigServiceInterface {
  final ConfigServiceWorker _worker = ConfigServiceWorker();

  @override
  Map<String, dynamic> get currentConfig => _worker.currentConfig;

  @override
  Future<void> loadConfig() async {
    await _worker.loadConfig();
  }
  @override
  void dispose() {
    _worker.dispose();
  }
}
