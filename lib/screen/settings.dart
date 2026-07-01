import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bot_toast/bot_toast.dart';

import 'package:wheel_of_fortune/services/app_config_service.dart';
import 'package:wheel_of_fortune/services/icon_catalog_service.dart';
import 'package:wheel_of_fortune/widgets/menu/change_icon.dart';
import 'package:wheel_of_fortune/services/music_service.dart';
import 'package:wheel_of_fortune/services/game_message.dart';
import 'package:wheel_of_fortune/screen/welcome.dart';
import 'package:wheel_of_fortune/services/database_service.dart';


class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _starsEnabled = false;
  bool _spinSoundEnabled = true;
  bool _winSoundEnabled = true;
  bool _backgroundMusicEnabled = true;

  List<Map<String, dynamic>> _iconVariants = [];
  bool _isLoading = true;
  String _currentIcon = 'default';

  @override
  void initState() {
    super.initState();
    _loadIconVariants();
    _loadCurrentIcon();
    _starsEnabled = AppConfigService().starsEnabled;
    _spinSoundEnabled = AppConfigService().spinSoundEnabled;
    _winSoundEnabled = AppConfigService().winSoundEnabled;
    _backgroundMusicEnabled = AppConfigService().backgroundMusicEnabled;
  }

  Future<void> _loadCurrentIcon() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentIcon = prefs.getString('currentIcon') ?? 'default';
    });
  }

  Future<void> _loadIconVariants() async {
    final variants = await IconCatalogService.getIconVariants();
    setState(() {
      _iconVariants = variants;
      _isLoading = false;
    });
  }

  Future<void> _resetAllData() async {
    await GameMessage.show(
      context: context,
      title: '⚠️ Reset All Data?',
      text: 'This will delete ALL app data:\n'
            '• Nickname & Settings\n'
            '• Game history & Sectors\n'
            '• Downloaded music\n'
            '• Everything!\n\n'
            'This cannot be undone!',
      icon: MessageIcon.warning,
      gradient: MessageGradient.red,
      buttons: [
        MessageButton.custom(
          text: 'Cancel',
          gradient: MessageGradient.dark,
          onPressed: () {},
        ),
        MessageButton.custom(
          text: 'Reset All',
          gradient: MessageGradient.red,
          onPressed: () async {
            try {
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              AppConfigService().resetToDefaults();
              await DatabaseService.instance.clearAllData();
              await MusicService.clearMusicCache();
              await MusicService.stopMusic();

              if (mounted) {
                BotToast.showCustomText(
                  duration: const Duration(seconds: 2),
                  align: const Alignment(0, -0.8),
                  toastBuilder: (cancelFunc) {
                    return Card(
                      color: Colors.green.shade800,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        child: Text(
                          '🧹 All data cleared! Restarting...',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  },
                );

                await Future.delayed(const Duration(seconds: 1));
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const WelcomeScreen()),
                  (route) => false,
                );
              }
            } catch (e) {
              if (mounted) {
                BotToast.showCustomText(
                  duration: const Duration(seconds: 3),
                  align: const Alignment(0, -0.8),
                  toastBuilder: (cancelFunc) {
                    return Card(
                      color: Colors.red.shade900,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        child: Text(
                          'Error: $e',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  },
                );
              }
            }
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1A1A2E),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView( // 👈 ГЛАВНОЕ ИЗМЕНЕНИЕ
          child: Column(
            children: [
              const Align(
                alignment: Alignment.center,
                child: Text(
                  'App Icon',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else
                SizedBox(
                  height: 100,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _iconVariants.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 16),
                    itemBuilder: (context, index) {
                      final variant = _iconVariants[index];
                      final String id = variant['id'];
                      final String displayName = variant['displayName'] ?? id;
                      final String imagePath = 'assets/bee_dynamic_launcher/icons/ic_${id}.png';
                      return ChangeIconBtn(
                        iconName: id,
                        label: displayName,
                        previewImagePath: imagePath,
                        isActive: _currentIcon == id,
                      );
                    },
                  ),
                ),
              Divider(color: Colors.purple.shade300),

              const Text(
                'Music',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              Card(
                color: const Color(0xFF2D1B4E),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: SwitchListTile(
                  title: const Text(
                    'Spin Sound',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  value: _spinSoundEnabled,
                  onChanged: (value) async {
                    setState(() {
                      _spinSoundEnabled = value;
                      AppConfigService().spinSoundEnabled = value;
                      MusicService.setSpinSoundEnabled(value);
                    });
                  },
                  activeColor: Colors.purple,
                  secondary: Icon(
                    _spinSoundEnabled ? Icons.volume_up : Icons.volume_off,
                    color: _spinSoundEnabled ? Colors.pink : Colors.grey,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                color: const Color(0xFF2D1B4E),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: SwitchListTile(
                  title: const Text(
                    'Win Sound',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  value: _winSoundEnabled,
                  onChanged: (value) async {
                    setState(() {
                      _winSoundEnabled = value;
                      AppConfigService().winSoundEnabled = value;
                      MusicService.setWinSoundEnabled(value);
                    });
                  },
                  activeColor: Colors.purple,
                  secondary: Icon(
                    _winSoundEnabled ? Icons.volume_up : Icons.volume_off,
                    color: _winSoundEnabled ? Colors.pink : Colors.grey,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                color: const Color(0xFF2D1B4E),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: SwitchListTile(
                  title: const Text(
                    'Background Music',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  subtitle: const Text(
                    'Plays random tracks',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  value: _backgroundMusicEnabled,
                  onChanged: (value) async {
                    setState(() {
                      _backgroundMusicEnabled = value;
                      AppConfigService().backgroundMusicEnabled = value;
                    });
                    if (!value) {
                      MusicService.stopMusic();
                      if (!await GameMessage.wasShown("music_disabled")) {
                        await GameMessage.show(
                          context: context,
                          title: "Really? You turned off the music? 🥲",
                          text: "Vote for your favourite tracks in my Telegram channel and help improve the soundtrack!",
                          icon: MessageIcon.warning,
                          gradient: MessageGradient.dark,
                          alignment: MessageButtonsAlignment.spaceBetween,
                          buttons: [
                            MessageButton.tgchannel(),
                            MessageButton.continueButton(),
                          ],
                        );
                        await GameMessage.markShown("music_disabled");
                      }
                    } else {
                      MusicService.reloadMusic(context: context);
                    }
                  },
                  activeColor: Colors.purple,
                  secondary: Icon(
                    _backgroundMusicEnabled ? Icons.volume_up : Icons.volume_off,
                    color: _backgroundMusicEnabled ? Colors.pink : Colors.grey,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              const Text(
                'Experimental settings',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              Card(
                color: const Color(0xFF2D1B4E),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: SwitchListTile(
                  title: const Text(
                    'Experimental stars',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  subtitle: const Text(
                    'May lag on older devices',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  value: _starsEnabled,
                  onChanged: (value) {
                    setState(() {
                      _starsEnabled = value;
                      AppConfigService().starsEnabled = value;
                    });
                  },
                  activeColor: Colors.purple,
                  secondary: Icon(
                    _starsEnabled ? Icons.star : Icons.star_border,
                    color: _starsEnabled ? Colors.yellow : Colors.grey,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade900.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade400),
                ),
                child: const Text(
                  'Experimental features may cause lag and crashes. \nEnable at your own risk.\nBut hey, beauty requires sacrifice... ',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),

              const SizedBox(height: 16),
              const Text(
                'Developer Tools',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              Card(
                color: const Color(0xFF2D1B4E),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  leading: const Icon(Icons.delete_forever, color: Colors.red),
                  title: const Text(
                    'Reset All Data',
                    style: TextStyle(color: Colors.red),
                  ),
                  subtitle: const Text(
                    "⚠️ This will delete ALL your data and CANNOT be undone!",
                    style: TextStyle(color: Colors.red, fontSize: 12),
                  ),
                  trailing: const Icon(Icons.warning, color: Colors.red),
                  onTap: _resetAllData,
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
