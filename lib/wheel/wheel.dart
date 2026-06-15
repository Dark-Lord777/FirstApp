import 'dart:ui';
import 'dart:math';
import 'package:flutter/material.dart';

class WheelDraw extends StatelessWidget {
  final List<String> sectors;
  final double rotationAngle; 
  final double? availableWidth;
  
  const WheelDraw({
    required this.sectors, 
    this.rotationAngle = 0.0,
    this.availableWidth,
    super.key
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
         BoxShadow(
            color: Colors.purple.shade700.withOpacity(0.8),
            blurRadius: 40,
            spreadRadius: 10,
          ),
          BoxShadow(
            color: Colors.purple.shade500.withOpacity(0.5),
            blurRadius: 60,
            spreadRadius: 5,
          ),

          BoxShadow(
            color: Colors.purple.shade400.withOpacity(0.3),
            blurRadius: 80,
            spreadRadius: 0,
          ),
        ],
      ),
      width: 300,
      height: 300,
      child: CustomPaint(
        size: Size(300, 300),
        painter: _WheelPainter(sectors, rotationAngle),  
      ),
    );
  }
}

class _WheelPainter extends CustomPainter {
  final List<String> sectors;
  final double rotationAngle;  
  
  _WheelPainter(this.sectors, this.rotationAngle); 

  @override
  void paint(Canvas canvas, Size size) {
    var center = Offset(size.width / 2, size.height / 2);
    var radius = size.width / 2;
    
    if (sectors.isEmpty) {
      TextPainter textPainter = TextPainter(
        text: TextSpan(
          style: TextStyle(color: Colors.white, fontSize: 16),
          children: [
            TextSpan(text: "Click on button\n"),
            TextSpan(
              text: "Add Sectors",
              style: TextStyle(
                color: Colors.pink.shade400,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      
      Paint bgPaint = Paint()..color = Colors.grey.shade800;
      canvas.drawCircle(center, radius, bgPaint);
      
    Paint borderPaint = Paint()
      ..color = Colors.yellow.shade700
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7;
    canvas.drawCircle(center, radius, borderPaint);
      textPainter.paint(
        canvas,
        Offset(center.dx - textPainter.width / 2, center.dy - textPainter.height / 2),
      );

      Paint centerDot = Paint()..color = Colors.white;
      canvas.drawCircle(center, 5, centerDot);
      return;
    }
    
    double anglePerSector = 2 * pi / sectors.length;
    double startAngle = -pi / 2 + rotationAngle;  
    
    Paint backgroundPaint = Paint()..color = Colors.grey.shade800;
    canvas.drawCircle(center, radius, backgroundPaint);
    
    Paint borderPaint = Paint()
      ..color = Colors.yellow.shade700
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7;
    canvas.drawCircle(center, radius, borderPaint);
    
    for (int i = 0; i < sectors.length; i++) {
      Paint sectorPaint = Paint()
        ..color = Colors.primaries[i % Colors.primaries.length];
      
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        anglePerSector,
        true,
        sectorPaint,
      );
      
      double midAngle = startAngle + anglePerSector / 2;
      double textRadius = radius * 0.7;
      double x = center.dx + textRadius * cos(midAngle);
      double y = center.dy + textRadius * sin(midAngle);
      
      TextPainter textPainter = TextPainter(
        text: TextSpan(
          text: sectors[i],
          style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold,
          shadows: [
            Shadow(color: Colors.black.withOpacity(0.5),
        blurRadius: 4,
        offset: Offset(2, 2),
              ),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, y - textPainter.height / 2),
      );
      
      startAngle += anglePerSector;
    }
    
    Paint pointerPaint = Paint()
    ..shader = LinearGradient(
      colors: [Colors.amber.shade600, Colors.amber.shade300],
    ).createShader(Rect.fromLTWH(size.width / 2 - 20, -15, 40, 50));

    Path pointerPath = Path();
    double pointerX = size.width / 2;
    double pointerTop = -15;
    
    pointerPath.moveTo(pointerX - 20, pointerTop);
    pointerPath.lineTo(pointerX, pointerTop + 35);
    pointerPath.lineTo(pointerX + 20, pointerTop);
    pointerPath.close();
    
    canvas.drawPath(pointerPath, pointerPaint);
    
    Paint pointerBorder = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawPath(pointerPath, pointerBorder);

    Paint centerBorder = Paint()
    ..shader = RadialGradient(
      colors: [Colors.amber.shade400, Colors.amber.shade800],
    ).createShader(Rect.fromCircle(center: center, radius: 25));

    Paint centerDot =  Paint()..color = Colors.white;
    canvas.drawCircle(center, 5, centerDot);

  }

  @override
  bool shouldRepaint(covariant _WheelPainter oldDelegate) {
    return oldDelegate.sectors != sectors || 
           oldDelegate.rotationAngle != rotationAngle;
  }
}
