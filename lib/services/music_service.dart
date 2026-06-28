import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class MusicService {
  static final AudioPlayer _player = AudioPlayer();
  static List<String> _tracks = [];
  static int _currentTrackIndex = 0;
  static bool _isPlaying = false;
  static String? _spinSoundPath;
  static String? _winSoundPath;

    static Future<void> loadMusic({
      required bool enabled,
      required List<String> tracks,
      required String spinSound,
      required String winSound,
    }) async {
      try {
        if (!enabled) {
          await stopMusic();
          return;
        }

        final prefs = await SharedPreferences.getInstance();

        // Если треки изменились — скачиваем
        if (_tracks != tracks || _spinSoundPath == null || _winSoundPath == null) {
          await _downloadTracks(tracks);
          _tracks = tracks;
          await prefs.setStringList('cached_tracks', _tracks);
          
          if (spinSound.isNotEmpty) {
            _spinSoundPath = await _downloadSingleSound(spinSound, 'spin.mp3');
          }
          if (winSound.isNotEmpty) {
            _winSoundPath = await _downloadSingleSound(winSound, 'win.mp3');
          }
        }

        // Запускаем фоновую музыку
        if (_tracks.isNotEmpty && !_isPlaying) {
          _playRandomTrack();
        }
      } catch (e) {
        debugPrint('Music service error: $e');
      }
    }

  static Future<String?> _downloadSingleSound(String url, String fileName) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final musicDir = Directory('${dir.path}/music');
      if (!await musicDir.exists()) {
        await musicDir.create();
      }

      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final file = File('${musicDir.path}/$fileName');
        await file.writeAsBytes(response.bodyBytes);
        return file.path;
      }
    } catch (e) {
      debugPrint('Failed to download sound: $url');
    }
    return null;
  }

  static Future<void> _downloadTracks(List<String> urls) async {
    final dir = await getApplicationDocumentsDirectory();
    final musicDir = Directory('${dir.path}/music');
    if (!await musicDir.exists()) {
      await musicDir.create();
    }

    for (var url in urls) {
       final fileName = url.split('/').last;
       final file = File('${musicDir.path}/$fileName');

      if (await file.exists() && file.lengthSync() > 0) {
       debugPrint('✅ File exists and not empty: $fileName');
        continue;
        }
    
      try {
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          await file.writeAsBytes(response.bodyBytes);
          debugPrint('Downloaded: $fileName');
        }
      } catch (e) {
        debugPrint('Failed to download: $url');
      }
    }
  }

  static Future<void> _playRandomTrack() async {
    if (_tracks.isEmpty) return;
    
    _currentTrackIndex = DateTime.now().millisecondsSinceEpoch % _tracks.length;
    final trackName = _tracks[_currentTrackIndex].split('/').last;
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/music/$trackName');

    if (await file.exists()) {
      await _player.play(DeviceFileSource(file.path));
      _isPlaying = true;
    }
  }

  static Future<void> playSpinSound() async {
    if (_spinSoundPath != null) {
      await _player.play(DeviceFileSource(_spinSoundPath!));
    }
  }

  static Future<void> playWinSound() async {
    if (_winSoundPath != null) {
      await _player.play(DeviceFileSource(_winSoundPath!));
    }
  }

  static Future<void> stopMusic() async {
    await _player.stop();
    _isPlaying = false;
  }

  static Future<void> _showDeleteDialog(String reason, Map<String, dynamic> config) async {
    final dir = await getApplicationDocumentsDirectory();
    final musicDir = Directory('${dir.path}/music');
    if (await musicDir.exists()) {
      await musicDir.delete(recursive: true);
    }

    final musicConfig = config['music'] ?? {};
    final newTracks = List<String>.from(musicConfig['tracks'] ?? []);
    if (newTracks.isNotEmpty) {
      await _downloadTracks(newTracks);
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('delete_reason');
  }

  static void dispose() {
    _player.dispose();
  }

  static final AudioPlayer _bgPlayer = AudioPlayer(); // фоновый
  static final AudioPlayer _sfxPlayer = AudioPlayer(); // звуковые эффекты

  //for background music 
  static Future<void> playBackgroundMusic(String path) async {
  await _bgPlayer.play(DeviceFileSource(path));
  _bgPlayer.setVolume(1.0);
}

static Future<void> setBackgroundVolume(double volume) async {
  await _bgPlayer.setVolume(volume);
}

static Future<void> stopBackgroundMusic() async {
  await _bgPlayer.stop();
}
/*
  //for sound effects like isWin or isWheel 
static Future<void> playSpinSound() async {
  if (_spinSoundPath != null) {
    await _sfxPlayer.play(DeviceFileSource(_spinSoundPath!));
    _sfxPlayer.setVolume(1.0); // не приглушаем
  }
}

static Future<void> playWinSound() async {
  if (_winSoundPath != null) {
    await _sfxPlayer.play(DeviceFileSource(_winSoundPath!));
    _sfxPlayer.setVolume(1.0); // не приглушаем
  }
}
*/


}
