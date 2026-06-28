import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:wheel_of_fortune/widgets/star.dart';
import 'package:wheel_of_fortune/services/app_config_service.dart';

class StarField extends StatefulWidget {
  const StarField({super.key});

  @override
  State<StarField> createState() => _StarFieldState();
}

class _StarFieldState extends State<StarField> {
  late List<Map<String, dynamic>> _stars;
  final Random _random = Random();
  Timer? _timer;
  Timer? _respawnTimer;

  bool _isAttracting = false;
  bool _isTouching = false;

  @override
  void initState() {
    super.initState();
    _generateStars();
    _startStarAnimation();

    _respawnTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _respawnStars();
    });
  }

  void _generateStars() {
    _stars = List.generate(150, (index) {
      return {
        'x': _random.nextDouble(),
        'y': _random.nextDouble(),
        'opacity': 0.8 + _random.nextDouble() * 0.2,
        'size': 2 + _random.nextDouble() * 6,
        'speedX': (-1 + _random.nextDouble() * 2) * 0.0008,
        'speedY': (-1 + _random.nextDouble() * 2) * 0.0008,
        'phase': _random.nextDouble() * 2 * pi,
      };
    });
  }

  void _startStarAnimation() {
    _timer = Timer.periodic(const Duration(milliseconds: 80), (timer) {
      _updateStars();
    });
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

        // Пульсация прозрачности
        star['phase'] = (star['phase'] as double) + 0.05;
        final double pulse = 0.7 + 0.3 * sin(star['phase'] as double);
        star['opacity'] = (star['opacity'] as double) * pulse;
        if ((star['opacity'] as double) > 1.0) star['opacity'] = 1.0;
        if ((star['opacity'] as double) < 0.1) star['opacity'] = 0.1;
      }
    });
  }

  void _handleTapDown(Offset position) {
    _isTouching = true;
    _attractStars(position);
  }

  void _handleTapUp() {
    _isTouching = false;
    _isAttracting = false;
    _scatterStars();
  }

  void _handleTapCancel() {
    _isTouching = false;
    _isAttracting = false;
  }

  void _attractStars(Offset touchPoint) {
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

  void _scatterStars() {
    for (var star in _stars) {
      star['speedX'] = (-1 + _random.nextDouble() * 2) * 0.01;
      star['speedY'] = (-1 + _random.nextDouble() * 2) * 0.01;
    }
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

  @override
  void dispose() {
    _timer?.cancel();
    _respawnTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!AppConfigService().starsEnabled) {
      return const SizedBox.shrink(); //dont show  the stars 
    }
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return GestureDetector(
      onTapDown: (details) => _handleTapDown(details.localPosition),
      onTapUp: (_) => _handleTapUp(),
      onTapCancel: _handleTapCancel,
      behavior: HitTestBehavior.translucent,
      child: Stack(
        children: _stars.map((star) {
          return Positioned(
            left: (star['x'] as double) * screenWidth,
            top: (star['y'] as double) * screenHeight,
            child: Star(
              size: star['size'] as double,
              opacity: star['opacity'] as double,
            ),
          );
        }).toList(),
      ),
    );
  }
}
