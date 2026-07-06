import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:wheel_of_fortune/services/app_config_service.dart';

class MaintenanceScreen extends StatefulWidget {
  const MaintenanceScreen({super.key});

  @override
  State<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends State<MaintenanceScreen>
with TickerProviderStateMixin {

  late AnimationController _rotationController;
  late AnimationController _particlesController;
  late Animation<double> _fadeIn;
  late Animation<double> _scaleIn;

  late AnimationController _textFadeController;
  late Animation<double> _textFade;
  

  final List<_FloatingParticle> _particles = [];
  final Random _random = Random();

//  _Comet? _comet;
  //Timer? _cometTimer;

  int _messageIndex = 0;
  Timer? _messageTimer;
  final List<String> _messages = [
        "We're polishing the wheel...",
        "Adding a little magic... ✨",
        "Preparing your next spin...",
        "Almost ready...",
        "We'll be back soon.",
  ];
  
    String _currentMessage = "We're polishing the wheel...";

 // int _dotCount = 0;
  Timer? _dotTimer;

  @override 
  void initState() {
    super.initState();
    
    //animaton of cogwheel 
    _rotationController = AnimationController(
      vsync: this,
    duration: const Duration(seconds: 20),
    )..repeat();

    _particlesController = AnimationController(
      vsync: this,
    duration: const Duration(seconds: 3),
    )..repeat();

    _fadeIn = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _rotationController,
        curve: const Interval(0, 0.4, curve: Curves.easeOut),
      ),
    );
    _scaleIn = Tween<double>(begin: 0.8, end: 1).animate(
      CurvedAnimation(
        parent: _rotationController,
        curve: const Interval(0.2, 0.6, curve: Curves.elasticOut),
      ),
    );
    _textFadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..forward();
    _textFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _textFadeController, curve: Curves.easeOut),
    );

    _initParticles();
    //_initCometTimer();
    _initMessageTimer();
   // _initDotTimer();
  }
  void _initParticles() {
    for (int i = 0; i < 30; i++) {
      _particles.add(_FloatingParticle(
      x: _random.nextDouble(),
      y: _random.nextDouble(),
      size: _random.nextDouble() * 7 + 2,
      speed: _random.nextDouble() * 6 + 3,
      opacity: _random.nextDouble() * 0.5 + 0.4,
      color: [
        Colors.yellow.shade300,
        Colors.purple.shade300,
        Colors.pink.shade300,
        Colors.blue.shade300,
        Colors.white,
      ][_random.nextInt(5)],
      dx: (_random.nextDouble() - 0.5) * 0.3,
      dy: (_random.nextDouble() - 0.5) * 0.3,
    ));
    }
  }
/*
  void _initCometTimer() {
    _cometTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted) {
        setState(() {
        final fromLeft = _random.nextBool();
        final fromTop = _random.nextBool();
        _comet = _Comet(
          startX: -0.1,
          startY: _random.nextDouble() * 0.6 + 0.1,
          endX: 1.1,
          endY: _random.nextDouble() * 0.6 + 0.1,
          progress: 0,
          );
        });
        _animateComet();
      }
    });
  }

  void _animateComet() {
    const steps = 30;
    int step = 0;
    Timer.periodic(const Duration(milliseconds: 40), (timer) {
      step++;
      if (step > steps || !mounted) {
         timer.cancel();
         setState(() => _comet = null);
         return;
      }
      setState(() {
        if (_comet != null) {
          _comet!.progress = step / steps;
        }
      });
    });
  }
*/ 
  void _initMessageTimer() {
    _messageTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!mounted) return;
      _textFadeController.reverse().then((_) {
        if (mounted) {
        setState(() {
          _messageIndex = (_messageIndex + 1) % _messages.length;
          _currentMessage = _messages[_messageIndex];
        });
        _textFadeController.forward();
        }
      });
    });
  }
