import 'dart:ui';
import 'dart:math';
import 'package:flutter/material.dart';

class WheelDraw extends StatelessWidget {
  final List<String> sectors;
  const WheelDraw({required this.sectors, super.key});

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
        painter: _WheelPainter(sectors),  
      ),
    );
  }
}

class _WheelPainter extends CustomPainter {
  final List<String> sectors;
  _WheelPainter(this.sectors); 

  @override
  void paint(Canvas canvas, Size size) {

    var center = Offset(size.width / 2, size.height / 2);
    var radius = size.width / 2;
    var angle = 2 * 3.14 / sectors.length;
    var start = -1.57; 

    Paint backgroundPaint = Paint()
    ..color = Colors.grey.shade800
    ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, backgroundPaint);
    Paint obvodka = Paint()
    ..color = Colors.yellow.shade700
    ..style = PaintingStyle.stroke
    ..strokeWidth = 7;
    canvas.drawCircle(center, radius, obvodka);


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
  textPainter.paint(
    canvas,
    Offset(
      center.dx - textPainter.width / 2,
      center.dy - textPainter.height / 2,
    ),
  );
  return;
}
    if (sectors.isEmpty) return;
    for (var i = 0; i < sectors.length; i++) {
      var paint = Paint()..color = Colors.primaries[i % Colors.primaries.length];
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius), 
        start,
        angle,
        true,
        paint,
      );

Paint pointerPaint = Paint()
  ..color = Colors.red.shade700
  ..style = PaintingStyle.fill;

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


    var midAngle = start + angle / 2;
    var textRadius = radius * 0.7;
    var x = center.dx + textRadius * cos(midAngle);
    var y = center.dy + textRadius * sin(midAngle);

    TextPainter textPainter = TextPainter(
      text: TextSpan(
        text: sectors[i],
        style: TextStyle(
          color: Colors.white,
          fontSize: 14,

        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(x - textPainter.width / 2, y - textPainter.height / 2),
    );
      start += angle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
