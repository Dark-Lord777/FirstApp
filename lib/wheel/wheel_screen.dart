import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint; 

import 'package:flutter/material.dart';
import 'package:wheel_of_fortune/widgets/spin_btn.dart';
import 'package:wheel_of_fortune/widgets/reset_btn.dart';
import 'package:wheel_of_fortune/widgets/add_btn.dart';
import 'package:wheel_of_fortune/widgets/modalka.dart';
import 'package:wheel_of_fortune/wheel/wheel.dart';
import 'package:wheel_of_fortune/wheel/logic.dart'; 
import 'package:wheel_of_fortune/services/config_service_interface.dart';
import 'package:wheel_of_fortune/services/database_service.dart';

class WheelScreen extends StatefulWidget {
  final ConfigServiceInterface configService;
  const WheelScreen({required this.configService, super.key});

  @override
  State<WheelScreen> createState() => _WheelScreenState();
}

class _WheelScreenState extends State<WheelScreen> with TickerProviderStateMixin {
  List<String> sectors = [];
  late WheelLogic _wheelLogic;
  double _currentRotationAngle = 0.0;

  String titleText = "";

  @override
  void initState() {
    super.initState();
    
    _applyConfig();
    
    _wheelLogic = WheelLogic(
      vsync: this,  
      onAngleChanged: () {
        setState(() {
          _currentRotationAngle = _wheelLogic.currentAngle;
        });
      },
      onWin: (String prize) async  {
        debugPrint("PRIZE $prize}");
        if (!kIsWeb) {
        await DatabaseService.instance.saveSpin(prize, true);
        }
      },
      sectors: sectors,
    );
  }
  void _applyConfig() {
    final config = widget.configService.currentConfig;
    setState(() {
      titleText = config['titleText'] ?? "";
    });
  }

Future<void> _showAddSectorDialog() async {
  final result = await showAddSectorDialog(
    context: context,
    title: "Add New Sector",
    hintText: "Enter sector name...",
    errorText: "Please enter sector name",
    buttonText: "Add",
    icon: Icons.add_circle_outline_rounded,
  );
    if (result !=null && result.isNotEmpty) {
    setState(() {
    sectors.add(result);
    _wheelLogic.updateSectors(sectors);
    });
    }
  }

Future<void> _showChangeTitleDialog() async {
  final newTitle = await showAddSectorDialog(
    context: context,
    title: "Change Title",
    hintText: "Enter new title...",
    buttonText: "Change",
    icon: Icons.title,
    initialValue: titleText,
    errorText: "Please enter title",
  );
   if (newTitle !=null && newTitle.isNotEmpty) {
    setState(() {
    titleText = newTitle;
    });
    }
  }


  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isLandscape = screenWidth > screenHeight;
    final isTablet = screenWidth > 600;
    final isSmallWindow = screenWidth < 500;
    
    final topPadding = screenHeight * (isLandscape ? 0.05 : 0.13);
    final wheelTop = screenHeight * (isLandscape ? 0.15 : 0.25);
    final bottomButtons = screenHeight * 0.23;
    final addButtonBottom = screenHeight * 0.06;

    double titleFontSize;
    if (isTablet) {
      titleFontSize = 50.0;
    } else if (isSmallWindow) {
      titleFontSize = 24.0;
    } else {
      titleFontSize = screenWidth * 0.08;
    }
    titleFontSize = titleFontSize.clamp(20.0, 50.0);
    
    final leftRightOffset = screenWidth * 0.05;
    return LayoutBuilder (
      builder: ( context, constraints ) {
        final availableWidth = constraints.maxWidth;
      
    

    return Scaffold(
      resizeToAvoidBottomInset: false,
      drawer: const SettingsDrawer(),
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
            Positioned(
              top: topPadding,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: _showChangeTitleDialog,
                  child: Text(
                  titleText,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.yellow.shade500,
                      fontSize: titleFontSize,
                      fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
            
            Positioned(
              top: wheelTop,
              left: 0,
              right: 0,
              child: Center(
                child: WheelDraw(
                  sectors: sectors,
                  rotationAngle: _currentRotationAngle, 
                  availableWidth: availableWidth,
                ),
              ),
            ),
            
            Positioned(
              left: leftRightOffset,
              bottom: bottomButtons,
              child: ResetButton(
                onPressed: () {
                  setState(() {
                    sectors.clear();
                    _wheelLogic.updateSectors(sectors); 
                  });
                },
              ),
            ),
            
            Positioned(
              left: 0,
              right: 0,
              bottom: addButtonBottom,
              child: Center(
                child: AddBtn(
                onPressed: _showAddSectorDialog,
               /*   onSectorAdded: (String sectorName) {
                    setState(() {
                      sectors.add(sectorName);
                      _wheelLogic.updateSectors(sectors);
                    });
                  },*/ 
                ),
              ),
            ),
            
            Positioned(
              right: leftRightOffset,
              bottom: bottomButtons,
              child: SpinBtn(
                onPressed: () {
                  if (sectors.isEmpty) {
                    return; 
                  }
                  _wheelLogic.spin();
                },
              ),
            ),
            Positioned(
                  top: MediaQuery.of(context).padding.top + 8,
                  left: 16,
                  child: Builder(
                    builder: (context) => GestureDetector(
                      onTap: () => Scaffold.of(context).openDrawer(),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.menu, color: Colors.yellow.shade500, size: 28),
                      ),
                    ),
                  ),
                ),
              //add btn 
          ],    
        ),     
      ),      
    );      
  },
);
}

  @override
  void dispose() {
    _wheelLogic.dispose();
    super.dispose();
  }
}
