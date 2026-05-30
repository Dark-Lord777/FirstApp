import 'package:flutter/foundation.dart' show kIsWeb; 
import 'package:wheel_of_fortune/services/config_service_interface.dart';
import 'package:wheel_of_fortune/services/config_service_web.dart';
import 'package:wheel_of_fortune/services/config_service_native.dart';

ConfigServiceInterface  createConfigService() {
    if (kIsWeb) {
    print('create web cng service');
    return ConfigServiceWeb(); 
    } else {
    print('create native cnfg service');
    return ConfigServiceNative();
    }
}
