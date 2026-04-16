import 'dart:ui';
import 'package:flutter/material.dart';
import '../widgets/spin_btn.dart';
import '../widgets/reset_btn.dart';
import '../widgets/add_btn.dart';
import '../wheel/wheel.dart';

class WheelScreen extends StatefulWidget {  // ← МЕНЯЕМ НА StatefulWidget!
  const WheelScreen({super.key});

  @override
  State<WheelScreen> createState() => _WheelScreenState();
}

class _WheelScreenState extends State<WheelScreen> {
  // ПЕРЕМЕННАЯ ДЛЯ ХРАНЕНИЯ СЕКТОРОВ
  List<String> sectors = [];


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
Color(0xFF1A1A1A), // мягкий черный
Color(0xFF201A30), // чуть светлее
Color(0xFF2A1A3A), // черный с фиолетовым отливом
Color(0xFF321D4F), // промежуток
Color(0xFF3D1F6D), // темный фиолет
Color(0xFF48247B), // светлее
Color(0xFF552A8A), // насыщенный фиолет
Color(0xFF613099), // промежуток
Color(0xFF7038A8), // яркий фиолет
Color(0xFF7D41B8), // светлее
Color(0xFF8B4BC8), // светлый фиолет
Color(0xFF9858D4), // промежуток
Color(0xFFA865E0), // почти лаванда
Color(0xFFB874EC)  // еще светлее лаванда (акцент)
            ],
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
          ),
        ),
        child: Stack(
          children: [

            Positioned(
              top: 120,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  "You lucky today?",
                  style: TextStyle(
                    color: Colors.yellow.shade500,
                    fontSize: 35,
                    
                  ),
                ),
              ),
            ),
            // КОЛЕСО
            Positioned(
              top: 240,  // ← МЕНЯЙ ЭТО ЧИСЛО ДЛЯ ДВИЖЕНИЯ
              left: 0,
              right: 0,
              child: Center(
                child: WheelDraw(sectors: sectors),
              ),
            ),
            
            // RESET кнопка
            Positioned(
              left: 30,
              bottom: 180,
              child: ResetButton(
                onPressed: () {
                  setState(() {
                    sectors.clear();
                  });
                },
              ),
            ),
            
            // ADD кнопка
            Positioned(
              left: 0,
              right: 0,
              bottom: 30,
              child: Center(
                child: AddBtn(
                  onPressed: () {},
                  onSectorAdded: (String sectorName) {
                    setState(() {
                      sectors.add(sectorName);
                    });
                  },
                ),
              ),
            ),
            
            // SPIN кнопка
            Positioned(
              right: 30,
              bottom: 180,
              child: SpinBtn(
                onPressed: () {
                  print("Spin нажат!");
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
