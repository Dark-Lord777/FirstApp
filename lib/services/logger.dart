import 'package:flutter/foundation.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'package:wheel_of_fortune/services/database_service.dart';

class SqfliteTalkerObserver extends TalkerObserver {
  static bool isSaving = false;

  @override
  void onError(TalkerError err) =>
      _save('ERROR', err.message, err.stackTrace?.toString());

  @override
  void onException(TalkerException exc) =>
      _save('EXCEPTION', exc.message, exc.stackTrace?.toString());

  @override
  void onLog(TalkerData log) {
    final level = log.logLevel;
    if (level == LogLevel.error ||
        level == LogLevel.warning ||
        level == LogLevel.critical) {
      _save(log.title ?? 'LOG', log.message ?? '');
    }
  }

  void _save(String title, String? message, [String? stack]) {
    if (isSaving) {
      debugPrint('Log saving already in progress, skipping: $title');
      return;
    }
    isSaving = true;
    try {
      final fullMessage = message ?? '';
      final details = stack ?? '';
      DatabaseService.instance.saveLogEvent(title, fullMessage, details);
    } catch (e) {
      debugPrint('Failed to save log through observer: $e');
    } finally {
      isSaving = false;
    }
  }
}

class Log {
  static bool _logsEnabled = false;
  static bool get logsEnabled => _logsEnabled;

  // 👇 ТУТ ДОЛЖЕН БЫТЬ ТОЛЬКО ОДИН!
  static final ValueNotifier<bool> logsEnabledNotifier = ValueNotifier(false);

  static final _talker = TalkerFlutter.init(
    observer: SqfliteTalkerObserver(),
    settings: TalkerSettings(enabled: true),
    logger: TalkerLogger(
      settings: TalkerLoggerSettings(enableColors: kDebugMode),
    ),
  );

  static String _caller() {
    final trace = StackTrace.current.toString();
    final lines = trace.split('\n');
    for (final line in lines) {
      final clean = line.trim();
      if (clean.contains('package:wheel_of_fortune/services/logger.dart')) continue;
      if (clean.contains('<asynchronous suspension>')) continue;
      if (clean.contains('package:wheel_of_fortune/')) {
        return clean.replaceFirst(RegExp(r'^#\d+\s+'), '').trim();
      }
    }
    return 'unknown caller';
  }

  static void dev(dynamic msg) {
    if (kDebugMode) {
      _talker.debug('[DEV] $msg\n📍 ${_caller()}');
    }
  }

  static void d(dynamic msg) {
    if (kDebugMode) {
      _talker.debug('$msg\n📍 ${_caller()}');
    }
  }

  static void i(dynamic msg) {
    _talker.info('$msg\n📍 ${_caller()}');
  }

  static void w(dynamic message) {
    _talker.warning('$message\n📍 ${_caller()}');
  }

  static void e(dynamic message) {
    _talker.error('$message\n📍 ${_caller()}');
  }

  static void c(dynamic message) {
    _talker.critical('$message\n📍 ${_caller()}');
  }

  static void h(Object error, StackTrace? stackTrace, [String? message]) {
    _talker.handle(error, stackTrace, '$message\n📍 ${_caller()}');
  }

  static List<TalkerData> get history => _talker.history;
  static Talker get instance => _talker;

  static void clearHistory() {
    _talker.history.clear();
  }

  static void setLogsEnabled(bool enabled) {
    _logsEnabled = enabled;
    logsEnabledNotifier.value = enabled; // 👈 ТЕПЕРЬ РАБОТАЕТ
  }
}
