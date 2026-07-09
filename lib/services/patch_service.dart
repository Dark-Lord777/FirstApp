import 'package:shorebird_code_push/shorebird_code_push.dart';
import 'package:wheel_of_fortune/services/logger.dart';

class PatchService {
  static final ShorebirdUpdater _updater = ShorebirdUpdater();

  static Patch? _currentPatch;
  
  static bool get isAvailable => _updater.isAvailable;

  static Future<bool> hasNewPatch() async {
    try {
      if (!_updater.isAvailable) {
        Log.w('Shorebird is not available');
        return false;
      }
  
    final status = await _updater.checkForUpdate(track: UpdateTrack.stable);

    switch (status) {
      case UpdateStatus.outdated:
        Log.i("New patch available");
        return true;
      case UpdateStatus.upToDate:
        Log.i("App is up to date");
        return false;
      case UpdateStatus.restartRequired:
        Log.i("Restart required to apply patch");
          return true;
      case UpdateStatus.unavailable:
        Log.w("Update unavailable");
        return false;
    }
  } catch (e, st) {
      Log.h(e,st, "Error checking new patch");
      return false;
    }
  }


  static Future<bool> isPatchReadyToInstall() async {
    try {
      if (!_updater.isAvailable) return false;
      final currentPatch = await _updater.readCurrentPatch();

      if (currentPatch != null) {
        final status = await _updater.checkForUpdate(track: UpdateTrack.stable);
        return status == UpdateStatus.restartRequired;
      }
      return false;
    } catch (e, st) {
      Log.h(e, st, 'Error checking patch ready');
      return false;
    }
  }

  static Future<bool> isPatchApplied() async {
    try {
      if (!_updater.isAvailable) return false;

      final currentPatch = await _updater.readCurrentPatch();
      _currentPatch = currentPatch;

      return currentPatch != null;
    } catch (e, st) {
      Log.h(e, st, 'Error checking patch applied');
      return false;
    }
  }


  static Future<int?> getcurrentPatchNumber() async {
    try {
      if (!_updater.isAvailable) return null;

      final currentPatch = await _updater.readCurrentPatch();
      return currentPatch?.number;

    } catch (e) {
      return null;
    }
  }

  static Future<void> downloadAndInstallPatch() async {
    try {
      if (!_updater.isAvailable) {
        Log.w("Shorebird is not available");
        return;
      }

      Log.i("Starting patch download...");
      await _updater.update(track: UpdateTrack.stable);

      Log.i("Patch downloaded successful");
      Log.i('Restart required to apply the patch');

    } catch (e, st) {
      Log.h(e,st,"Error downloading patch");
      throw Exception('Failed to donwlod patch: $e');
    }
  }
  
  //for debug 
  static Future<UpdateStatus> getUpdateStatus() async {
    try {
      if (!_updater.isAvailable) return UpdateStatus.unavailable;
      return await _updater.checkForUpdate(track: UpdateTrack.stable);
    } catch (e) {
      return UpdateStatus.unavailable;
    }
  }
}
