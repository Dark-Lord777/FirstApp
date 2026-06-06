import 'package:flutter/foundation.dart' show kIsWeb; 
import 'package:wheel_of_fortune/services/config_service_interface.dart';
import 'package:wheel_of_fortune/services/config_service_worker.dart'; 

ConfigServiceInterface createConfigService() {
  return ConfigServiceWorker();
}
