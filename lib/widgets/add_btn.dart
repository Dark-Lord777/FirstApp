import 'package:flutter/material.dart';
import 'base_anim_btn.dart';
import 'modalka.dart';

class AddBtn extends StatelessWidget {
  final VoidCallback onPressed;
  final Function(String)? onSectorAdded;

  const AddBtn({
    super.key,
    required this.onPressed,
    this.onSectorAdded,
  });

  Future<void> _showDialog(BuildContext context) async {
    final String? sectorName = await showAddSectorDialog(context);
    
    if (sectorName != null && sectorName.isNotEmpty) {
      if (onSectorAdded != null) {
        onSectorAdded!(sectorName);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseAnimatedButton(
      text: "Add Sectors",
      onPressed: () {
        onPressed();
        _showDialog(context);
      },
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
