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
  int _sessionSeconds = 0; // Считаем вручную, без таймера
  bool _initialized = false;

  // Для накопления данных перед сохранением
  final List<Map<String, dynamic>> _pendingSpins = [];
  bool _hasChanges = false;

  static const String _keyTotalSpins = 'game_total_spins';
  static const String _keyTotalSessions = 'game_total_sessions';
  static const String _keyTotalTime = 'game_total_time_seconds';
  static const int _notificationInterval = 10;
  static const int _saveThreshold = 5; // Сохраняем в базу каждые 5 спинов

  // ===== ИНИЦИАЛИЗАЦИЯ (быстро) =====
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    final prefs = await SharedPreferences.getInstance();
    
    _totalSpins = prefs.getInt(_keyTotalSpins) ?? 0;
    _sessionSpins = 0;
    _spinsSinceLastNotification = _totalSpins % _notificationInterval;
    _sessionStartTime = DateTime.now();
    _sessionSeconds = 0;

    debugPrint('📊 GameEventsService initialized');
  }

  // ===== УЧЁТ СПИНОВ (оптимизировано) =====
  Future<void> recordSpin(String sector, bool isWin) async {
    // 1. Работаем только с памятью (быстро)
    _totalSpins++;
    _sessionSpins++;
    _spinsSinceLastNotification++;
    _hasChanges = true;

    // 2. Считаем время сессии (без таймера)
    _sessionSeconds = DateTime.now().difference(_sessionStartTime!).inSeconds;

    // 3. Накопливаем для базы
    _pendingSpins.add({
      'sector': sector,
      'isWin': isWin,
      'timestamp': DateTime.now().toIso8601String(),
    });

    debugPrint('🎡 Spin #$_totalSpins (session: $_sessionSpins)');

    // 4. Проверяем уведомление (быстро)
    if (_spinsSinceLastNotification >= _notificationInterval) {
      _spinsSinceLastNotification = 0;
      // Не ждём уведомление, запускаем асинхронно
      _showNotification();
    }

    // 5. Сохраняем в базу пачкой (не каждый спин!)
    if (_pendingSpins.length >= _saveThreshold) {
      await _flushPendingSpins();
    }

    // 6. Сохраняем только счётчики (быстро)
    await _saveCounters();

    // 7. Отправляем статистику (не ждём)
    _sendStatsToServer(sector, isWin);
  }

  // ===== СОХРАНЕНИЕ ПАЧКОЙ =====
  Future<void> _flushPendingSpins() async {
    if (_pendingSpins.isEmpty) return;
    
    try {
      final db = DatabaseService.instance;
      for (var spin in _pendingSpins) {
        await db.saveSpin(spin['sector'], spin['isWin']);
      }
      _pendingSpins.clear();
      debugPrint('💾 Saved ${_pendingSpins.length} spins to DB');
    } catch (e) {
      debugPrint('⚠️ Failed to save spins: $e');
    }
  }

  // ===== СОХРАНЕНИЕ ТОЛЬКО СЧЁТЧИКОВ =====
  Future<void> _saveCounters() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyTotalSpins, _totalSpins);
  }

  // ===== УЧЁТ СЕКТОРОВ (оптимизировано) =====
  Future<void> recordSector(String name) async {
    // Сохраняем в базу, но не ждём
    DatabaseService.instance.saveSector(name);
    debugPrint('📝 Sector recorded: $name');
  }

  // ===== УВЕДОМЛЕНИЯ (лёгкие) =====
  void _showNotification() {
    // Проверяем в памяти, без SharedPreferences
    if (_totalSpins % (_notificationInterval * 2) == 0) {
      // Показываем только каждое второе уведомление (реже)
      final messages = [
        '🎯 $_totalSpins spins! Keep going!',
        '🔥 $_totalSpins spins! You\'re on fire!',
        '💪 $_totalSpins spins already!',
      ];
      final message = messages[_totalSpins ~/ _notificationInterval % messages.length];
      
      // Показываем через BotToast (легче, чем Dialog)
      // Используем BotToast.showText вместо GameMessage (тяжёлый)
      // Или просто выводим в debug
      debugPrint('📢 NOTIFICATION: $message');
      
      // Если хочешь диалог — показываем его, но редко
      _showLightNotification(message);
    }
  }

  void _showLightNotification(String message) {
    // Используем простой SnackBar (лёгкий)
    final context = _getContext();
    if (context != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.purple.shade700,
        ),
      );
    }
  }

  // ===== ОТПРАВКА НА СЕРВЕР (не блокируем) =====
  void _sendStatsToServer(String sector, bool isWin) {
    // Отправляем только если есть интернет и раз в 10 спинов
    if (_totalSpins % 10 != 0) return;
    
    // Запускаем без await
    _sendStatsAsync(sector, isWin);
  }

  Future<void> _sendStatsAsync(String sector, bool isWin) async {
    try {
      final userInfo = await UserIdService.getUserInfo();
      final data = {
        'userId': userInfo['userId'],
        'deviceId': userInfo['deviceId'],
        'totalSpins': _totalSpins,
        'sessionSpins': _sessionSpins,
        'sessionDuration': _sessionSeconds,
        'timestamp': DateTime.now().toIso8601String(),
      };

      await http.post(
        Uri.parse('${AppConfigService().syncUrl}/stats'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      ).timeout(const Duration(seconds: 3)); // Таймаут 3 секунды
    } catch (e) {
      debugPrint('Error $e');
      // Молча игнорируем ошибки
    }
  }

  // ===== ЗАВЕРШЕНИЕ СЕССИИ (сохраняем всё) =====
  Future<void> endSession() async {
    // 1. Сохраняем все накопленные спины
    await _flushPendingSpins();
    
    // 2. Сохраняем счётчики
    final prefs = await SharedPreferences.getInstance();
    final totalSeconds = prefs.getInt(_keyTotalTime) ?? 0;
    final newTotal = totalSeconds + _sessionSeconds;
    await prefs.setInt(_keyTotalTime, newTotal);
    
    final sessions = prefs.getInt(_keyTotalSessions) ?? 0;
    await prefs.setInt(_keyTotalSessions, sessions + 1);
    
    // 3. Сохраняем общее количество спинов
    await prefs.setInt(_keyTotalSpins, _totalSpins);

    debugPrint('📊 Session ended: ${_sessionSeconds}s, $_sessionSpins spins');
  }

  // ===== ПОЛУЧЕНИЕ СТАТИСТИКИ (быстро) =====
  int get totalSpins => _totalSpins;
  int get sessionSpins => _sessionSpins;
  int get sessionSeconds => _sessionSeconds;

  // ===== ВСПОМОГАТЕЛЬНЫЕ МЕТОДЫ =====
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
    _pendingSpins.clear();
    debugPrint('🔄 Stats reset');
  }

  void dispose() {
    _initialized = false;
    // Сохраняем всё при выходе
    endSession();
  }
}
