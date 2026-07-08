import 'package:flutter/material.dart';
import 'package:talker_flutter/talker_flutter.dart';

import 'package:wheel_of_fortune/services/logger.dart';
import 'package:wheel_of_fortune/services/routing.dart';
import 'package:wheel_of_fortune/services/music_service.dart';


class LogOverlay extends StatefulWidget {
  final Widget child;

  const LogOverlay({super.key, required this.child});

  @override
  State<LogOverlay> createState() => _LogOverlayState();
}

class _LogOverlayState extends State<LogOverlay> {
  bool _isLogVisible = false;
  final ScrollController _scrollController = ScrollController();
  List<TalkerData> _logs = [];

  int _pointerCount = 0;

  @override
  void initState() {
    super.initState();
    _logs = Log.history.reversed.toList();
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

  void _handleThreeFingerSwipe() {
    setState(() {
      _isLogVisible = !_isLogVisible;
      if (_isLogVisible) {
        _refreshLogs();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (event) {
        _pointerCount++;
      },
      onPointerUp: (event) {
        _pointerCount--;
      },
      child: GestureDetector(
      onVerticalDragUpdate: (details) {
        //if (details.pointerCount == 3) {
          //swipe up //but swipe down > 20
        if (_pointerCount >= 3 && details.delta.dy < -20) {
          _handleThreeFingerSwipe();
          }
       // }
      },
      child: Stack(
        children: [
          widget.child,
          if (_isLogVisible) 
          _buildLogOverlay(),
        ],
      ),
      ),
    );
  }

  Widget _buildLogOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.85),
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _logs.isEmpty
                ? const Center(
                child: Text(
                  'Logs are empty',
                  style: TextStyle(color: Colors.grey),
                ),
              )
              : ListView.builder(
                controller: _scrollController,
                reverse: true,
                itemCount: _logs.length,
                itemBuilder: (context, index) {
                  final log = _logs[index];
                  return _buildLogTile(log);
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
        border: Border(
          bottom: BorderSide(color: Colors.purple.shade400),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.bug_report, color: Colors.white),
          const SizedBox(width: 12),
          Text(
            'Logs ($_logs.length)',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              MusicService.playClick();
              _refreshLogs();
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () {
              MusicService.playClick();
              Log.clearHistory();
            /*
              setState(() {
                _logs = [];
              });
              */ 
            },
          ),
          IconButton(
            icon: Icon(Icons.close, color: Colors.white),
            onPressed: () {
              MusicService.playClick();
              _isLogVisible = false;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLogTile(TalkerData log) {
    Color? color;
    String? prefix;

    if (log is TalkerLog) {
      final level = log.logLevel;
      if (level == LogLevel.error) {
        color = Colors.red.shade300;
        prefix = 'ERROR';
      } else if (level == LogLevel.warning) {
        color = Colors.orange.shade300;
        prefix = "WARN";
      } else if (level == LogLevel.critical) {
        color = Colors.red.shade900;
        prefix = "CRITICAL";
      } else {
        color = Colors.blue.shade300;
        prefix = 'INFO';
      }
    } else if (log is TalkerError || log is TalkerException) {
      color = Colors.red.shade300;
      prefix = 'EXCEPTION';
    } else {
      color = Colors.blue.shade300;
      prefix = 'LOG';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '$prefix',
                style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
              ),
              Expanded(
                child: Text(
                  log.message?.toString() ?? '',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              if (log is TalkerError || log is TalkerException) 
              Padding (
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                log.stackTrace?.toString() ?? '',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 10,
                    fontFamily: 'monospace',
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (log is TalkerLog && log.logLevel == LogLevel.error) 
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  log.stackTrace?.toString() ?? '',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 10,
                    fontFamily: 'monospace',
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
