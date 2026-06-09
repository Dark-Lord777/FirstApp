import 'package:flutter/material.dart';
import 'package:wheel_of_fortune/widgets/base_anim_btn.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:bee_dynamic_launcher/bee_dynamic_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChangeIconBtn extends StatelessWidget {
  final String iconName;
  final String label;
  final IconData iconData;

  const ChangeIconBtn({
    super.key,
    required this.iconName,
    required this.label,
    required this.iconData,
  });

  Future<void> _changeIcon(BuildContext context) async {
    if (!kIsWeb && Platform.isAndroid) {
      try {
        final variants = await BeeDynamicLauncher.getAvailableVariants();
        if (variants.contains(iconName)) {
          await BeeDynamicLauncher.applyVariant(iconName);
          
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('currentIcon', iconName);
          
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Icon changed to $label')),
            );
          }
        } else {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Variant not available'), backgroundColor: Colors.orange),
            );
          }
        }
      } catch (e) {
       debugPrint("Error: $e");
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Not supported on this platform'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override 
  Widget build(BuildContext context) {
    return BaseAnimatedButton(
      text: label,
      
      onPressed: () => _changeIcon(context),
      gradientColors: const [
        Color(0xFF6C5CE7),
        Color(0xFF8E44AD),
        Color(0xFF9B59B6),
      ],
      textColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      fontSize: 16,
    );
  }
}
