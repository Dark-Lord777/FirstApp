import 'package:flutter/material.dart';
import 'dart:math';

class Star extends StatelessWidget {
  final double size;
  final double opacity;

  const Star({
    required this.size,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: StarPainter(
        size: size,
        opacity: opacity,
      ),
    );
  }
}

class StarPainter extends CustomPainter {
  final double size;
  final double opacity;

  const StarPainter({
    required this.size,
    required this.opacity,
  });

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final Paint paint = Paint()
      ..color = Colors.white.withOpacity(opacity)
      ..style = PaintingStyle.fill;

    final Path path = Path();
    final Offset center = Offset(canvasSize.width / 2, canvasSize.height / 2);
    final double outerRadius = size / 2;
    final double innerRadius = outerRadius * 0.4;
    const int points = 5;

    for (int i = 0; i < points * 2; i++) {
      final double radius = i.isEven ? outerRadius : innerRadius;
      final double angle = -pi / 2 + (i * pi) / points;
      final double x = center.dx + radius * cos(angle);
      final double y = center.dy + radius * sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
