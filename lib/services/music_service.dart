import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as p;
import 'package:audioplayers/audioplayers.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:wheel_of_fortune/services/app_config_service.dart';
import 'package:wheel_of_fortune/widgets/base_anim_btn.dart';
import 'package:wheel_of_fortune/services/game_message.dart';
import 'package:wheel_of_fortune/services/logger.dart';

class MusicService {
  // ===== PLAYERS =====
  static final AudioPlayer _backgroundPlayer = AudioPlayer();
  static final AudioPlayer _effectPlayer = AudioPlayer();

  // ===== STATE =====
  static bool _spinSoundEnabled = true;
  static bool _winSoundEnabled = true;

  static bool _initialized = false;
  static bool _musicLoaded = false;
  static bool _isDownloading = false;
  static String _musicVersion = "";
  static const String _tempArchive = "music.zip";
  static const bool kUseBundledMusic = true;

  static final Random _random = Random();
  static bool _isAppInBackground = false;
  static String _lastTrackPath = "";
static Duration _lastTrackPosition = Duration.zero;

  static const Map<String, String> _musicFolders = {
  'BackgroundMusic': 'bg',
  'Spin': 'spin',
  'Win': 'win',
  'UI': 'click',
};
  static const List<String> _supportedExtensions = ['.mp3', '.wav', '.ogg'];


  // ===== GETTERS =====
  static bool get spinSoundEnabled => _spinSoundEnabled;
  static bool get winSoundEnabled => _winSoundEnabled;

  // ===== SETTERS (только здесь, один раз!) =====
  static void setSpinSoundEnabled(bool enabled) {
    _spinSoundEnabled = enabled;
    if (!enabled) {
      _effectPlayer.stop();
    }
  }

  static void setWinSoundEnabled(bool enabled) {
    _winSoundEnabled = enabled;
    if (!enabled) {
      _effectPlayer.stop();
    }
  }

  // ===== LOCAL CACHE =====
  static final List<String> _backgroundTracks = [];
  static final Map<String, String> _sounds = {};

  // ===== PUBLIC API =====
  static Future<void> initialize({
    required BuildContext context,
  }) async {
    if (_initialized) return;
    _initialized = true;


await _effectPlayer.setAudioContext(AudioContext(
      android: const AudioContextAndroid(
        isSpeakerphoneOn: false,
        audioFocus: AndroidAudioFocus.none,
      ),
    ));


    _backgroundPlayer.onPlayerComplete.listen((_) {
      _onTrackComplete();
    });
    await loadMusic(context: context);
    await _loadSavedState();
    _backgroundPlayer.onPlayerStateChanged.listen((state) {
  Log.d("STATE: $state");
});

_backgroundPlayer.onDurationChanged.listen((d) {
  Log.d("DURATION: $d");
});

  }
  
  static Future<void> _loadMusic({required BuildContext context}) async {
    if (_isDownloading) {
      Log.i('Music download already running');
      return;
    }

    _isDownloading = true;
    try {
      if (!AppConfigService().backgroundMusicEnabled) {
        await stopMusic();
        return;
      }

      await _loadAllMusic();

      _updateMusic(context);

      _musicLoaded = true;

      if (_backgroundTracks.isNotEmpty && !_isAppInBackground) {
        await _playRandomBackground();
      }
      Log.i("Music initialized");
    } catch (e, st) {
      Log.h(e, st,'Music loading failed:');
      BotToast.showText(text: "Music loading failed");
    } finally {
      _isDownloading = false;
    }
  }


  static Future<void> _loadAllMusic() async {
    _backgroundTracks.clear();
    _sounds.clear();

    await _loadFromAssets();

    await _loadFromDisk();
      Log.i("✅ Music (archived) loaded: ${_backgroundTracks.length} bg tracks, ${_sounds.length} effects");

  }

