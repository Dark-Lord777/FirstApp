import 'package:flutter/material.dart';
import 'package:wheel_of_fortune/widgets/base_anim_btn.dart';
import 'package:wheel_of_fortune/widgets/modalka.dart';

class AddBtn extends StatelessWidget {
  final VoidCallback onPressed;
//  final Function(String)? onSectorAdded;

  const AddBtn({
    super.key,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return BaseAnimatedButton(
      text: "Add Sectors",
      onPressed: onPressed,
      gradientColors: [
        Color(0xFFF48FB1),
        Color(0xFFEC407A),
        Color(0xFFD81B60),
      ],
      textColor: Colors.white,
      padding: const EdgeInsets.symmetric(
        horizontal: 70,
        vertical: 17,
      ),
      fontSize: 18,
    );
  }
}
