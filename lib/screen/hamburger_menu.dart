import 'package:flutter/material.dart';
import 'package:wheel_of_fortune/widgets/menu/change_icon.dart';
import 'package:wheel_of_fortune/widgets/menu/about_btn.dart';
import 'package:wheel_of_fortune/services/icon_catalog_service.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:url_launcher/url_launcher.dart';
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
    if (await canLaunchUrl(uri)) {
    await launchUrl(uri);
    } else {
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
      _currentIcon = prefs.getString('currentIcon') ?? 'deault';
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
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.8,
      backgroundColor: const Color(0xFF1A1A2E),
      child: SafeArea(
        child: Column(
          children: [
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
                  Text(
                    'Settings',
                    style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const Text(
                    'Wheel Of Fortune',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: EdgeInsets.only(left: 8, bottom: 8),
                        child: Text(
                          'App Icon',
                          style: TextStyle(color: Colors.purple, fontSize: 12, fontWeight: FontWeight.bold),
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
                    const SizedBox(height: 24),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: EdgeInsets.only(left: 8, bottom: 8),
                        child: Text(
                          'System',
                          style: TextStyle(color: Colors.purple, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    ListTile(
                      leading: Icon(Icons.share, color: Colors.purple),
                      title: Text('Share App'),
                      onTap: () {
                        BotToast.showText(text: "Coming soon");
                        },
                    ),
                    ListTile(
                      leading: Icon(Icons.description, color: Colors.purple),
                      title: Text('Terms & Conditions'),
                      onTap: () {
                        BotToast.showText(text: "Coming soon");
                  //      _launchUrl('https://mysyte.com/terms');
                      },
                    ),
                    ListTile(
                      leading: Icon(Icons.privacy_tip, color: Colors.purple),
                      title: Text('Privacy Policy'),
                      onTap: () {
                        BotToast.showText(text: "Coming soon");
                    //    _launchUrl('https://mysyte.com/privacy');
                      },
                    ),
                    const Divider(color: Colors.grey),
                    const AboutBtn(),
                    //end of elements
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
