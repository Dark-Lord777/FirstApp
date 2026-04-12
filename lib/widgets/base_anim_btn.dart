import 'dart:ui';
import 'package:flutter/material.dart';

class BaseAnimatedButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final List<Color> gradientColors;
  final Color textColor;
  final EdgeInsets padding;
  final double fontSize;

  const BaseAnimatedButton({
    super.key,
    required this.text,
    required this.onPressed,
    required this.gradientColors,
    required this.textColor,
    this.padding = const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
    this.fontSize = 24,
  });

  @override
  State<BaseAnimatedButton> createState() => _BaseAnimatedButtonState();
}

class _BaseAnimatedButtonState extends State<BaseAnimatedButton> {
  bool pressed = false;
  bool hovered = false;

  @override
  Widget build(BuildContext context) {
    final scale = pressed ? 0.96 : (hovered ? 1.03 : 1.0);
    final offsetY = pressed ? 4.0 : 0.0;

    return MouseRegion(
      onEnter: (_) => setState(() => hovered = true),
      onExit: (_) => setState(() => hovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => pressed = true),
        onTapUp: (_) {
          setState(() => pressed = false);
          widget.onPressed();
        },
        onTapCancel: () => setState(() => pressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          transform: Matrix4.translationValues(0, offsetY, 0)..scale(scale),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                padding: widget.padding,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                      colors: widget.gradientColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,

                  ),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: widget.gradientColors.first.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Text(
                  widget.text,
                  style: TextStyle(
                    fontSize: widget.fontSize,
                    color: widget.textColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
