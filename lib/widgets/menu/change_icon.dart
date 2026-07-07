import 'package:flutter/material.dart';
import 'package:wheel_of_fortune/widgets/base_anim_btn.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:bee_dynamic_launcher/bee_dynamic_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bot_toast/bot_toast.dart';

import 'package:wheel_of_fortune/services/music_service.dart';
import 'package:wheel_of_fortune/services/logger.dart';


class ChangeIconBtn extends StatelessWidget {
  final String iconName;
  final String label;
  final String previewImagePath;
  final bool isActive;

  const ChangeIconBtn({
    super.key,
    required this.iconName,
    required this.label,
    required this.previewImagePath,
    this.isActive = false,
  });

  Future<void> _changeIcon(BuildContext context) async {
    if (!kIsWeb && Platform.isAndroid) {
      try {
        Log.d('Trying to change icon to: $iconName');

        final variants = await BeeDynamicLauncher.getAvailableVariants();
    
        Log.d('Available variants: $variants');
        
        if (variants.contains(iconName)) {
          Log.d('Variant found, aproving');
          await BeeDynamicLauncher.applyVariant(iconName);
                    
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('currentIcon', iconName);

          final current = await BeeDynamicLauncher.getCurrentVariant();
          Log.i('Current variant after change: $current');
          
          if (context.mounted) {
            BotToast.showText(
              text: "Icon changed to $label",
              duration: const Duration(seconds: 2),
              textStyle: const TextStyle(color: Colors.white, fontSize: 14),
              clickClose: true,
            );
          }
        } else {
          Log.i('Variant $iconName not found in $variants');
          if (context.mounted) {
            BotToast.showText(
              text: "Variant not available",
              duration: const Duration(seconds: 2),
            );
          }
        }
      } catch (e, st) {
       Log.h(e, st, "Error");
        if (context.mounted) {
            BotToast.showText(
              text: "Error $e",
              duration: const Duration(seconds: 2),
            );
        }
      }
    } else {
      if (context.mounted) {
          Log.i('Not supported on this platform');
             BotToast.showText(
              text: "Not supported in this platform",
              duration: const Duration(seconds: 2),
            );
      }
    }
  }

  @override 
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () { 
          MusicService.playClick();
        _changeIcon(context);
      },
      child: Container(
        width: 100,
      decoration: BoxDecoration(
          color: isActive ? Colors.purple.shade800 : Colors.grey.shade900,
          borderRadius: BorderRadius.circular(16),
          border: isActive ? Border.all(color: Colors.purple.shade400, width: 2) : null,
        ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.asset(
            previewImagePath,
            width: 56,
            height: 56,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
                  width: 56,
                  height: 56,
                  color: Colors.grey.shade800,
                  child: Icon(Icons.image_not_supported, color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.purple.shade300 : Colors.white,
                fontSize: 12,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal
                ),
            ),
          ],
        ),
      ),
    );
  }
}
