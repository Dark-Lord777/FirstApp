import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:bot_toast/bot_toast.dart';

import 'package:wheel_of_fortune/wheel/wheel_screen.dart';
import 'package:wheel_of_fortune/services/app_config_service.dart';
import 'package:wheel_of_fortune/services/routing.dart';
import 'package:wheel_of_fortune/screen/splash_screen.dart';
import 'package:wheel_of_fortune/services/music_service.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  // ===== АНИМАЦИИ =====
  late AnimationController _mainController;
  late Animation<double> _fadeIn;
  late Animation<double> _scaleIn;
  late Animation<double> _slideUp;

  late AnimationController _wheelController;
  late Animation<double> _wheelRotation;

  late AnimationController _particleController;
  final List<_Particle> _particles = [];

  // ===== ПОЛЕ =====
  final TextEditingController _nickController = TextEditingController();
  final FocusNode _nickFocusNode = FocusNode();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeIn = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _mainController, curve: Curves.easeOut),
    );

    _scaleIn = Tween<double>(begin: 0.7, end: 1).animate(
      CurvedAnimation(parent: _mainController, curve: Curves.elasticOut),
    );

    _slideUp = Tween<double>(begin: 50, end: 0).animate(
      CurvedAnimation(parent: _mainController, curve: Curves.easeOut),
    );

    _wheelController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _wheelRotation = Tween<double>(begin: 0, end: 2 * pi).animate(
      CurvedAnimation(parent: _wheelController, curve: Curves.linear),
    );

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _initParticles();

    _mainController.forward();

    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        // _nickFocusNode.requestFocus();
      }
    });
  }

  void _initParticles() {
    final random = _Particle._random;
    for (int i = 0; i < 50; i++) {
      final colorIndex = (random.nextDouble() * 4).floor();
      _particles.add(_Particle(
        x: random.nextDouble(),
        y: random.nextDouble(),
        size: random.nextDouble() * 4 + 2,
        speed: random.nextDouble() * 0.5 + 0.2,
        opacity: random.nextDouble() * 0.5 + 0.3,
        color: [
          Colors.purple.shade300,
          Colors.pink.shade300,
          Colors.blue.shade300,
          Colors.yellow.shade300,
        ][colorIndex],
        dx: (random.nextDouble() - 0.5) * 0.5,
        dy: (random.nextDouble() - 0.5) * 0.5,
      ));
    }
  }

  @override
  void dispose() {
    _mainController.dispose();
    _wheelController.dispose();
    _particleController.dispose();
    _nickController.dispose();
    _nickFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: GestureDetector(
        onTap: () {
          _nickFocusNode.unfocus();
        },
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF0F0F1A),
                Color(0xFF1A0A2E),
                Color(0xFF2D1B4E),
                Color(0xFF4A1A6B),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Stack(
            children: [
              // ===== ЧАСТИЦЫ =====
              ..._particles.map((p) => _buildParticle(p, size)),

              // ===== ОСНОВНОЙ КОНТЕНТ ЧЕРЕЗ СЛИВЕРЫ =====
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: CustomScrollView(
                    physics: const ClampingScrollPhysics(),
                    slivers: [
                      // Оборачиваем всю Column с основным контентом в SliverToBoxAdapter
                      SliverToBoxAdapter(
                        child: Transform.translate(
                          offset: const Offset(0, 10),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(height: 20),
                              
                              // ===== КОЛЕСО =====
                              FadeTransition(
                                opacity: _fadeIn,
                                child: ScaleTransition(
                                  scale: _scaleIn,
                                  child: AnimatedBuilder(
                                    animation: _wheelRotation,
                                    builder: (context, child) {
                                      return Transform.rotate(
                                        angle: _wheelRotation.value,
                                        child: Container(
                                          width: size.width * 0.45,
                                          height: size.width * 0.45,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            gradient: RadialGradient(
                                              colors: [
                                                Colors.purple.shade300,
                                                Colors.purple.shade700,
                                                Colors.purple.shade900,
                                              ],
                                              stops: const [0.2, 0.6, 1.0],
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.purple.shade700
                                                    .withOpacity(0.5),
                                                blurRadius: 60,
                                                spreadRadius: 20,
                                              ),
                                            ],
                                          ),
                                          child: Stack(
                                            alignment: Alignment.center,
                                            children: [
                                              ...List.generate(12, (index) {
                                                final angle =
                                                    index * (2 * pi / 12);
                                                return Transform.rotate(
                                                  angle: angle,
                                                  child: Container(
                                                    width: size.width * 0.65 * 0.6,
                                                    height: 2,
                                                    color: Colors.white
                                                        .withOpacity(
                                                            index % 2 == 0
                                                                ? 0.3
                                                                : 0.15),
                                                  ),
                                                );
                                              }),
                                              Container(
                                                width: 50,
                                                height: 50,
                                                decoration: const BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: Colors.white,
                                                ),
                                                child: const Icon(
                                                  Icons.star,
                                                  color: Colors.purple,
                                                  size: 28,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),

                              const SizedBox(height: 40),

                              // ===== ЗАГОЛОВОК =====
                              FadeTransition(
                                opacity: _fadeIn,
                                child: Transform.translate(
                                  offset: Offset(0, _slideUp.value),
                                  child: Column(
                                    children: [
                                      const Text(
                                        'Wheel of Fortune',
                                        style: TextStyle(
                                          fontSize: 32,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          letterSpacing: 1.5,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Spin and decide!',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.white.withOpacity(0.6),
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(height: 30),

                              // ===== ПОЛЕ ДЛЯ НИКА =====
                              FadeTransition(
                                opacity: _fadeIn,
                                child: Transform.translate(
                                  offset: Offset(0, _slideUp.value * 1.2),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Come up with a nickname',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.8),
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.purple.shade900
                                                  .withOpacity(0.3),
                                              Colors.purple.shade700
                                                  .withOpacity(0.1),
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(
                                            color: Colors.purple.shade400
                                                .withOpacity(0.3),
                                          ),
                                        ),
                                        child: TextField(
                                          controller: _nickController,
                                          focusNode: _nickFocusNode,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                          ),
                                          textInputAction: TextInputAction.done,
                                          decoration: InputDecoration(
                                            hintText: 'Enter a nickname...',
                                            hintStyle: TextStyle(
                                              color: Colors.white.withOpacity(0.3),
                                              fontSize: 16,
                                            ),
                                            prefixIcon: Icon(
                                              Icons.person_outline,
                                              color: Colors.purple.shade300,
                                              size: 24,
                                            ),
                                            border: InputBorder.none,
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 16,
                                            ),
                                          ),
                                          onSubmitted: (_) => _handleAuth(),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(height: 20),

                              // ===== КНОПКИ =====
                              FadeTransition(
                                opacity: _fadeIn,
                                child: Transform.translate(
                                  offset: Offset(0, _slideUp.value * 1.4),
                                  child: Column(
                                    children: [
                                      SizedBox(
                                        width: double.infinity,
                                        height: 56,
                                        child: ElevatedButton(
                                          onPressed: _isLoading
                                              ? null
                                              : _handleAuth,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                Colors.purple.shade600,
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                            ),
                                            elevation: 8,
                                            shadowColor: Colors.purple.shade700
                                                .withOpacity(0.5),
                                          ),
                                          child: _isLoading
                                              ? const SizedBox(
                                                  height: 24,
                                                  width: 24,
                                                  child: CircularProgressIndicator(
                                                    color: Colors.white,
                                                    strokeWidth: 2,
                                                  ),
                                                )
                                              : const Text(
                                                  'Continue',
                                                  style: TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      TextButton(
                                        onPressed: _isLoading ? null : _handleGuest,
                                        child: Text(
                                          'Continue as guest',
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(0.5),
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              TextButton(
                                onPressed: _isLoading ? null : _handleRestore,
                                child: Text(
                                  'Already have an account? Restore',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.4),
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ),

                      // ===== ПОДПИСЬ (ПРИЖАТА К НИЗУ) =====
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Container(
                          alignment: Alignment.bottomCenter,
                          padding: EdgeInsets.only(
                            bottom: size.height * 0.02,
                            left: 16,
                            right: 16,
                          ),
                          child: FadeTransition(
                            opacity: _fadeIn,
                            child: RichText(
                              textAlign: TextAlign.center,
                              text: TextSpan(
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.white.withOpacity(0.3),
                                ),
                                children: [
                                  const TextSpan(
                                    text: 'By clicking "Continue" you agree to the ',
                                  ),
                                  WidgetSpan(
                                    alignment: PlaceholderAlignment.baseline,
                                    baseline: TextBaseline.alphabetic,
                                    child: GestureDetector(
                                      behavior: HitTestBehavior.translucent,
                                      onTap: () {
                                        MusicService.playClick();
                                        _launchUrl(AppConfigService().termsUrl);
                                      },
                                      child: const Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 4,
                                          vertical: 10,
                                        ),
                                        child: Text(
                                          'Terms',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.purpleAccent,
                                            fontWeight: FontWeight.bold,
                                            decoration: TextDecoration.underline,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const TextSpan(
                                    text: ' of use',
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===== ЧАСТИЦА =====
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

  // ===== МЕТОДЫ =====

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    try {
      MusicService.playClick();
      await launchUrl(uri, mode: LaunchMode.platformDefault);
    } catch (e) {
      BotToast.showCustomText(
        duration: const Duration(seconds: 3),
        align: const Alignment(0, -0.8),
        toastBuilder: (cancelFunc) {
          return Card(
            color: Colors.red.shade900,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Text(
                'Cannot open link',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        },
      );
    }
  }

  Future<void> _handleAuth() async {
    MusicService.playClick();

    final nick = _nickController.text.trim();
    if (nick.isEmpty) {
      MusicService.playClick();

      BotToast.showCustomText(
        duration: const Duration(seconds: 2),
        align: const Alignment(0, -0.3),
        toastBuilder: (cancelFunc) {
          return Card(
            color: const Color(0xFF4A148C),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Colors.purpleAccent, width: 1),
            ),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Text(
                'Enter a nickname',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        },
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      MusicService.playClick();
      _nickFocusNode.unfocus();
      await Future.delayed(const Duration(milliseconds: 300));
      await RoutingService().registerUser(nick);
      if (mounted) {
        RoutingService().navigateToWheel(context);
      }
    } catch (e) {
      BotToast.showCustomText(
        duration: const Duration(seconds: 3),
        align: const Alignment(0, -0.8),
        toastBuilder: (cancelFunc) {
          return Card(
            color: Colors.red.shade900,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Text(
                'Error: $e',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        },
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleGuest() async {
    MusicService.playClick();
    final guestNick = 'Guest_${DateTime.now().millisecondsSinceEpoch % 10000}';

    await RoutingService().registerGuest(guestNick);
    if (mounted) {
      RoutingService().navigateToWheel(context);
    }
  }

  Future<void> _handleRestore() async {
    MusicService.playClick();

    final nick = await _showRestoreDialog();
    if (nick == null || nick.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final savedNick = prefs.getString('user_nickname');

      if (savedNick == nick) {
        await RoutingService().registerUser(nick);
        if (mounted) {
          RoutingService().navigateToWheel(context);
        }
      } else {
        BotToast.showCustomText(
          duration: const Duration(seconds: 2),
          align: const Alignment(0, -0.3),
          toastBuilder: (cancelFunc) {
            return Card(
              color: Colors.red.shade900,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Text(
                  'Account not found. Please register...',
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
            );
          },
        );
      }
    } catch (e) {
      BotToast.showCustomText(
        duration: const Duration(seconds: 2),
        align: const Alignment(0, -0.3),
        toastBuilder: (cancelFunc) {
          return Card(
            color: Colors.red.shade900,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Text(
                'Error $e',
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          );
        },
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<String?> _showRestoreDialog() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2D1B4E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Restore Account',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Enter your nickname to restore your account',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Enter your nickname...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                filled: true,
                fillColor: Colors.purple.shade900.withOpacity(0.3),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple.shade600,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Restore', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade900,
      ),
    );
  }
}

// ===== ЧАСТИЦЫ (ВНЕ КЛАССА) =====

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
