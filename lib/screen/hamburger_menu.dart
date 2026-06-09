import 'package:flutter/material.dart';
import 'package:wheel_of_fortune/widgets/menu/change_icon.dart';
import 'package:wheel_of_fortune/widgets/menu/about_btn.dart';

class SettingsDrawer extends StatelessWidget {
  const SettingsDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.65,
      backgroundColor: Color(0xFF1A1A2E),
      child: SafeArea(
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(24),
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
                    style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Wheel Of Fortune',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                   Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: EdgeInsets.only(left: 8, bottom: 8),
                        child: Text(
                          'App Icon',
                          style: TextStyle(color: Colors.purple.shade300, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    ChangeIconBtn(iconName: 'default', label: 'Default', iconData: Icons.circle),
                    const SizedBox(height: 12),
                    ChangeIconBtn(iconName: '777', label: 'Lucky 777', iconData: Icons.auto_awesome),
                    const SizedBox(height: 12),
                    ChangeIconBtn(iconName: 'pink', label: 'Pink', iconData: Icons.favorite),
                    const SizedBox(height: 24),

                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: EdgeInsets.only(left: 8, bottom: 8),
                        child: Text(
                          'System',
                          style: TextStyle(color: Colors.purple.shade300, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    
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
