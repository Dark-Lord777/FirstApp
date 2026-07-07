import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:audioplayers/audioplayers.dart';
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
import 'package:wheel_of_fortune/widgets/star_field.dart';
import 'package:wheel_of_fortune/services/music_service.dart';
import 'package:wheel_of_fortune/services/game_events.dart';
import 'package:wheel_of_fortune/services/logger.dart';


// ===== КЛАСС ЧАСТИЦЫ (ВНЕ КЛАССА WheelScreen!) =====
class _Particle {
  static final _random = _SecureRandom();

  double x, y;
  double size;
  double speed;
  double opacity;
  Color color;
  double dx, dy;

  _Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.opacity,
    required this.color,
    required this.dx,
    required this.dy,
  });

  void update() {
    x += dx * 0.005;
    y += dy * 0.005;
    if (x > 1) x = 0;
    if (x < 0) x = 1;
    if (y > 1) y = 0;
    if (y < 0) y = 1;
  }
}

class _SecureRandom {
  final _random = _Random();
  double nextDouble() => _random.nextDouble();
}

class _Random {
  int _seed = DateTime.now().millisecondsSinceEpoch;

  double nextDouble() {
    _seed = (_seed * 9301 + 49297) % 233280;
    return _seed / 233280.0;
  }

  int nextInt(int max) => (nextDouble() * max).floor();
}
// ===== КОНЕЦ КЛАССА ЧАСТИЦЫ =====

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

  // 👇 ЛЁГКИЕ ЧАСТИЦЫ ДЛЯ СТАРЫХ УСТРОЙСТВ
  late final List<_Particle> _particles = [];
  late AnimationController _particleController;

  final Random _random = Random();

  @override
  void initState() {
    super.initState();

    _applyConfig();

    _wheelLogic = WheelLogic(
      vsync: this,
      onAngleChanged: () {
        setState(() {
          _currentRotationAngle = _wheelLogic.currentAngle;
        });
      },
      onWin: (String prize) async {
        Log.d("PRIZE $prize");
        GameEventsService().recordSpin(prize, true);
        _pulseController.forward().then((_) => _pulseController.reset());
        MusicService.setBackgroundVolume(0.3);
        MusicService.playWinSound();

        if (!kIsWeb) {
          await DatabaseService.instance.saveSpin(prize, true);
        }
        MusicService.setBackgroundVolume(1.0);
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

    // 👇 ИНИЦИАЛИЗАЦИЯ ЧАСТИЦ
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _initParticles();
        AppConfigService().starsNotifier.addListener(_onStarsChanged);
  }
  void _onStarsChanged() {
    if (mounted) {
      setState(() {}); 
    }
  }
  
  void _initParticles() {
    final random = _Particle._random;
    for (int i = 0; i < 50; i++) {
      final colorIndex = (random.nextDouble() * 4).floor();
      _particles.add(_Particle(
        x: random.nextDouble(),
        y: random.nextDouble(),
        size: random.nextDouble() * 5 + 1.5,
        speed: random.nextDouble() * 0.5 + 0.2,
        opacity: random.nextDouble() * 0.3 + 0.7,
        color: [
                Colors.orange.shade400,   // 🟧 ЯРКИЙ
        Colors.white,     // 🩰 РОЗОВЫЙ
        Colors.red,     // 💎 БИРЮЗОВЫЙ
        Colors.purple,     // 🟩 САЛАТОВЫЙ
        Colors.yellow, // 🟪 ФИОЛЕТОВЫЙ
        Colors.yellow,   // 🟨 ЖЁЛТЫЙ

        ][colorIndex],
        dx: (random.nextDouble() - 0.5) * 0.5,
        dy: (random.nextDouble() - 0.5) * 0.5,
      ));
    }
  }

  Widget _buildParticle(_Particle p, Size size) {
    return Positioned(
      left: p.x * size.width,
      top: (p.y * size.height) % size.height,
      child: AnimatedBuilder(
        animation: _particleController,
        builder: (context, child) {
          p.update();
          return Transform.translate(
            offset: Offset(
              p.dx * _particleController.value * 50,
              p.dy * _particleController.value * 50,
            ),
            child: Container(
              width: p.size,
              height: p.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: p.color.withOpacity(p.opacity),
              ),
            ),
          );
        },
      ),
    );
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
    final size = MediaQuery.of(context).size; // 👈 ДЛЯ ЧАСТИЦ
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

              // ========== 2. ЗВЁЗДЫ ИЛИ ЧАСТИЦЫ ==========
              if (AppConfigService().starsEnabled)
                const StarField()
              else
                ..._particles.map((p) => _buildParticle(p, size)),

              // ========== 3. ВСЁ ОСТАЛЬНОЕ ==========
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
                      titleText = AppConfigService().titleText;
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
                      Log.d('Spin button pressed');
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
                    onTap: () {
                      MusicService.playClick();
                    Scaffold.of(context).openDrawer();
                    },
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
    _wheelLogic.dispose();
    _pulseController.dispose();
    _particleController.dispose();
        AppConfigService().starsNotifier.removeListener(_onStarsChanged);
    super.dispose();
  }
}