  static Future<void> _loadFromAssets() async {
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      final assets = manifest.listAssets();

      for (final folder in _musicFolders.keys) {
        final folderPath = 'assets/music/$folder/';
        final type = _musicFolders[folder]!;
        for (final asset in assets) {
          if (asset.startsWith(folderPath) && _isSupportedFile(asset)) {
            if (folder == 'BackgroundMusic') {
              _backgroundTracks.add(asset);
            } else {
              _sounds[type] = asset;
            }
          }
        }
      }
      Log.i('Loaded from assets');
    } catch (e, st) {
      Log.h(e, st,'Failed to load from assets');
    }
  }
  
  static Future<void> _loadFromDisk() async {
    try {
      final musicDir = await _musicDirectory();

      for (final folder in _musicFolders.keys) {
        final dir = Directory("${musicDir.path}/$folder");
      if (!await dir.exists()) continue;

      final files = dir.listSync();
      final type = _musicFolders[folder]!;

      for (final entity in files) {
          if (entity is! File) continue;
        final path = entity.path;
      if (_isSupportedFile(path)) {
        if (folder == 'BackgroundMusic') {
          if (!_backgroundTracks.contains(path)) {
              _backgroundTracks.add(path);
              }
            } else {
            _sounds[type] = path;
            }
          }
        }
      }
      Log.i('Loaded from Disk');
    } catch (e, st) {
      Log.h(e, st, 'Failed to load from disk');
    }
  }

  static bool _isSupportedFile(String path) {
    return _supportedExtensions.any((ext) => path.toLowerCase().endsWith(ext));
  }

  static Future<void> _loadFolder({
    required String folder,
    required String type,
    required bool isBackground,
  }) async {
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      final assets = manifest.listAssets();
      final folderPath = 'assets/music/$folder/';

      for (final asset in assets) {
        if (asset.startsWith(folderPath) && _isSupportedFile(asset)) {
          if (isBackground) {
            if (!_backgroundTracks.contains(asset)) {
              _backgroundTracks.add(asset);
            }
          } else {
            _sounds[type] = asset;
          }
        }
      }
    } catch (e, st) {
      Log.h(e, st, 'Failed to load $folder from assets');
    }

    try {
      final musicDir = await _musicDirectory();
      final dir = Directory("${musicDir.path}/$folder");
      if (!await dir.exists()) return;

      final files = dir.listSync();
      for (final entity in files) {
        if (entity is! File) continue;
        final path = entity.path;
        if (_isSupportedFile(path)) {
          if (isBackground) {
            if (!_backgroundTracks.contains(path)) {
              _backgroundTracks.add(path);
            }
          } else {
            _sounds[type] = path;
          }
        }
      }
    } catch (e, st) {
      Log.h(e, st, 'Failed to load $folder from disk');
    }
  }


  static Future<void> reloadMusic({
    required BuildContext context,
  }) async {
    _musicLoaded = false;
    _isDownloading = false;
    await loadMusic(context: context);
  }


  static Future<void> loadMusic({
    required BuildContext context,
  }) async {

    if (_isDownloading) {
      Log.i("Music download already running");
      return;
    }

    _isDownloading = true;
    try {
      if (!AppConfigService().backgroundMusicEnabled) {
        await stopMusic();
        return;
      }
      
      final musicFolder = await _musicDirectory();
      final firstStart = !await musicFolder.exists();

      if (firstStart) {
        await musicFolder.create(recursive: true);
        BotToast.showText(
          text: "Downloading music...",
        );
      }
      
      await _loadBackgroundMusic();



await _loadEffects("spin");
await _loadEffects("win");
await _loadEffects("click");

       _updateMusic(context);
      _musicLoaded = true;

      if (firstStart && _backgroundTracks.isNotEmpty) {
        BotToast.showText(
          text: "Music downloaded",
        );
      }
    
      //start a music after as app was in background 
      if (_backgroundTracks.isNotEmpty && !_isAppInBackground) {
        await _playRandomBackground();
      }

      Log.i("Music initialized");
    } catch (e, st) {
      Log.h(e, st, 'Music loading failed');
      //debugPrint(e.toString());
      BotToast.showText(
        text: "Music loading failed",
      );
    } finally {
      _isDownloading = false;
    }
  }
  
