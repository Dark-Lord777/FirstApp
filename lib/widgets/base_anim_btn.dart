import 'dart:ui';
import 'package:flutter/material.dart';

import 'package:wheel_of_fortune/services/music_service.dart';


class BaseAnimatedButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final List<Color> gradientColors;
  final Color textColor;
  final EdgeInsets padding;
  final double fontSize;
  final bool playClickSound;

  const BaseAnimatedButton({
    super.key,
    required this.text,
    required this.onPressed,
    required this.gradientColors,
    required this.textColor,
    this.padding = const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
    this.fontSize = 24,
    this.playClickSound = true,
  });

  @override
  State<BaseAnimatedButton> createState() => _BaseAnimatedButtonState();
}

class _BaseAnimatedButtonState extends State<BaseAnimatedButton> 
 with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool pressed = false;
  bool hovered = false;

  @override 
  void initState() {
   super.initState();
  _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 100),
  );
  _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
    CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
  );
}

void _handlePress() {
      debugPrint(' _handlePress called'); 
  if (widget.onPressed == null) { 
  debugPrint("on pressed in null");
  return; 
  }

  if (widget.playClickSound) {
      debugPrint(' playClickSound is true, calling playClick...');
  debugPrint('Play click');
    MusicService.playClick();
  } else {
        debugPrint(' playClickSound is false, skipping');
  }
  _controller.forward().then((_) {
    _controller.reverse();
    widget.onPressed!();
  });
}
  @override 
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

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
          _handlePress();
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
