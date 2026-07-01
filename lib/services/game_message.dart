import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';


import 'package:wheel_of_fortune/widgets/base_anim_btn.dart';
import 'package:wheel_of_fortune/services/app_config_service.dart';

class GameMessage {
  static Future<void> show({
    required BuildContext context,
    String title = "",
    required String text,

    MessageIcon icon = MessageIcon.info,
    MessageGradient gradient = MessageGradient.purple,
    List<MessageButton> buttons = const [],

    MessageButtonsAlignment alignment = MessageButtonsAlignment.center,

    bool closeOnTapOutside = false,
    
  }) async {
    await showDialog(
      context: context,
      barrierDismissible: closeOnTapOutside,
      builder: (_) {
        return Dialog (
          backgroundColor: Colors.transparent,
          child: Container(
            width: 430,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
                colors: gradient.colors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
                border: Border.all(
                color: Colors.white.withOpacity(.15),
              ),
              boxShadow: [
                BoxShadow(
                  color: gradient.colors.first.withOpacity(.35),
                  blurRadius: 25,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon.icon,
                  size: 40,
                  color: icon.color,
                ),
                const SizedBox(height: 12),
                if (title.isNotEmpty)
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                if (title.isNotEmpty)
                const SizedBox(height: 12),
                Text(
                  text,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 17,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 18),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 10,
                  runSpacing: 10,
                  children: buttons.map((button) {
                    return BaseAnimatedButton(
                        text: button.text,
                        gradientColors: button.gradient.colors,
                    textColor: Colors.white,
                    fontSize: 18,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                        ),
                      onPressed: () {
                          Navigator.pop(context);
                          button.onPressed?.call();
                        },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  static Future<bool> wasShown(String key) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(key) ?? false;
}

static Future<void> markShown(String key) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(key, true);
}

}

enum MessageButtonsAlignment {
  left(MainAxisAlignment.start),
  center(MainAxisAlignment.center),
  right(MainAxisAlignment.end),
  spaceBetween(MainAxisAlignment.spaceBetween);
  
  final MainAxisAlignment value;
  const MessageButtonsAlignment(this.value);
}
class MessageGradient {
  final List<Color> colors;

  const MessageGradient._(
    this.colors,
  );

  static const purple = MessageGradient._([
    Color(0xFFB874EC),
    Color(0xFF6D39C8),
]);
  static const red = MessageGradient._([
    Color(0xFFE53935),
    Color(0xFF8E0000),
]);
  static const green = MessageGradient._([
    Color(0xFF2ECC71),
    Color(0xFF0E9F4B),
]);
  static const blue = MessageGradient._([
    Color(0xFF2196F3),
    Color(0xFF1565C0),
]);
  static const orange = MessageGradient._([
    Color(0xFFFF9800),
    Color(0xFFE65100),
]);
  static const gold = MessageGradient._([
    Color(0xFFFFD54F),
    Color(0xFFFFB300),
]);
  static const dark = MessageGradient._([
    Color(0xFF2A1A3A),
    Color(0xFF171726),
]);

}

class MessageIcon {
  final IconData icon;

  final Color color;

  const MessageIcon._(
    this.icon,
    this.color,
  );
  static const info = MessageIcon._(
    Icons.info,
    Colors.lightBlue,
  );
  static const warning = MessageIcon._(
    Icons.warning_amber_rounded,
    Colors.orange,
  );
  static const success = MessageIcon._(
    Icons.check_circle,
    Colors.greenAccent,
  );
  static const error = MessageIcon._(
    Icons.error,
    Colors.redAccent,
  );
  static const music = MessageIcon._(
    Icons.music_note,
    Colors.deepPurpleAccent,
  );
  static const download = MessageIcon._(
    Icons.download,
    Colors.lightBlueAccent,
  );
  static const update = MessageIcon._(
    Icons.system_update,
    Colors.amber,    
  );
  static const settings = MessageIcon._(
    Icons.settings,
    Colors.white,
  );
  static const gift = MessageIcon._(
    Icons.card_giftcard,
    Colors.pinkAccent,
  );
  static const coin = MessageIcon._(
    Icons.monetization_on,
    Colors.amberAccent,
  );

}

class MessageButton {
  final String text;
  final MessageGradient gradient;
  final VoidCallback? onPressed;

  const MessageButton(
    this.text,
    this.gradient,
    this.onPressed,
  );

  factory MessageButton.ok({
    VoidCallback? onPressed,
  }) {
    return MessageButton(
    "OK",
    MessageGradient.green,
    onPressed,
    );
  }
  factory MessageButton.cancel({
    VoidCallback? onPressed,
  }) {
    return MessageButton(
      "Cancel",
      MessageGradient.red,
      onPressed,
    );
  }
  factory MessageButton.yes({
    VoidCallback? onPressed,
  }) {
    return MessageButton(
      "Yes",
      MessageGradient.green,
    onPressed,
    );
  }
  factory MessageButton.no({
    VoidCallback? onPressed,
  }) {
    return MessageButton(
      "No",
    MessageGradient.red,
    onPressed,
    );
  }
  factory MessageButton.retry({
    VoidCallback? onPressed,
  }) {
    return MessageButton(
    "Retry",
    MessageGradient.orange,
    onPressed,
  );
}
factory MessageButton.download({
  VoidCallback? onPressed,
}) {
    return MessageButton(
      "Download",
    MessageGradient.blue,
    onPressed,
    );
  }
factory MessageButton.continueButton({
  VoidCallback? onPressed,
}) {
    return MessageButton(
      "Continue",
    MessageGradient.purple,
    onPressed,
    );
  }
factory MessageButton.close({
  VoidCallback? onPressed,
}) {
    return MessageButton(
      "Close",
    MessageGradient.dark,
    onPressed,
    );
  }
factory MessageButton.custom({
  required String text,
  required MessageGradient gradient,
  VoidCallback? onPressed,
}) {
    return MessageButton(
      text,
      gradient,
      onPressed,
    );
  }
  factory MessageButton.tgchannel({
  VoidCallback? onPressed,
}) {
  return MessageButton(
    "Telegram",
    MessageGradient.blue,
    () async {
        final uri = Uri.parse(AppConfigService().tgChannel);
        await launchUrl(uri);
      }
  );
}
}
