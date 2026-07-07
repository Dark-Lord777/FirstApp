import 'dart:async';
import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:wheel_of_fortune/services/logger.dart';


class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

    static bool _isSavingLog = false;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('analytics.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE spins (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sector TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        is_win INTEGER DEFAULT 0
      )
    ''');
    
    await db.execute('''
      CREATE TABLE sectors (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        added_at TEXT NOT NULL
      )
    ''');
    
    await db.execute('''
      CREATE TABLE events (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        event_type TEXT NOT NULL,
        event_data TEXT,
        timestamp TEXT NOT NULL
      )
    ''');
  }
  
  Future<void> _upgradeDB(Database db, int oldversion, int newVersion) async {
    if (oldversion < 2) {
      await db.execute('DROP TABLE IF EXISTS event');
      await db.execute('''
      CREATE TABLE events (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        event_type TEXT NOT NULL,
        event_data TEXT,
        timestamp TEXT NOT NULL 
      )
      ''');
    }
  }

  // Сохранить выигрыш
  Future<void> saveSpin(String sector, bool isWin) async {
    unawaited(
    database.then((db) => db.insert('spins', {
    'sector': sector,
    'timestamp': DateTime.now().toIso8601String(),
    'is_win': isWin ? 1 : 0,
  }))
  );
}

  // Сохранить сектор
  Future<void> saveSector(String name) async {
    final db = await database;
    await db.insert('sectors', {
      'name': name,
      'added_at': DateTime.now().toIso8601String(),
    });
  }

  // Получить все данные для отправки
  Future<Map<String, dynamic>> getAllAnalytics() async {
    final db = await database;
    final spins = await db.query('spins');
    final sectors = await db.query('sectors');
    final events = await db.query('events');
    
    return {
      'spins': spins,
      'sectors': sectors,
      'events': events,
      'device_id': await _getDeviceId(),
    };
  }

  // Очистить после отправки
  Future<void> clearAfterSync() async {
    final db = await database;
    await db.delete('spins');
    await db.delete('sectors');
    await db.delete('events');
  }

  // Получить ID устройства
  Future<String> _getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    String? deviceId = prefs.getString('device_id');
    if (deviceId == null) {
      deviceId = DateTime.now().millisecondsSinceEpoch.toString();
      await prefs.setString('device_id', deviceId);
    }
    return deviceId;
  }
  // В конец класса DatabaseService
  
  Future<void> saveLogEvent(String level, String message, [String? details]) async {
    if (_isSavingLog) {
      debugPrint('Log save already in progress, skipping');
      return;
    }
    _isSavingLog = true;

    try {
      final db = await database;
      final logData = jsonEncode({
          'message': message,
          'details': details ?? '',
        });

        await db.insert('events', {
          'event_type': 'LOG_$level',
          'event_data': logData,
          'timestamp': DateTime.now().toIso8601String(),
        });
      } catch (e) {
        //DO NOT CALL Log.h() HERE! ONLY debugPrint, otherwise it will lead to recursion and crash the program.
        debugPrint('Failed to save log to local DB $e');
      } finally {
      _isSavingLog = false;
      }
    }
  
// ===== ОЧИСТКА ВСЕХ ДАННЫХ =====
Future<void> clearAllData() async {
  try {
    final db = await database;
    await db.delete('spins');
    await db.delete('sectors');
    await db.delete('events');
    debugPrint('🗑️ All database tables cleared');
  } catch (e) {
  debugPrint('Error clearing database: $e');
    }
  }
}
