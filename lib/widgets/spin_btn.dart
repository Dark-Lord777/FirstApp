import 'package:flutter/material.dart';
import './base_anim_btn.dart'; //if you call this function use BaseAnimatedButton 

class SpinBtn extends StatelessWidget {
  final VoidCallback onPressed;

  const SpinBtn({
    super.key,
    required this.onPressed,
  });

  @override
Widget build(BuildContext context) {
    return BaseAnimatedButton(
      text: "Spin",
      onPressed: onPressed,
      gradientColors: [
        //later put your color like this Color(0FFhecCode)
    Color(0xFFFFD54F), // золотистый
    Color(0xFFFFB300), // тёмное золото
    Color(0xFFFF8F00), // янтарный
        ],
    textColor: Colors.white,
    padding: const EdgeInsets.symmetric(
      horizontal: 50,
      vertical: 17,
    ),
      fontSize: 24,
    );
  }
}
