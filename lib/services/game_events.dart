import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/material.dart';

import 'package:wheel_of_fortune/services/database_service.dart';
import 'package:wheel_of_fortune/services/user_id_service.dart';
import 'package:wheel_of_fortune/services/app_config_service.dart';
import 'package:wheel_of_fortune/services/game_message.dart';
import 'package:wheel_of_fortune/services/routing.dart';
import 'package:wheel_of_fortune/services/logger.dart';


final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class GameEventsService {
  static final GameEventsService _instance = GameEventsService._internal();
  factory GameEventsService() => _instance;
  GameEventsService._internal();

  // ===== ВСЁ В ПАМЯТИ (быстро) =====
  int _totalSpins = 0;
  int _sessionSpins = 0;
  int _spinsSinceLastNotification = 0;
  DateTime? _sessionStartTime;
  int _sessionSeconds = 0; 
  int _totalTimeBeforeSession = 0; // Добавили переменную для накопленного времени
  bool _initialized = false;

  // Для накопления данных перед сохранением в локальную БД
  final List<Map<String, dynamic>> _pendingSpins = [];
  bool _hasChanges = false;

  static const String _keyTotalSpins = 'game_total_spins';
  static const String _keyTotalSessions = 'game_total_sessions';
  static const String _keyTotalTime = 'game_total_time_seconds';
  
  static const int _notificationInterval = 10;
  static const int _saveThreshold = 5; // Сохраняем в локальную базу каждые 5 спинов
 // static const int _syncInterval = 5;  // Шлем на сервер тоже каждые 5 спинов для подстраховки

  // ===== ИНИЦИАЛИЗАЦИЯ =====
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    final prefs = await SharedPreferences.getInstance();
    
    _totalSpins = prefs.getInt(_keyTotalSpins) ?? 0;
    _totalTimeBeforeSession = prefs.getInt(_keyTotalTime) ?? 0; // Исправили ключ для времени

    _sessionSpins = 0;
    _spinsSinceLastNotification = _totalSpins % _notificationInterval;
    _sessionStartTime = DateTime.now();
    _sessionSeconds = 0;

    Log.i('📊 GameEventsService initialized. Total spins: $_totalSpins');

    // КЛЮЧЕВОЕ ОБНОВЛЕНИЕ: Мгновенная синхронизация с сервером при входе в прогу!
    _sendStatsAsync('APP_INIT_SYNC', false);
  }
  
  // ===== УЧЁТ СПИНОВ =====
  Future<void> recordSpin(String sector, bool isWin) async {
    // 1. Работаем с памятью (быстро)
    _totalSpins++;
    _sessionSpins++;
    _spinsSinceLastNotification++;
    _hasChanges = true;

    // 2. Считаем время сессии
    _sessionSeconds = DateTime.now().difference(_sessionStartTime!).inSeconds;

    // 3. Накопливаем для локальной sqlite базы
    _pendingSpins.add({
      'sector': sector,
      'isWin': isWin,
      'timestamp': DateTime.now().toIso8601String(),
    });

    Log.i('🎡 Spin #$_totalSpins (session: $_sessionSpins). Записано в память.');

    // 4. Проверяем уведомление (оставили как было)
    if (_spinsSinceLastNotification >= _notificationInterval) {
      _spinsSinceLastNotification = 0;
      _showNotification();
    }

    // 5. Сохраняем в локальную SQLite базу пачкой
    if (_pendingSpins.length >= _saveThreshold) {
      await _flushPendingSpins();
    }

    // 6. Мгновенно сохраняем счётчики в SharedPreferences телефона (защита от вылета)
    await _saveCounters();

    // 7. КЛЮЧЕВОЕ ОБНОВЛЕНИЕ: Отправляем на сервер по новому интервалу (_syncInterval = 5)
    final syncInterval = AppConfigService().syncInterval;
    if (_totalSpins % syncInterval == 0) {
     Log.i('Spins have $syncInterval accumulated, background synchronization with the server...');
      _sendStatsAsync(sector, isWin);
    }
  }

  // ===== СОХРАНЕНИЕ ПАЧКОЙ В ЛОКАЛЬНУЮ БД =====
  Future<void> _flushPendingSpins() async {
    if (_pendingSpins.isEmpty) return;
    
    try {
      final db = DatabaseService.instance;
      for (var spin in _pendingSpins) {
        await db.saveSpin(spin['sector'], spin['isWin']);
      }
      Log.i(' Saved ${_pendingSpins.length} spins to DB');
      _pendingSpins.clear();
    } catch (e, st) {
      Log.h(e, st, 'Failed to save spins to local DB:');
    }
  }

  // ===== СОХРАНЕНИЕ ТОЛЬКО СЧЁТЧИКОВ В ПАМЯТЬ ТЕЛЕФОНА =====
  Future<void> _saveCounters() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyTotalSpins, _totalSpins);
    await prefs.setInt(_keyTotalTime, _totalTimeBeforeSession + _sessionSeconds);
  }

  // ===== УЧЁТ СЕКТОРОВ =====
  Future<void> recordSector(String name) async {
    DatabaseService.instance.saveSector(name);
    Log.d(' Sector recorded: $name');
  }

  // ===== УВЕДОМЛЕНИЯ =====
  void _showNotification() {
    if (_totalSpins % (_notificationInterval * 2) == 0) {
      final messages = [
        '🎯 $_totalSpins spins! Keep going!',
        '🔥 $_totalSpins spins! You\'re on fire!',
        '💪 $_totalSpins spins already!',
      ];
      final message = messages[_totalSpins ~/ _notificationInterval % messages.length];
      
      Log.i('📢 NOTIFICATION: $message');
      _showLightNotification(message);
    }
  }

  void _showLightNotification(String message) {
    final context = _getContext();
    if (context != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.purple.shade700,
        ),
      );
    }
  }

  // ===== АСИНХРОННАЯ ОТПРАВКА НА СЕРВЕР CLOUDFLARE =====
  Future<void> _sendStatsAsync(String sector, bool isWin) async {
    try {
      final userInfo = await UserIdService.getUserInfo();
      final currentTotalTime = _totalTimeBeforeSession + _sessionSeconds;

      final nickname = RoutingService().nickname ?? 'Unknown';
      final isGuest = RoutingService().isGuest;
      final isRegistered = RoutingService().isRegistered;

      final data = {
        'userId': userInfo['userId'],
        'deviceId': userInfo['deviceId'],
        'nickname': nickname,
        'isGuest': isGuest,
        'isRegistered': isRegistered,
        'userType': isGuest ? 'guest' : (isRegistered ? 'registered' : 'Unknown'),

        'totalSpins': _totalSpins,
        'sessionSpins': _sessionSpins,
        'sessionDuration': currentTotalTime, // Передаем общее суммарное время игры
        'sector': sector,
        'isWin': isWin,
        'timestamp': DateTime.now().toIso8601String(),
      };

      final response = await http.post(
        Uri.parse('${AppConfigService().workerUrl}/stats'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      ).timeout(const Duration(seconds: 4));


      if (response.statusCode == 200 || response.statusCode == 201) {
        Log.i('Server synchronized successfully! Status: ${response.statusCode}');
      } else {
        Log.e('Server accepted the request but responded with an error: ${response.statusCode}');
      }
    } on TimeoutException catch (e) {
      Log.w('First try sincronization failed. Try again');
      try {
        await Future.delayed(const Duration(seconds: 2));
        final response = await http.post(
          Uri.parse('${AppConfigService().workerUrl}/stats'),
          headers: {'Content-Type': 'application/json'},
        ).timeout(const Duration(seconds: 6));
      } catch (e, st) {
      Log.h(e, st, 'Background synchronization failed (no network), data saved locally');
      }
    }
  }

  // ===== ЗАВЕРШЕНИЕ СЕССИИ =====
  Future<void> endSession() async {
    await _flushPendingSpins();
    
    final prefs = await SharedPreferences.getInstance();
    final currentTotalTime = _totalTimeBeforeSession + _sessionSeconds;
    await prefs.setInt(_keyTotalTime, currentTotalTime);
    
    final sessions = prefs.getInt(_keyTotalSessions) ?? 0;
    await prefs.setInt(_keyTotalSessions, sessions + 1);
    
    await prefs.setInt(_keyTotalSpins, _totalSpins);

    Log.i(' Session ended saved: ${_sessionSeconds}s, $_sessionSpins spins');
  }

  // ===== ГЕТТЕРЫ =====
  int get totalSpins => _totalSpins;
  int get sessionSpins => _sessionSpins;
  int get sessionSeconds => _sessionSeconds;

  BuildContext? _getContext() {
    try {
      return navigatorKey.currentContext;
    } catch (e) {
      return null;
    }
  }

  // ===== СБРОС (для тестов) =====
  Future<void> resetStats() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyTotalSpins);
    await prefs.remove(_keyTotalSessions);
    await prefs.remove(_keyTotalTime);
    _totalSpins = 0;
    _sessionSpins = 0;
    _totalTimeBeforeSession = 0;
    _pendingSpins.clear();
    Log.w(' Stats reset');
  }

  void dispose() {
    _initialized = false;
    endSession();
  }
}