static Future<void> resumeMusic() async {
  if (!AppConfigService().backgroundMusicEnabled) {
    Log.d(' Music disabled, not resuming');
    return;
  }
  
  if (_backgroundTracks.isEmpty) {
    Log.i(' No tracks loaded, cannot resume');
    return;
  }
  
  if (_lastTrackPath.isNotEmpty) {
    await _resumeFromSavedState();
  } else {
    await _playRandomBackground();
  }
}  

  static Future<void> play(String sound) async {
    final path = _sounds[sound];

    if (path == null) {
      Log.w("Unknown sound: $sound");
      return;
    }

    try {
      if (_effectPlayer.state == PlayerState.playing) {
        return;
      }
      await _effectPlayer.stop();
      await _effectPlayer.play(
        DeviceFileSource(path),
      );
      await _effectPlayer.setVolume(1);
    } catch (e, st) {
      Log.h(e, st, 'Error in function play');
//      debugPrint(e.toString());
    }
  }

// when your app in background your music playsand this fnc help you 

  static void setAppLifecycleState(AppLifecycleState state) {
    if (state ==  AppLifecycleState.paused || 
        state ==  AppLifecycleState.detached) {
        _saveCurrentStateManually();
        _isAppInBackground = true;
        _backgroundPlayer.stop();
        Log.d('Music paused (app in background)');
        } else if (state ==  AppLifecycleState.resumed) {
          if (_backgroundTracks.isNotEmpty && AppConfigService().backgroundMusicEnabled) {
          _resumeFromSavedState();
          }
          Log.d("Music resumed (app in foreground)");
        }
      }

  static Future<void> _saveCurrentStateManually() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    
    if (_lastTrackPath.isNotEmpty) {
      await prefs.setString('last_track_path', _lastTrackPath);
      await prefs.setInt('last_track_position', _lastTrackPosition.inMilliseconds);
      Log.i(' Saved manually: ${_lastTrackPath.split('/').last} at ${_lastTrackPosition.inSeconds}s');
    }
  } catch (e, st) {
    Log.h(e, st, 'Failed to save state manually');
  }
}

static Future<void> _saveCurrentState() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      if (_lastTrackPath.isNotEmpty) {
        await prefs.setString('last_track_path', _lastTrackPath);
      }
      final position = await _backgroundPlayer.getCurrentPosition();
      if (position != null) {
        await prefs.setInt('last_track_position', position.inMilliseconds);
      }
      Log.i('Saved state: ${_lastTrackPath.split('/').last} at ${position?.inSeconds}s');
    } catch (e, st) {
      Log.h(e, st,'failed to save state');
    }
  }  

  static Future<void> _resumeFromSavedState() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final trackPath = prefs.getString('last_track_path');
      final positionMs = prefs.getInt('last_track_position');

      if (trackPath == null || positionMs == null) {
        if (_backgroundTracks.isNotEmpty) {
        Log.w('Not save a state');
        await _playRandomBackground();
        }
        return;
      }
      final file = File(trackPath);
      if (!await file.exists()) {
        Log.i('Saved track not found, playing random');
        await _playRandomBackground();
        return;
      }
      await _backgroundPlayer.stop();
      await _backgroundPlayer.play(DeviceFileSource(trackPath), position: Duration(milliseconds: positionMs ?? 0));
      await _backgroundPlayer.setVolume(1);
      _lastTrackPath = trackPath;
       _lastTrackPosition = Duration(milliseconds: positionMs);

        _startPositionTimer();
      Log.d('Resumed: ${trackPath.split("/").last} at ${positionMs ~/ 1000}s');
    } catch (e, st) {
      Log.h(e, st, 'failed to resume $e');
      if (_backgroundTracks.isNotEmpty) {
      await _playRandomBackground();
      }
    }
  }
  static Timer? _positionTimer;

static void _startPositionTimer() {
  _positionTimer?.cancel();
  _positionTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
    final pos = await _backgroundPlayer.getCurrentPosition();
    if (pos != null) {
      _lastTrackPosition = pos;
        Log.d(' Position updated: ${pos.inSeconds}s');
    }
  });
}

  static Future<void> _loadSavedState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final trackPath = prefs.getString('last_track_path');
      final positionMs = prefs.getInt('last_track_position');

      if (trackPath != null && positionMs != null) {
        _lastTrackPath = trackPath;
        _lastTrackPosition = Duration(milliseconds: positionMs);
         Log.i(' Loaded saved state: ${trackPath.split('/').last} at ${positionMs ~/ 1000}s');

      }

    } catch (e, st) {
      Log.h(e, st, 'Failed ti load saved state');
    }
  }

