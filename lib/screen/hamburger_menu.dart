import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // needed for kReleaseMode 
import 'package:wheel_of_fortune/widgets/menu/change_icon.dart';
import 'package:wheel_of_fortune/services/icon_catalog_service.dart';
import 'package:wheel_of_fortune/services/app_config_service.dart';

import 'package:bot_toast/bot_toast.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsDrawer extends StatefulWidget {
  const SettingsDrawer({super.key});

  @override
  State<SettingsDrawer> createState() => _SettingsDrawerState();
}

class _SettingsDrawerState extends State<SettingsDrawer> {
  List<Map<String, dynamic>> _iconVariants = [];
  bool _isLoading = true;
  String _currentIcon = 'default';

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        BotToast.showText(text: "Cannot open link");
      }
    }
  } 

  @override
  void initState() {
    super.initState();
    _loadIconVariants();
    _loadCurrentIcon();
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

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Drawer(
      width: MediaQuery.of(context).size.width * 0.8,
      backgroundColor: const Color(0xFF1A1A2E),
      child: SafeArea(
        child: Column(
          children: [
            // Шапка меню
            Container(
              padding: const EdgeInsets.all(24),
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.purple.shade800, Colors.purple.shade600],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.menu, color: Colors.white, size: 32),
                  const SizedBox(height: 16),
                  const Text(
                    'Settings',
                    style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const Text(
                    'Wheel Of Fortune',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
            
            Expanded(
              child: CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: EdgeInsets.only(left: 8, bottom: 8),
                            child: Text(
                              'App Icon',
                              style: TextStyle(color: Colors.purple, fontSize: 14, fontWeight: FontWeight.bold),
                            ),
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
                        const SizedBox(height: 24),
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: EdgeInsets.only(left: 8, bottom: 8),
                            child: Text(
                              'System',
                              style: TextStyle(color: Colors.purple, fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        ListTile(
                          leading: const Icon(Icons.share, color: Colors.purple),
                          title: const Text('Share App'),
                          onTap: () {
                            Share.share(AppConfigService().shareUrl);
//                        Share.share('Check out Wheel of Fortune: Stars Edition! Download it here:\nhttps://uptodown.com');

                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.description, color: Colors.purple),
                          title: const Text('Terms & Conditions'),
                          onTap: () => _launchUrl(AppConfigService().termsUrl),
                        ),
                        ListTile(
                          leading: const Icon(Icons.privacy_tip, color: Colors.purple),
                          title: const Text('Privacy Policy'),
                          onTap: () => _launchUrl(AppConfigService().privacyUrl),
                        ),
                        const Divider(color: Colors.grey),
                        ListTile(
                          leading: const Icon(Icons.info, color: Colors.purple),
                          title: const Text('About the app'),
                          onTap: () {
                            showAboutDialog(
                              context: context,
                              applicationName: 'Wheel of Fortune',
                              applicationVersion: '1.0.1',
                              applicationIcon: const Icon(Icons.casino, size: 30),
                              children: const [
                                Text('Dynamic icon changer'),
                                Text('Made with Flutter'),
                              ],
                            );
                          },
                        ),
                      ]),
                    ),
                  ),
                  
                  // Прижимаем лицензию к низу экрана
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: EdgeInsets.only(bottom: screenHeight * 0.02, left: 16, right: 16),
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 4,
                          runSpacing: 4,
                          children: [
                            Text(
                              'By using this app, you agree to our',
                              style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                            ),
                            GestureDetector(
                              onTap: () => _launchUrl(AppConfigService().termsUrl),
                              child: const Text(
                                'Terms',
                                style: TextStyle(
                                  color: Colors.purpleAccent, 
                                  fontSize: 11, 
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

