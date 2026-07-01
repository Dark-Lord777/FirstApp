import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:wheel_of_fortune/services/app_config_service.dart';
import 'package:wheel_of_fortune/widgets/base_anim_btn.dart';

class MusicService {

  // players

  static final AudioPlayer _backgroundPlayer = AudioPlayer();
  static final AudioPlayer _effectPlayer = AudioPlayer();

  // state

  static bool _initialized = false;
  static bool _musicLoaded = false;
  static bool _isDownloading = false;

  static String _musicVersion = "";

  static final Random _random = Random();

  // local cache

  static final List<String> _backgroundTracks = [];

  static final Map<String, String> _sounds = {};

  // ============================================================
  // Public API
  // ============================================================

  static Future<void> initialize({
    required BuildContext context,
  }) async {

    if (_initialized) {
      return;
    }

    _initialized = true;

    _backgroundPlayer.onPlayerComplete.listen((_) {
      _playRandomBackground();
    });

    await loadMusic(context: context);
  }

  static Future<void> loadMusic({
    required BuildContext context,
  }) async {

    if (_musicLoaded) {
      debugPrint("Music already loaded");
      return;
    }

    if (_isDownloading) {
      debugPrint("Music download already running");
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

      await _checkForceUpdate(context);

      await _loadBackgroundMusic();

      await _loadEffects();

      _musicLoaded = true;

      if (firstStart && _backgroundTracks.isNotEmpty) {

        BotToast.showText(
          text: "Music downloaded",
        );
      }

      debugPrint("Music initialized");

    } catch (e) {

      debugPrint(e.toString());

      BotToast.showText(
        text: "Music loading failed",
      );

    } finally {

      _isDownloading = false;

    }
  }

  static Future<void> play(String sound) async {

    final path = _sounds[sound];

    if (path == null) {
      debugPrint("Unknown sound: $sound");
      return;
    }

    try {

      await _effectPlayer.stop();

      await _effectPlayer.play(
        DeviceFileSource(path),
      );

      await _effectPlayer.setVolume(1);

    } catch (e) {

      debugPrint(e.toString());

    }

  }

  static Future<void> playSpinSound() async {

    await play("spin");

  }

  static Future<void> playWinSound() async {

    await play("win");

  }

  static Future<void> stopSpinSound() async {

    await _effectPlayer.stop();

  }

