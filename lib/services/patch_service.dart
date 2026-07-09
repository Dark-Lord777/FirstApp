import 'package:shorebird_code_push/shorebird_code_push.dart';
import 'package:wheel_of_fortune/services/logger.dart';

class PatchService {
  static final ShorebirdCodePush _shorebird =  ShorebirdCodePush();

  static Future<bool> hasNewPatch() async {
    try {
      final hasUpdate = await _shorebird.isNewPatchAvailableForDownload();
      Log.i('App has a patch for update');
      return hasUpdate;
    } catch (e, st) {
      Log.h(e, st, "Error checking new patch");
      return false;
    }
  }

  static Future<bool> isPatchReadyToInstall() async {
    try {
      final isReady = await _shorebird.isPatchReadyToInstall();
      return isReady;
    } catch (e, st) {
      Log.h(e, st, 'Error checking patch ready');
      return false;
    }
  }

  static Future<bool> isPatchApplied() async {
    try {
      final patchNumber = await _shorebird.currentPatchNumber();
      return patchNumber != null;
    } catch (e, st) {
      Log.h(e, st, 'Error checking patch applied');
      return false;
    }
  }
  static Future<int?> getcurrentPatchNumber() async {
    try {
      return await _shorebird.currentPatchNumber();
    } catch (e) {
      return null;
    }
  }

  static Future<void> downloadAndInstallPatch() async {
    try {
      await _shorebird.downloadUpdateIfAvailable();
      Log.i('Patch downloaded successful');
    } catch (e, st) {
      Log.h(e,st,"Error downloading patch");
    }
  }
}
