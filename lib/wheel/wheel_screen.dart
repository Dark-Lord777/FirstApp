import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter/material.dart';
import 'package:wheel_of_fortune/screen/hamburger_menu.dart';
import 'package:wheel_of_fortune/services/app_config_service.dart';
import 'package:wheel_of_fortune/services/database_service.dart';
import 'package:wheel_of_fortune/widgets/add_btn.dart';
import 'package:wheel_of_fortune/widgets/modalka.dart';
import 'package:wheel_of_fortune/widgets/reset_btn.dart';
import 'package:wheel_of_fortune/widgets/spin_btn.dart';
import 'package:wheel_of_fortune/widgets/star.dart';
import 'package:wheel_of_fortune/wheel/logic.dart';
import 'package:wheel_of_fortune/wheel/wheel.dart';
import 'package:wheel_of_fortune/widgets/star_background.dart';


class WheelScreen extends StatefulWidget {
  const WheelScreen({super.key});

  @override
  State<WheelScreen> createState() => _WheelScreenState();
}

class _WheelScreenState extends State<WheelScreen> with TickerProviderStateMixin {
  List<String> sectors = [];
  late WheelLogic _wheelLogic;
  double _currentRotationAngle = 0.0;

  String titleText = "";

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  final Random _random = Random();
  late List<Map<String, dynamic>> _stars;

  Timer? _timer;
  Timer? _respawnTimer;

  bool _isAttracting = false;
  bool _isTouching = false;

