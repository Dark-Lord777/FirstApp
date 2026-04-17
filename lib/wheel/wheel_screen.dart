// файл: lib/wheel/wheel_screen.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import '../widgets/spin_btn.dart';
import '../widgets/reset_btn.dart';
import '../widgets/add_btn.dart';
import '../wheel/wheel.dart';
import '../wheel/logic.dart'; // ← ПОДКЛЮЧАЕМ НАШУ ЛОГИКУ

class WheelScreen extends StatefulWidget {
  const WheelScreen({super.key});

  @override
  State<WheelScreen> createState() => _WheelScreenState();
}

class _WheelScreenState extends State<WheelScreen> with TickerProviderStateMixin {
  // Список секторов
  List<String> sectors = [];
  
  // КОНТРОЛЛЕР ЛОГИКИ ВРАЩЕНИЯ
  late WheelLogic _wheelLogic;
  
  // Текущий угол для передачи в WheelDraw
  double _currentRotationAngle = 0.0;

  @override
  void initState() {
    super.initState();
    
    // ИНИЦИАЛИЗАЦИЯ ЛОГИКИ
    _wheelLogic = WheelLogic(
      vsync: this,  // нужно для анимации (with TickerProviderStateMixin)
      onAngleChanged: () {
        // Этот колбэк вызывается при каждом кадре анимации
        setState(() {
          _currentRotationAngle = _wheelLogic.currentAngle;
        });
      },
      onWin: (String prize) {
        // Диалог убран - только вывод в консоль
        print('🏆 ВЫИГРЫШ: $prize');
      },
      sectors: sectors,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF1A1A1A),
              Color(0xFF201A30),
              Color(0xFF2A1A3A),
              Color(0xFF321D4F),
              Color(0xFF3D1F6D),
              Color(0xFF48247B),
              Color(0xFF552A8A),
              Color(0xFF613099),
              Color(0xFF7038A8),
              Color(0xFF7D41B8),
              Color(0xFF8B4BC8),
              Color(0xFF9858D4),
              Color(0xFFA865E0),
              Color(0xFFB874EC)
            ],
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
          ),
        ),
        child: Stack(
          children: [
            // Заголовок
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
            
            // КОЛЕСО (теперь передаём угол поворота)
            Positioned(
              top: 240,
              left: 0,
              right: 0,
              child: Center(
                child: WheelDraw(
                  sectors: sectors,
                  rotationAngle: _currentRotationAngle, // ← угол из логики
                ),
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
                    _wheelLogic.updateSectors(sectors); // ← обновляем в логике
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
                      _wheelLogic.updateSectors(sectors); // ← обновляем в логике
                    });
                  },
                ),
              ),
            ),
            
            // SPIN кнопка (теперь вызывает spin из логики)
            Positioned(
              right: 30,
              bottom: 180,
              child: SpinBtn(
                onPressed: () {
                  if (sectors.isEmpty) {
                    // Если секторов нет — показываем предупреждение
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Сначала добавьте сектора!'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }
                  _wheelLogic.spin(); // ← ЗАПУСКАЕМ ВРАЩЕНИЕ
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  @override
  void dispose() {
    _wheelLogic.dispose(); // ← ВАЖНО: очищаем контроллер
    super.dispose();
  }
}