// ===== ЭФФЕКТЫ =====
static Future<void> playClick() async {
  if (!_sounds.containsKey("click")) {
    Log.w('⚠️ click sound not loaded');
    return;
  }
  
  try {
    await _effectPlayer.play(DeviceFileSource(_sounds["click"]!));
    await _effectPlayer.setVolume(0.5); // тише, чтобы не перекрывало
  } catch (e, st) {
    Log.h(e, st, 'Error playing click: $e');
  }
}

static Future<void> playSpinSound() async {
  if (!_spinSoundEnabled) return;
  if (!_sounds.containsKey("spin")) return;
  
  try {
    await _effectPlayer.stop();
    await _effectPlayer.play(DeviceFileSource(_sounds["spin"]!));
    await _effectPlayer.setVolume(1);
  } catch (e, st) {
    Log.h(e, st, 'Error playing spin: $e');
  }
}

static Future<void> playWinSound() async {
  if (!_winSoundEnabled) return;
  if (!_sounds.containsKey("win")) return;
  
  try {
    await _effectPlayer.stop(); 
    await _effectPlayer.play(DeviceFileSource(_sounds["win"]!));
    await _effectPlayer.setVolume(1);
  } catch (e, st) {
    Log.h(e, st, 'Error playing win: $e');
  }
}
  static Future<void> stopSpinSound() async {
    await _effectPlayer.stop();
  }

  static Future<void> stopMusic() async {
      _positionTimer?.cancel();
    await _backgroundPlayer.stop();
  }

  static Future<void> stopAll() async {
    await _backgroundPlayer.stop();
    await _effectPlayer.stop();
  }

  static Future<void> setBackgroundVolume(
    double volume,
  ) async {
    await _backgroundPlayer.setVolume(volume);
  }

  static void dispose() {
    _backgroundPlayer.dispose();
    _effectPlayer.dispose();
  }

  // ===== BACKGROUND MUSIC =====
  static Future<void> _loadBackgroundMusic() async {
    await _loadFolder(
      folder: 'BackgroundMusic',
      type: 'bg',
      isBackground: true,
    );
    _backgroundTracks.clear();

    Log.i("Loaded ${_backgroundTracks.length} background tracks");
  }


  static Future<void> _playRandomBackground() async {
    if (_backgroundTracks.isEmpty) {
    Log.w('No tracks available');
      return;
    }

    if (!AppConfigService().backgroundMusicEnabled) {
      Log.d('Bakcground music disabled, skiping');
      return;
    }

    final path = _backgroundTracks[_random.nextInt(_backgroundTracks.length)];
    final file = File(path);

    if (!await file.exists()) {
      Log.w("Missing music file $path");
      return;
    }

    try {
      await _backgroundPlayer.stop();
      await _backgroundPlayer.play(
        DeviceFileSource(path),
      );
      await _backgroundPlayer.setVolume(1);
      _lastTrackPath = path;
      _lastTrackPosition = Duration.zero;

          _startPositionTimer();

      Log.i("Playing: ${path.split('/').last}");
    } catch (e, st) {
      Log.h(e, st, 'Error playing background: $e');
      debugPrint(e.toString());
    }
  }
    static void _onTrackComplete() {
      Log.d('Track finished, playing next...');
        _positionTimer?.cancel();
      _playRandomBackground();
    }
  


  // ===== EFFECTS =====
  static Future<void> _loadEffects(String type) async {
    final folder = _musicFolders.keys.firstWhere(
      (key) => _musicFolders[key] == type,
      orElse: () => '',
    );
    
    if (folder.isEmpty) {
      Log.w("Unknown effect type: $type");
      return;
    }

    await _loadFolder(
      folder: folder,
      type: type,
      isBackground: false,
    );
    Log.i("Loaded $type effect: ${_sounds[type] ?? 'not found'}");
  }

  static Future<void> _loadEffect(String type) async {
    await _loadEffect("spin");
    await _loadEffects("win");
    await _loadEffects('click');

  }


  // ===== DOWNLOAD =====
  static Future<bool> _downloadArchive(
    String url,
  ) async {
    try {
      final response = await http.get(Uri.parse(url));
      Log.i("download ok");
      if (response.statusCode !=200 ) {
        return false;
      }
      final dir = await _musicDirectory();

      final archive = File("${dir.path}/$_tempArchive");
      await archive.writeAsBytes(
        response.bodyBytes,
      );
      return true;
    } catch (e, st) {
      Log.h(e, st, 'Download error');
 //     debugPrint(e.toString());
      return false;
    }
  }

  // EXTRACT