  @override
  void initState() {
    super.initState();

    _respawnTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _respawnStars();
    });

    _applyConfig();

    _wheelLogic = WheelLogic(
      vsync: this,
      onAngleChanged: () {
        setState(() {
          _currentRotationAngle = _wheelLogic.currentAngle;
        });
      },
      onWin: (String prize) async {
        debugPrint("PRIZE $prize}");
        _pulseController.forward().then((_) => _pulseController.reset());
        if (!kIsWeb) {
          await DatabaseService.instance.saveSpin(prize, true);
        }
      },
      sectors: sectors,
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.elasticOut),
    );
    _generateStars();
    _startStarAnimation();
  }

  void _startStarAnimation() {
    _timer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      _updateStars();
    });
  }

  void _generateStars() {
    _stars = List.generate(150, (index) {
      return {
        'x': _random.nextDouble(),
        'y': _random.nextDouble(),
        'opacity': 0.3 + _random.nextDouble() * 0.4,
        'direction': 1,
        'size': 2 + _random.nextDouble() * 6,
        'speedX': (-1 + _random.nextDouble() * 2) * 0.0008,
        'speedY': (-1 + _random.nextDouble() * 2) * 0.0008,
        'phase': _random.nextDouble() * 2 * pi,
      };
    });
  }

  void _handleTapDown(Offset position) {
    _isTouching = true;
    attractStars(position);
  }

  void _handleTapUp() {
    _isTouching = false;
    _isAttracting = false;
    scatterStars();
  }

  void _handleTapCancel() {
    _isTouching = false;
    _isAttracting = false;
  }

  void _respawnStars() {
    for (int i = 0; i < _stars.length; i++) {
      if ((_stars[i]['speedX'] as double).abs() < 0.00002 &&
          (_stars[i]['speedY'] as double).abs() < 0.00002) {
        _stars[i]['x'] = _random.nextDouble();
        _stars[i]['y'] = _random.nextDouble();
        _stars[i]['speedX'] = (-1 + _random.nextDouble() * 2) * 0.0008;
        _stars[i]['speedY'] = (-1 + _random.nextDouble() * 2) * 0.0008;
      }
    }
  }

  void scatterStars() {
    for (var star in _stars) {
      star['speedX'] = (-1 + _random.nextDouble() * 2) * 0.01;
      star['speedY'] = (-1 + _random.nextDouble() * 2) * 0.01;
    }
  }

  void _updateStars() {
    setState(() {
      for (var star in _stars) {
        star['x'] = (star['x'] as double) + (star['speedX'] as double);
        star['y'] = (star['y'] as double) + (star['speedY'] as double);

        star['speedX'] = (star['speedX'] as double) * 0.99;
        star['speedY'] = (star['speedY'] as double) * 0.99;

        if ((star['x'] as double) > 1) {
          star['x'] = 1.0;
          star['speedX'] = -(star['speedX'] as double);
        }
        if ((star['x'] as double) < 0) {
          star['x'] = 0.0;
          star['speedX'] = -(star['speedX'] as double);
        }

        if ((star['y'] as double) > 1) {
          star['y'] = 1.0;
          star['speedY'] = -(star['speedY'] as double);
        }
        if ((star['y'] as double) < 0) {
          star['y'] = 0.0;
          star['speedY'] = -(star['speedY'] as double);
        }

        double size = star['size'] as double;
        if (size < 0.5) {
          star['size'] = 0.5;
        }
        if (size > 20) {
          star['size'] = 20;
        }

        double opacity = star['opacity'] as double;
        if (opacity > 1.0) star['opacity'] = 1.0;
        if (opacity < 0.1) star['opacity'] = 0.1;
      }
    });
  }

  void attractStars(Offset touchPoint) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    _isAttracting = true;
    setState(() {
      for (var star in _stars) {
        double starX = (star['x'] as double) * screenWidth;
        double starY = (star['y'] as double) * screenHeight;

        double dx = touchPoint.dx - starX;
        double dy = touchPoint.dy - starY;
        double distance = sqrt(dx * dx + dy * dy);

        if (distance > 1) {
          double speed = 0.002;
          star['speedX'] = (dx / distance) * speed;
          star['speedY'] = (dy / distance) * speed;
        }
      }
    });
  }

  void _applyConfig() {
    setState(() {
      titleText = AppConfigService().titleText;
    });
  }

  Future<void> _showAddSectorDialog() async {
    final result = await showAddSectorDialog(
      context: context,
      title: "Add New Sector",
      hintText: "Enter sector name...",
      errorText: "Please enter sector name",
      buttonText: "Add",
      icon: Icons.add_circle_outline_rounded,
    );
    if (result != null && result.isNotEmpty) {
      setState(() {
        sectors.add(result);
        _wheelLogic.updateSectors(sectors);
      });
    }
  }

  Future<void> _showChangeTitleDialog() async {
    final newTitle = await showAddSectorDialog(
      context: context,
      title: "Change Title",
      hintText: "Enter new title...",
      buttonText: "Change",
      icon: Icons.title,
      initialValue: titleText,
      errorText: "Please enter title",
    );
    if (newTitle != null && newTitle.isNotEmpty) {
      setState(() {
        titleText = newTitle;
      });
    }
  }

    @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isLandscape = screenWidth > screenHeight;
    final isTablet = screenWidth > 600;
    final isSmallWindow = screenWidth < 500;

    final topPadding = screenHeight * (isLandscape ? 0.05 : 0.13);
    final wheelTop = screenHeight * (isLandscape ? 0.15 : 0.25);
    final bottomButtons = screenHeight * 0.23;
    final addButtonBottom = screenHeight * 0.06;

    double titleFontSize;
    if (isTablet) {
      titleFontSize = 50.0;
    } else if (isSmallWindow) {
      titleFontSize = 24.0;
    } else {
      titleFontSize = screenWidth * 0.08;
    }
    titleFontSize = titleFontSize.clamp(20.0, 50.0);

    final leftRightOffset = screenWidth * 0.05;

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;

        return Scaffold(
          resizeToAvoidBottomInset: false,
          drawer: const SettingsDrawer(),
          body: Stack(
            fit: StackFit.expand,
            children: [
              // ========== 1. ГРАДИЕНТНЫЙ ФОН ==========
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: const [
                      Color(0xFF1A1A1A),
                      Color(0xFF201A30),
                      Color(0xFF2A1A3A),
                      Color(0xFF321D4F),
                      Color(0xFF3D1F6D),
                      Color(0xFF48247B),
                      Color(0xFF552A8A),
                      Color(0xFF613099),
                      Color(0xFF7038A8),
                      Color(0xFF7D41B8),
                      Color(0xFF8B4BC8),
                      Color(0xFF9858D4),
                      Color(0xFFA865E0),
                      Color(0xFFB874EC),
                    ],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
              ),

              // ========== 2. ЗВЁЗДЫ (СВЕРХУ ФОНА) ==========
              StarBackground(
                stars: _stars,
                onTapDown: _handleTapDown,
                onTapUp: _handleTapUp,
                onTapCancel: _handleTapCancel,
              ),

              // ========== 3. ВСЁ ОСТАЛЬНОЕ (КНОПКИ, ЗАГОЛОВОК, КОЛЕСО) ==========
              // Заголовок
              Positioned(
                top: topPadding,
                left: 0,
                right: 0,
                child: Center(
                  child: GestureDetector(
                    onTap: _showChangeTitleDialog,
                    child: Text(
                      titleText,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.yellow.shade500,
                        fontSize: titleFontSize,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),

              // Колесо
              Positioned(
                top: wheelTop,
                left: 0,
                right: 0,
                child: Center(
                  child: AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _pulseAnimation.value,
                        child: child,
                      );
                    },
                    child: WheelDraw(
                      sectors: sectors,
                      rotationAngle: _currentRotationAngle,
                      availableWidth: availableWidth,
                    ),
                  ),
                ),
              ),

              // Кнопка Reset
              Positioned(
                left: leftRightOffset,
                bottom: bottomButtons,
                child: ResetButton(
                  onPressed: () {
                    setState(() {
                      sectors.clear();
                      _wheelLogic.updateSectors(sectors);
                    });
                  },
                ),
              ),

              // Кнопка Add
              Positioned(
                left: 0,
                right: 0,
                bottom: addButtonBottom,
                child: Center(
                  child: AddBtn(
                    onPressed: _showAddSectorDialog,
                  ),
                ),
              ),

              // Кнопка Spin
              Positioned(
                right: leftRightOffset,
                bottom: bottomButtons,
                child: SpinBtn(
                  onPressed: () {
                    if (sectors.isEmpty) {
                      return;
                    }
                    _wheelLogic.spin();
                  },
                ),
              ),

              // Гамбургер меню
              Positioned(
                top: MediaQuery.of(context).padding.top + 8,
                left: 16,
                child: Builder(
                  builder: (context) => GestureDetector(
                    onTap: () => Scaffold.of(context).openDrawer(),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.menu,
                        color: Colors.yellow.shade500,
                        size: 28,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }


  @override
  void dispose() {
    _timer?.cancel();
    _respawnTimer?.cancel();
    _wheelLogic.dispose();
    _pulseController.dispose();
    super.dispose();
  }
}

