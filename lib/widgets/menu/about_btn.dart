import 'package:flutter/material.dart';
import 'package:wheel_of_fortune/widgets/base_anim_btn.dart';

class AboutBtn extends StatelessWidget {
  const AboutBtn({super.key});

  @override
  Widget build(BuildContext context) {
    return BaseAnimatedButton(
      text: 'About',
      onPressed: () {
        showAboutDialog(
          context: context,
          applicationName: 'Wheel of Fortune',
          applicationVersion: '1.0.0',
          applicationIcon: const Icon(Icons.casino, size: 30),
          children: const [
            Text('Dynamic icon changer'),
            Text('Made with Flutter'),
          ],
        );
      },
      gradientColors: const [
        Color(0xFF757F9A),
        Color(0xFFD7DDE8),
      ],
      textColor: Colors.black87,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      fontSize: 16,
    );
  }
}
