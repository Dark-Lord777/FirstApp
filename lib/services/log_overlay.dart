import 'package:flutter/material.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'package:wheel_of_fortune/services/logger.dart';

class LogOverlay extends StatefulWidget {
  final Widget child;
  const LogOverlay({super.key, required this.child});

  @override
  State<LogOverlay> createState() => _LogOverlayState();
}

class _LogOverlayState extends State<LogOverlay> {
  final ScrollController _scrollController = ScrollController();
  List<TalkerData> _logs = [];

  @override
  void initState() {
    super.initState();
    _refreshLogs();
  }

  void _refreshLogs() {
    setState(() {
      _logs = Log.history.reversed.toList();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
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
          if (enabled) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
            _refreshLogs();
          });
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
      height: MediaQuery.of(context).size.height * 0.5, 
      child: Container(
        color: Colors.black.withOpacity(0.95),
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _logs.isEmpty
                  ? const Center(
                      child: Text(
                        'Логов нет',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      reverse: true,
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
            'Логи (${_logs.length})',
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
              Log.setLogsEnabled(false); // 👈 ВЫКЛЮЧАЕМ
              setState(() {});
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
