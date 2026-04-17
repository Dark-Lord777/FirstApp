import 'dart:ui';
import 'dart:math';
import 'package:flutter/material.dart';

class WheelDraw extends StatelessWidget {
  final List<String> sectors;
  final double rotationAngle;  // ← ДОБАВИТЬ
  
  const WheelDraw({
    required this.sectors, 
    this.rotationAngle = 0.0,  // ← ДОБАВИТЬ
    super.key
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.purple.shade900,
            blurRadius: 30,
            spreadRadius: 5,
          ),
        ],
      ),
      width: 300,
      height: 300,
      child: CustomPaint(
        size: Size(300, 300),
        painter: _WheelPainter(sectors, rotationAngle),  // ← ПЕРЕДАЁМ ОБА
      ),
    );
  }
}

class _WheelPainter extends CustomPainter {
  final List<String> sectors;
  final double rotationAngle;  // ← ДОБАВИТЬ
  
  _WheelPainter(this.sectors, this.rotationAngle);  // ← ИЗМЕНИТЬ

  @override
  void paint(Canvas canvas, Size size) {
    var center = Offset(size.width / 2, size.height / 2);
    var radius = size.width / 2;
    
    if (sectors.isEmpty) {
      // Рисуем надпись если нет секторов
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
      
      textPainter.paint(
        canvas,
        Offset(center.dx - textPainter.width / 2, center.dy - textPainter.height / 2),
      );
      return;
    }
    
    double anglePerSector = 2 * pi / sectors.length;
    double startAngle = -pi / 2 + rotationAngle;  // ← С УЧЁТОМ ПОВОРОТА
    
    // Фон
    Paint backgroundPaint = Paint()..color = Colors.grey.shade800;
    canvas.drawCircle(center, radius, backgroundPaint);
    
    // Обводка
    Paint borderPaint = Paint()
      ..color = Colors.yellow.shade700
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7;
    canvas.drawCircle(center, radius, borderPaint);
    
    // Сектора
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
      
      // Текст
      double midAngle = startAngle + anglePerSector / 2;
      double textRadius = radius * 0.7;
      double x = center.dx + textRadius * cos(midAngle);
      double y = center.dy + textRadius * sin(midAngle);
      
      TextPainter textPainter = TextPainter(
        text: TextSpan(
          text: sectors[i],
          style: TextStyle(color: Colors.white, fontSize: 14),
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
    
    // Стрелка
    Paint pointerPaint = Paint()..color = Colors.red.shade700;
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
  }

  @override
  bool shouldRepaint(covariant _WheelPainter oldDelegate) {
    return oldDelegate.sectors != sectors || 
           oldDelegate.rotationAngle != rotationAngle;
  }
}
