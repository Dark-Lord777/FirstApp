import 'package:flutter/material.dart';
import 'package:wheel_of_fortune/services/app_config_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _starsEnabled = false;

  @override
  void initState() {
  super.initState();
  _starsEnabled = AppConfigService().starsEnabled;
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
          child: Column(
          children: [
          Card(
            color: const Color(0xFF2D1B4E),
            shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: SwitchListTile(
            title: const Text(
              'Experemental stars',
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
                'Experimental features may cause lag and crashes. Enable at your own risk',
              style: TextStyle(color: Colors.white70, fontSize: 12),
                     ),
                 ),
              ],
            ),
          ),
        );
      }
  }
