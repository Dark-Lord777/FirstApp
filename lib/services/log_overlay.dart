import 'dart:async';
import 'package:flutter/material.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'package:wheel_of_fortune/services/logger.dart';
import 'package:wheel_of_fortune/services/app_config_service.dart';

class LogOverlay extends StatefulWidget {
  final Widget child;
  const LogOverlay({super.key, required this.child});

  @override
  State<LogOverlay> createState() => _LogOverlayState();
}

class _LogOverlayState extends State<LogOverlay> {
  final ScrollController _scrollController = ScrollController();
  List<TalkerData> _logs = [];
  StreamSubscription? _talkerSubscription;

  @override
  void initState() {
    super.initState();
    _loadExistingLogs();
    
    _talkerSubscription = Log.instance.stream.listen((_) {
      if (AppConfigService().developerTools && Log.logsEnabledNotifier.value) {
        _refreshLogs();
      }
    });
  }

  @override
  void dispose() {
    _talkerSubscription?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _loadExistingLogs() {
    _logs = List.from(Log.history);
  }

  void _refreshLogs() {
    if (!mounted) return;
    setState(() {
      _logs = List.from(Log.history);
    });

    // Мягко скроллим вниз к самому свежему логу
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        ValueListenableBuilder<bool>(
          valueListenable: Log.logsEnabledNotifier,
          builder: (context, enabled, _) {
            if (enabled && AppConfigService().developerTools) {
              return _buildOverlay();
            }
            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }

  Widget _buildOverlay() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      height: MediaQuery.of(context).size.height * 0.7, 
      child: Material( // Добавлено, чтобы текстовые стили и жесты сидели на валидной подложке
        color: Colors.transparent,
        child: Container(
          color: Colors.black.withOpacity(0.95),
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: _logs.isEmpty
                    ? const Center(
                        child: Text(
                          'Logs are empty',
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        // reverse: false (по умолчанию) — теперь скролл послушный!
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        itemCount: _logs.length,
                        itemBuilder: (context, index) {
                          return _buildLogTile(_logs[index]);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.purple.shade900,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.bug_report, color: Colors.white, size: 20),
          const SizedBox(width: 12),
          Text(
            'Logs (${_logs.length})',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white, size: 20),
            onPressed: _refreshLogs,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
            onPressed: () {
              Log.clearHistory();
              setState(() => _logs = []);
            },
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white, size: 22),
            onPressed: () {
              Log.setLogsEnabled(false);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLogTile(TalkerData log) {
    Color? bgColor;
    Color? textColor;
    String prefix;

    if (log is TalkerLog) {
      final level = log.logLevel;
      if (level == LogLevel.error || level == LogLevel.critical) {
        bgColor = Colors.red.withOpacity(0.15);
        textColor = Colors.red.shade300;
        prefix = '❌ ERROR';
      } else if (level == LogLevel.warning) {
        bgColor = Colors.orange.withOpacity(0.12);
        textColor = Colors.orange.shade300;
        prefix = '⚠️ WARN';
      } else {
        bgColor = Colors.grey.withOpacity(0.06);
        textColor = Colors.blue.shade300;
        prefix = 'ℹ️ INFO';
      }
    } else if (log is TalkerError || log is TalkerException) {
      bgColor = Colors.red.withOpacity(0.2);
      textColor = Colors.red.shade300;
      prefix = '💥 EXCEPTION';
    } else {
      bgColor = Colors.grey.withOpacity(0.06);
      textColor = Colors.grey.shade400;
      prefix = '📝 LOG';
    }

    final message = log.message?.toString() ?? '';
    final stackTrace = _getStackTrace(log);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: textColor.withOpacity(0.2), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$prefix ',
                style: TextStyle(
                  color: textColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
          if (stackTrace.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                stackTrace,
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 10,
                  fontFamily: 'monospace',
                  height: 1.3,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getStackTrace(TalkerData log) {
    if (log is TalkerError || log is TalkerException) {
      return log.stackTrace?.toString() ?? '';
    }
    if (log is TalkerLog && log.logLevel == LogLevel.error) {
      return log.stackTrace?.toString() ?? '';
    }
    return '';
  }
}