  static Future<void> stopMusic() async {

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

  // Background music

  static Future<void> _loadBackgroundMusic() async {

    _backgroundTracks.clear();

    final files = await _getFileList("bg");

    if (files.isEmpty) {
      debugPrint("No background music");
      return;
    }

    for (final item in files) {

      final name = item["name"] as String;

      final path = await _ensureDownloaded(
        type: "bg",
        fileName: name,
      );

      if (path != null) {
        _backgroundTracks.add(path);
      }

    }

    if (_backgroundTracks.isNotEmpty) {
      await _playRandomBackground();
    }

  }

  static Future<void> _playRandomBackground() async {

    if (_backgroundTracks.isEmpty) {
      return;
    }

    final path =
        _backgroundTracks[_random.nextInt(_backgroundTracks.length)];

    final file = File(path);

    if (!await file.exists()) {

      debugPrint("Missing music file");

      return;

    }

    try {

      await _backgroundPlayer.stop();

      await _backgroundPlayer.play(
        DeviceFileSource(path),
      );

      await _backgroundPlayer.setVolume(1);

    } catch (e) {

      debugPrint(e.toString());

    }

  }

  // Effects

  static Future<void> _loadEffects() async {

    await _loadEffect("spin");
    await _loadEffect("win");

  }

  static Future<void> _loadEffect(
    String type,
  ) async {

    final files = await _getFileList(type);

    if (files.isEmpty) {

      debugPrint("$type effect not found");

      return;

    }

    final name = files.first["name"] as String;

    final path = await _ensureDownloaded(

      type: type,

      fileName: name,

    );

    if (path != null) {

      _sounds[type] = path;

    }

  }

  // Download

  static Future<String?> _ensureDownloaded({

    required String type,

    required String fileName,

  }) async {

    final directory = await _musicDirectory();

    final localName = fileName.split("/").last;

    final file = File(
      "${directory.path}/$localName",
    );

    if (await file.exists()) {

      return file.path;

    }

    return await _downloadFile(

      type: type,

      fileName: fileName,

    );

  }

  static Future<String?> _downloadFile({

    required String type,

    required String fileName,

  }) async {

    try {

      final response = await http.get(

        Uri.parse(
          "${AppConfigService().workerUrl}"
          "/music?action=download"
          "&type=$type"
          "&file=$fileName",
        ),

      );

      if (response.statusCode != 200) {

        debugPrint(
          "Download failed $fileName",
        );

        return null;

      }

      final directory = await _musicDirectory();

      final localName = fileName.split("/").last;

      final file = File(
        "${directory.path}/$localName",
      );

      await file.parent.create(
        recursive: true,
      );

      await file.writeAsBytes(
        response.bodyBytes,
      );

      debugPrint("Downloaded $localName");

      return file.path;

    } catch (e) {

      debugPrint(e.toString());

      return null;

    }

  }

  static Future<List<Map<String, dynamic>>> _getFileList(
    String type,
  ) async {

    try {

      final response = await http.get(

        Uri.parse(
          "${AppConfigService().workerUrl}"
          "/music?action=check"
          "&type=$type",
        ),

      );

      if (response.statusCode != 200) {

        return [];

      }

      return List<Map<String, dynamic>>.from(

        jsonDecode(response.body),

      );

    } catch (e) {

      debugPrint(e.toString());

      return [];

    }

  }

  // Cache

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

  // Force update

  static Future<void> _checkForceUpdate(
    BuildContext context,
  ) async {

    if (!AppConfigService().forceUpdate) {
      return;
    }

    final reason = AppConfigService().musicReason;

    await _showDeleteDialog(
      reason,
      context,
    );

    await _deleteAllMusic();

    _backgroundTracks.clear();
    _sounds.clear();

  }

  static Future<void> _deleteAllMusic() async {

    final dir = await _musicDirectory();

    if (await dir.exists()) {

      await dir.delete(
        recursive: true,
      );

    }

    await dir.create(
      recursive: true,
    );

  }

  // Debug

  static void printState() {

    debugPrint("----------- MUSIC -----------");

    debugPrint("initialized : $_initialized");

    debugPrint("loaded      : $_musicLoaded");

    debugPrint("version     : $_musicVersion");

    debugPrint("tracks      : ${_backgroundTracks.length}");

    debugPrint("effects     : ${_sounds.keys.toList()}");

    debugPrint("-----------------------------");

  }

  // Dialog

  static Future<void> _showDeleteDialog(
    String reason,
    BuildContext context,
  ) async {

    return showDialog(

      context: context,

      barrierDismissible: false,

      builder: (_) {

        return Dialog(

          backgroundColor: Colors.transparent,

          child: Container(

            padding: const EdgeInsets.all(24),

            decoration: BoxDecoration(

              gradient: const LinearGradient(

                colors: [

                  Color(0xFF2A1A3A),

                  Color(0xFF1A1A2E),

                ],

              ),

              borderRadius: BorderRadius.circular(24),

            ),

            child: Column(

              mainAxisSize: MainAxisSize.min,

              children: [

                const Icon(
                  Icons.music_note,
                  color: Colors.orange,
                  size: 46,
                ),

                const SizedBox(height: 16),

                const Text(

                  "Music update",

                  style: TextStyle(

                    color: Colors.white,

                    fontWeight: FontWeight.bold,

                    fontSize: 22,

                  ),

                ),

                const SizedBox(height: 14),

                Text(

                  reason,

                  textAlign: TextAlign.center,

                  style: const TextStyle(

                    color: Colors.white70,

                    fontSize: 16,

                  ),

                ),

                const SizedBox(height: 20),

                SizedBox(

                  width: double.infinity,

                  child: BaseAnimatedButton(

                    text: "Continue",

                    onPressed: () {

                      Navigator.pop(context);

                    },

                    gradientColors: const [

                      Color(0xFFB874EC),

                      Color(0xFF7D41B8),

                    ],

                    textColor: Colors.white,

                  ),

                ),

              ],

            ),

          ),

        );

      },

    );

  }

}

