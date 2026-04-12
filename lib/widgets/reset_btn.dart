import 'package:flutter/material.dart';
import './base_anim_btn.dart';

class ResetButton extends StatelessWidget {
  final VoidCallback onPressed;

  const ResetButton({
    super.key,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return BaseAnimatedButton(
      text: "RESET",
      onPressed: onPressed,
      gradientColors: [
    Color(0xFFFFAB91), // персик
    Color(0xFFFF8A65), // оранжево-персик
    Color(0xFFF4511E), // глубокий оранжевый
      ],
      textColor: Colors.yellow,
      padding: const EdgeInsets.symmetric(
        horizontal: 45,
        vertical: 17,
      ),
      fontSize: 24,
    );
  }
}