static Future<bool> _extractArchive() async {
  try {
    final dir = await _musicDirectory();

    final archiveFile = File(
      "${dir.path}/$_tempArchive",
    );

    if (!await archiveFile.exists()) {
      return false;
    }

    final bytes = await archiveFile.readAsBytes();

    final archive = ZipDecoder().decodeBytes(bytes);

    final tempDir = Directory(
      "${dir.path}_new",
    );

    if (await tempDir.exists()) {
      await tempDir.delete(
        recursive: true,
      );
    }

    await tempDir.create();

    for (final file in archive) {
      final filename = p.join(
        tempDir.path,
        file.name,
      );

      if (file.isFile) {
        final out = File(filename);

        await out.parent.create(
          recursive: true,
        );

        await out.writeAsBytes(
          file.content as List<int>,
        );
      } else {
        await Directory(filename).create(
          recursive: true,
        );
      }
    }

    await archiveFile.delete();

    final oldDir = await _musicDirectory();

    if (await oldDir.exists()) {
      await oldDir.delete(
        recursive: true,
      );
    }

    await tempDir.rename(
      oldDir.path,
    );
    Log.i("extract ok");
    return true;
  } catch (e, st) {
    Log.h(e, st, 'Failed extracted music');
//    debugPrint(e.toString());
    return false;
  }
}

static Future<void> _updateMusic(BuildContext context) async {

  await _loadCache();

  final remoteVersion = AppConfigService().musicVersion;

  if (_musicVersion == remoteVersion) {
  Log.i("Music is up to date version $_musicVersion");
    return;
  }
    Log.d("New music version available $remoteVersion");

  final ok = await _downloadArchive(
        "${AppConfigService().workerUrl}/music",
  );

  if (!ok) return;

  final extracted = await _extractArchive();

  if (!extracted) return;

  await _saveMusicVersion(remoteVersion);
    _backgroundTracks.clear();
    _sounds.clear();

    await _loadAllMusic();

    if (_backgroundTracks.isNotEmpty) {
      await _playRandomBackground();
    }

    if (AppConfigService().showMusicUpdateMessage) {
    await GameMessage.show(
      context: context,
      title: "Music updated",
      text: AppConfigService().musicReason,
      icon: MessageIcon.music,
      gradient: MessageGradient.purple,
      buttons: [
        MessageButton.ok(),
      ],
    );
  }
}


  // ===== CACHE =====
  static Future<Directory> _musicDirectory() async {
    final dir = await getApplicationDocumentsDirectory();
    return Directory("${dir.path}/music");
  }

  static Future<void> _loadCache() async {
    final prefs = await SharedPreferences.getInstance();
    _musicVersion = prefs.getString("music_version") ?? "";
  }

  static Future<void> _saveMusicVersion(
    String version,
  ) async {
    _musicVersion = version;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      "music_version",
      version,
    );
  }



  // ===== ОЧИСТКА КЕША МУЗЫКИ =====
  static Future<void> clearMusicCache() async {
    try {
      final dir = await _musicDirectory();
      if (await dir.exists()) {
        await dir.delete(recursive: true);
        Log.dev('🗑️ Music cache cleared');
      }
      _musicLoaded = false;
      _backgroundTracks.clear();
      _sounds.clear();

      await _loadAllMusic();
    } catch (e, st) {
      Log.h(e, st, 'Error clearing music cache: $e');
    }
  }


}

