import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:wheel_of_fortune/widgets/star.dart';

class StarBackground extends StatefulWidget {
  final List<Map<String, dynamic>> stars;
  final Function(Offset) onTapDown;
  final Function() onTapUp;
  final Function() onTapCancel;

  const StarBackground({
    super.key,
    required this.stars,
    required this.onTapDown,
    required this.onTapUp,
    required this.onTapCancel,
  });

  @override
  State<StarBackground> createState() => _StarBackgroundState();
}

class _StarBackgroundState extends State<StarBackground> {
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return GestureDetector(
      onTapDown: (details) => widget.onTapDown(details.localPosition),
      onTapUp: (details) => widget.onTapUp(),
      onTapCancel: widget.onTapCancel,
      behavior: HitTestBehavior.translucent,
      child: Stack(
        children: widget.stars.map((star) {
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
