import 'dart:convert';
import 'dart:math';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:bot_toast/bot_toast.dart';


import 'package:wheel_of_fortune/services/app_config_service.dart';
import 'package:wheel_of_fortune/widgets/modalka.dart';
import 'package:wheel_of_fortune/widgets/base_anim_btn.dart';


class MusicService {
  static final AudioPlayer _bgPlayer = AudioPlayer(); 
  static final AudioPlayer _sfxPlayer = AudioPlayer();
  
  static List<String> _tracks = [];
  static int _currentTrackIndex = 0;
  static bool _isPlaying = false;
  static String? _spinSoundPath;
  static String? _winSoundPath;

  static Future<void> loadMusic({required BuildContext context}) async {
    try {
//check background music 
      if (!AppConfigService().backgroundMusicEnabled) {
        await stopMusic();
        return;
      }
      final dir = await getApplicationDocumentsDirectory();
      final musicDir = Directory('${dir.path}/music');
      final bool isFirstDownload = !await musicDir.exists();
      
      if (!await musicDir.exists()) {
        await musicDir.create(recursive: true);
        final files = await musicDir.list().toList();
        debugPrint('Files in music/: $files');
      } else {
        debugPrint('music/ folder does not exist');
      }
      if (isFirstDownload) {
        BotToast.showText(text: 'Download a music...');
      }
      
//check a function delete tracks
      
      final forceUpdate = AppConfigService().forceUpdate;
      final reason = AppConfigService().musicReason;
      if (forceUpdate) {
        await _showDeleteDialog(reason, context);
        await _downloadAllMusic(context);
        //rm flag as don't remove music on the other try
        await _resetForceUpdateFlag();
        return;
      }

//check a background Music
      final bgFiles = await _getFileList('bg');
      if (bgFiles.isNotEmpty) {
        for (var file in bgFiles) {
          final fileName = file['name'];
          final dir = await getApplicationDocumentsDirectory();
          final localFile = File('${dir.path}/music/$fileName');
          if (!await localFile.exists()) {
            await _downloadFileViaWorker('bg', fileName);
          }
        }
        _tracks = bgFiles.map((file) => file['name'] as String).toList();
        await _playRandomTrack();
      }

//check a spin music 
      final spinFiles = await _getFileList('spin');
      if (spinFiles.isNotEmpty) {
        final fileName = spinFiles.first['name'];
        final justFileName = fileName.split('/').last;
        final dir = await getApplicationDocumentsDirectory();
        final localFile = File('${dir.path}/music/$fileName');
        if (!await localFile.exists()) {
          _spinSoundPath = await _downloadFileViaWorker('spin', fileName);
        } else {
          _spinSoundPath = localFile.path;
        }
      }

//check a win music 
      final winFiles = await _getFileList('win');
      if (winFiles.isNotEmpty) {
        final fileName = winFiles.first['name'];
        final justFileName = fileName.split('/').last;
        final dir = await getApplicationDocumentsDirectory();
        final localFile = File('${dir.path}/music/$fileName');
        if (!await localFile.exists()) {
          _winSoundPath = await _downloadFileViaWorker('win', fileName);
        } else {
          _winSoundPath = localFile.path;
        }
      }
       if (isFirstDownload && _tracks.isNotEmpty) {
          BotToast.showText(text: 'Music was downloaded');
        }
      //logs temporary 
      debugPrint('📁 BG Files: $bgFiles');
debugPrint('📁 Spin Files: $spinFiles');
debugPrint('📁 Win Files: $winFiles');
debugPrint('📁 Spin path: $_spinSoundPath');
debugPrint('📁 Win path: $_winSoundPath');

    } catch (e) {
      BotToast.showText(text: 'Error downloaded a music');
      debugPrint('Music service error: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> _getFileList(String type) async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfigService().workerUrl}/music?action=check&type=$type'),
      );
      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(jsonDecode(response.body));
      }
    } catch (e) {
      debugPrint('Failed to get file list: $e');
    }
    return [];
  }

  static Future<String?> _downloadFileViaWorker(String type, String fileName) async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfigService().workerUrl}/music?action=download&type=$type&file=$fileName'),
      );
      debugPrint('Worker status: ${response.statusCode}');

      if (response.statusCode != 200) {
        return null;
      }

      final dir = await getApplicationDocumentsDirectory();
      final musicDir = Directory('${dir.path}/music');

      final justFileName = fileName.split('/').last;
      final file = File('${musicDir.path}/$justFileName');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(response.bodyBytes);

      debugPrint('Saved ${file.path}');

      return file.path;
    } catch (e) {
      debugPrint('Failed to download: $e');
      return null;
    }
  }
    

  static Future<void> _playRandomTrack() async {
    if (_tracks.isEmpty) return;
    
    final random = Random();
    _currentTrackIndex = random.nextInt(_tracks.length);
    final fullTrackName = _tracks[_currentTrackIndex];
    final justFileName = fullTrackName.split('/').last;
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/music/$justFileName');

    if (await file.exists()) {
      await _bgPlayer.play(DeviceFileSource(file.path));
      _bgPlayer.setVolume(1.0);
      _isPlaying = true;

      _bgPlayer.onPlayerComplete.listen((event) {
        debugPrint('rack ended, playing next...');
        _playRandomTrack();
      });
    } else {
      debugPrint('File not found: $justFileName');
    }
  }

  static Future<void> playSpinSound() async {
    if (_spinSoundPath != null) {
      await _sfxPlayer.play(DeviceFileSource(_spinSoundPath!));
      _sfxPlayer.setVolume(1.0);
    }
  }

  static Future<void> playWinSound() async {
    if (_winSoundPath != null) {
      await _sfxPlayer.play(DeviceFileSource(_winSoundPath!));
      _sfxPlayer.setVolume(1.0);
    }
  }

  static Future<void> setBackgroundVolume(double volume) async {
    await _bgPlayer.setVolume(volume);
  }

  static Future<void> stopMusic() async {
    await _bgPlayer.stop();
    await _sfxPlayer.stop();
    _isPlaying = false;
  }

  static void dispose() {
    _bgPlayer.dispose();
    _sfxPlayer.dispose();
  }


  static Future<void> _showDeleteDialog(String reason, BuildContext context) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF2A1A3A), Color(0xFF1A1A2E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
                BoxShadow(
                  color: Color(0xFFB874EC).withOpacity(0.2),
                  blurRadius: 20,
                  spreadRadius: -5,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 48),
                const SizedBox(height: 16),
                const Text(
                  'Update a music',
                  style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text(
                  reason,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: BaseAnimatedButton(
                    text: 'Continue',
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    gradientColors: [Color(0xFFB874EC), Color(0xFF7D41B8)],
                    textColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static Future<void> _resetForceUpdateFlag() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('force_update_done', true);
  }

  static Future<void> _downloadAllMusic(BuildContext context) async {
    final dir = await getApplicationDocumentsDirectory();
    final musicDir = Directory('${dir.path}/music');
    if (await musicDir.exists()) {
      await musicDir.delete(recursive: true);
    }
    await loadMusic(context: context);
  }

}