/*
  void _initDotTimer() {
    _dotTimer = Timer.periodic(const Duration(milliseconds: 450), (timer) {
      if (mounted) {
      setState(() {
        _dotCount = (_dotCount + 1) % 4;
      });
      }
    });
  }
*/
  @override
  void dispose() {
    _rotationController.dispose();
    _particlesController.dispose();
    _textFadeController.dispose();
  //  _cometTimer?.cancel();
    _messageTimer?.cancel();
  //  _dotTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final config = AppConfigService();

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: const [
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
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _rotationController,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _rotationController.value * 2 * pi * 0.3,
                    child: Container(
                      width: double.infinity,
                      height: double.infinity,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.purple.withOpacity(0.08),
                          width: 2,
                        ),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: List.generate(12, (index) {
                          final angle = index * (2 * pi / 12);
                          return Transform.rotate(
                            angle: angle,
                            child: Container(
                              width: MediaQuery.of(context).size.width * 0.9,
                              height: 1,
                              color: Colors.purple.withOpacity(0.07),
                            ),
                          );
                        }),
                      ),
                    ),
                  );
                },
              ),
            ),
            ..._particles.map((p) => _buildParticle(p, size)),
   //                     if (_comet != null) _buildComet(_comet!, size),

            
            Positioned(
              bottom: size.height * 0.12,
              left: -size.width * 0.1,
              child: AnimatedBuilder(
                animation: _rotationController,
                builder: (context, child) {
                  final angle = -_rotationController.value * 2 * pi * 0.7 +
                      sin(_rotationController.value * 2) * 0.2;
                  return Transform.rotate(
                    angle: angle,
                    child: Icon(
                      Icons.settings,
                      size: size.width * 0.2,
                      color: Colors.pink.shade300.withOpacity(0.06),
                    ),
                  );
                },
              ),
            ),

            Positioned(
              top: size.height * 0.1,
              right: -size.width * 0.15,
              child: AnimatedBuilder(
                animation: _rotationController,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _rotationController.value * 2 * pi,
                    child: Icon(
                      Icons.settings,
                      size: size.width * 0.4,
                      color: Colors.purple.shade300.withOpacity(0.5),
                    ),
                  );
                },
              ),
            ),

            Positioned(
              bottom: size.height * 0.15,
              left: -size.width * 0.1,
              child: AnimatedBuilder(
                animation: _rotationController,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: -_rotationController.value * 2 * pi * 0.7,
                    child: Icon(
                      Icons.settings,
                      size: size.width * 0.4,
                      color: Colors.pink.shade300.withOpacity(0.5),
                    ),
                  );
                },
              ),
            ),
          SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FadeTransition(
                        opacity: _fadeIn,
                        child: ScaleTransition(
                          scale: _scaleIn,
                          child: Container(
                            width: size.width * 0.3,
                            height: size.width * 0.3,
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
                                color: Colors.purple.shade700.withOpacity(0.5),
                                blurRadius: 60,
                                spreadRadius: 20,
                              ),
                            ],
                          ),
                            //spokes // spices 
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              ...List.generate(8, (index) {
                              final angle = index * (2 * pi / 8);
                              return Transform.rotate(
                                angle: angle,
                                child: Container(
                                  width: size.width * 0.25,
                                  height: 2,
                                  color: Colors.white.withOpacity(0.2),
                                  ),
                                );
                              }),

                              AnimatedBuilder(
                                  animation: _rotationController,
                                  builder: (context, child) {
                                    return Transform.rotate(
                                      angle: _rotationController.value * 2 * pi * 0.5,
                                      child: const Icon(
                                        Icons.build,
                                        color: Colors.white,
                                        size: 40,
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),

                      FadeTransition(
                        opacity: _fadeIn,
                        child: Column(
                          children: [
                            Text(
                            config.maintenanceTitle,
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 1.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.purple.shade400.withOpacity(0.2),
                                    Colors.pink.shade400.withOpacity(0.1),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.purple.shade400.withOpacity(0.3),
                                ),
                              ),
                              child: Text(
                             config.maintenanceMessage,
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.white.withOpacity(0.9),
                                  height: 1.6,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                     const SizedBox(height: 60),

                      FadeTransition(
                        opacity: _fadeIn,
                        child: Column(
                          children: [
                            SizedBox(
                              width: 200,
                              child: LinearProgressIndicator(
                                backgroundColor: Colors.white.withOpacity(0.1),
                                valueColor: AlwaysStoppedAnimation(
                                  Colors.purple.shade400 
                                ),
                                minHeight: 3,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _currentMessage,
                         //  _currentMessage + '.' * (_dotCount % 4),

                            // ' We\'re polishing the wheel...',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.4),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        //end of elements 
      ),
    );

  }
  Widget _buildParticle(_FloatingParticle p, Size size) {
    return Positioned(
      left: p.x * size.width,
      top: (p.y * size.height) % size.height,
      child: AnimatedBuilder(
        animation: _particlesController,
        builder: (context, child) {
          p.update();
          return Transform.translate(
            offset: Offset(
              p.dx * _particlesController.value * 80,
              p.dy * _particlesController.value * 80,
            ),
            child: Container(
              width: p.size,
              height: p.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: p.color.withOpacity(p.opacity),
                boxShadow: [
                  BoxShadow(
                    color: p.color.withOpacity(0.3),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          );

        },

      ),
    );
  }

/*
  Widget _buildComet(_Comet comet, Size size) {
        final dx = comet.endX - comet.startX;
        final dy = comet.endY - comet.startY;
        final angle = atan2(dy, dx);

    final x = comet.startX * size.width + (comet.endX - comet.startX) * size.width * comet.progress;
    final y = comet.startY * size.height + (comet.endY - comet.startY) * size.height * comet.progress;
      
        final trailLength = 60.0;

    return Positioned(
      left: x - 40,
      top: y - 10,
      child: AnimatedOpacity(
        opacity: comet.progress < 0.1 ? comet.progress * 10 : 
          (comet.progress > 0.9 ? (1 - comet.progress) * 10 : 1),
        duration: const Duration(milliseconds: 50),
        child: Container(
          width: 80,
          height: 20,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.purple.shade300.withOpacity(0.01),
                Colors.pink.shade300.withOpacity(0.2),
                Colors.purple.shade200.withOpacity(0.5),
              ],
            ),
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
 */  
}


class _FloatingParticle {
  double x, y, size, speed, opacity, dx, dy;
  Color color;

  _FloatingParticle({
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
/*
class _Comet {
  double startX, startY, endX, endY, progress;

  _Comet({
    required this.startX,
    required this.startY,
    required this.endX,
    required this.endY,
    required this.progress,
  });
}
*/ 
