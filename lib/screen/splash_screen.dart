import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

//import 'package:wheel_of_fortune/wheel/wheel_screen.dart';
import 'package:wheel_of_fortune/screen/welcome.dart';
import 'package:wheel_of_fortune/wheel/wheel_screen.dart';


class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> 
  with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late Animation<double> _rotationAnimation;

  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  late AnimationController _positionController;
  late Animation<Offset> _positionedAnimation;

  @override 
  void initState() {
    super.initState();

    _rotationController = AnimationController(
      vsync: this,
    duration: const Duration(seconds: 2),
    )..repeat();
    
    _rotationAnimation = Tween<double>(begin: 0, end: 2 * pi).animate(
      CurvedAnimation(parent: _rotationController, curve: Curves.linear),
    );

    //In my head this wheel should change own scale 
    //from big to small if user do not registered
    _scaleController = AnimationController(
      vsync: this,
    duration: const Duration(milliseconds: 1500),
    );
    _scaleAnimation = Tween<double>(begin: 1.5, end: 0.95).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
    //move a logo to below part a screen 
    _positionController = AnimationController(
      vsync: this,
    duration: const Duration(milliseconds: 1500),
    );
    _positionedAnimation = Tween<Offset>(
      begin: const Offset(0, 0), //centre of screen
      end: const Offset(0, -0.37), 
    ).animate(
      CurvedAnimation(parent: _positionController, curve: Curves.easeInOut),
    );

    //launch a animation
    _scaleController.forward();
    _positionController.forward();

    Future.delayed(const Duration(seconds: 2), () {
      _navigateToNextScreen();
    });
  }
  void _navigateToNextScreen() async {
    final prefs = await SharedPreferences.getInstance();
    final isRegistered = prefs.getBool('is_registered') ?? false;
    final isGuest = prefs.getBool('is_guest') ?? false;

    Widget nextScreen;
    if (isRegistered || isGuest) {
      nextScreen = const WheelScreen();
    } else {
      nextScreen = const WelcomeScreen();
    }
    Navigator.pushReplacement(
      context,
    MaterialPageRoute(builder: (_) => nextScreen),
    );
  }
  
/*
  Widget getInitialScreen() {
    if(_isRegistered || _isGuest) {
      debugPrint('User Already: nickname=$nickname, going to Wheelscreen');
      return const WheelScreen();
    } else {
      debugPrint('No user found, showing WelcomeScreen');
      return const WelcomeScreen();
    }
  }
  void _navigateToWelcome() {
    Navigator.pushReplacement(
      context,
    PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) => const WelcomeScreen(),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = 0.0;
        const end = 1.0;
        const curve = Curves.easeInOut;
          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          var opacityAnimation = animation.drive(tween);
          return FadeTransition(
          opacity: opacityAnimation,
          child: child,
          );
        },
      transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }
*/ 
  @override
  void dispose() {
    _rotationController.dispose();
    _scaleController.dispose();
    _positionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
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
      
      child: Center(
        child: AnimatedBuilder(
          animation: Listenable.merge([
            _rotationController,
            _scaleController,
            _positionController,

          ]),
        builder: (context, child) {
            return Transform.translate(
              offset: Offset(
                _positionedAnimation.value.dx * size.width,
                _positionedAnimation.value.dy * size.height,
              ),
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: Transform.rotate(
                  angle: _rotationAnimation.value,
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
                          color: Colors.purple.shade700.withOpacity(0.5),
                          blurRadius: 60,
                          spreadRadius: 20,
                        ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        ...List.generate(12, (index) {
                          final angle = index * (2 * pi / 12);
                          return Transform.rotate(
                            angle: angle,
                            child: Container(
                              width: size.width * 0.45 * 0.9,
                              height: 2,
                              color: Colors.white.withOpacity(
                                index % 2 == 0 ? 0.3 : 0.15,
                              ),
                            ),
                          );
                        }),
                      Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                          ),
                          child: const Icon(
                            Icons.star,
                            color: Colors.purple,
                            size: 24,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
      ),
    );
  }
}
