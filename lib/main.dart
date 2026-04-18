import 'package:flutter/material.dart';
import 'wheel/wheel_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: WheelScreen(),
    );
  }
}

//i add this line for test workflow/ anad the future i remove this line
