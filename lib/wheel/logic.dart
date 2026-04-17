import 'dart:math';
import 'package:flutter/material.dart';


class _FortuneRandom {
  int _seed;
  int _callCounter = 0;
  static const int _MASK = 0xFFFFFFFF;

  _FortuneRandom() : _seed = DateTime.now().microsecondsSinceEpoch & _MASK;

  int _xorshift32() {
    _seed ^= (_seed << 13) & _MASK;
    _seed ^= (_seed >> 17) & _MASK;
    _seed ^= (_seed << 5) & _MASK;
    return _seed;
  }

  double nextDouble() {
    int randomInt = _xorshift32();
    randomInt = (randomInt + _callCounter) & _MASK;
    _callCounter++;
    if (_callCounter > 1000000) _callCounter = 0;
    return randomInt / 4294967296.0;
  }

  double nextDoubleRange(double min, double max) {
    return min + nextDouble() * (max - min);
  }

  int nextInt(int min, int max) {
    return min + (nextDouble() * (max - min + 1)).floor();
  }
}

class _SmoothCurve extends Curve {
  const _SmoothCurve();
  
  @override
  double transform(double t) {
    // КВАДРАТИЧНОЕ ЗАМЕДЛЕНИЕ - плавно замедляется к концу
    //return 1 - (1 - t) * (1 - t);
    
    // Кубическое замедление (ещё плавнее)
     return 1 - (1 - t) * (1 - t) * (1 - t);
    
    // Четвертичное замедление (очень плавное)
    // return 1 - pow(1 - t, 4);
    
    // С отскоком в конце
     return Curves.bounceOut.transform(t);
  }
}

class WheelLogic {
  late AnimationController _controller;
  late Animation<double> _animation;
  
  double _currentAngle = 0.0;
  double _startAngle = 0.0;
  double _targetDelta = 0.0;
  bool _isSpinning = false;
  
  final _FortuneRandom _random = _FortuneRandom();
  final VoidCallback onAngleChanged;
  final Function(String prize) onWin;
  List<String> sectors;
  
  static const double SPIN_DURATION_SECONDS = 9.0;  
  
  WheelLogic({
    required TickerProvider vsync,
    required this.onAngleChanged,
    required this.onWin,
    required this.sectors,
  }) {
    _controller = AnimationController(
      vsync: vsync,
      duration: Duration(milliseconds: (SPIN_DURATION_SECONDS * 1000).round()),
    );
    
    _animation = CurvedAnimation(
      parent: _controller,
      curve: _SmoothCurve(),  
    );
    
    _controller.addListener(_onAnimationFrame);
    _controller.addStatusListener(_onAnimationEnd);
  }
  
  double get currentAngle => _currentAngle;
  bool get isSpinning => _isSpinning;
  
  void spin() {
    if (_isSpinning) return;
    if (sectors.isEmpty) return;
    
    _startAngle = _currentAngle;
    
    int fullRotations = _random.nextInt(15, 30);  
    double landingAngle = _random.nextDouble() * 2 * pi;
    _targetDelta = fullRotations * 2 * pi + landingAngle;
    
    //print('🎡 Вращение: $fullRotations оборотов, длительность: ${SPIN_DURATION_SECONDS} сек');
    
    _isSpinning = true;
    _controller.forward(from: 0.0);
  }
  
  void _onAnimationFrame() {
    double progress = _animation.value;
    _currentAngle = _startAngle + (_targetDelta * progress);
    onAngleChanged();
  }
  
  void _onAnimationEnd(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      double finalAngle = _currentAngle % (2 * pi);
      if (finalAngle < 0) finalAngle += 2 * pi;
      
      String prize = _getSectorByAngle(finalAngle);
      //print('Winner : $prize');
      
      _isSpinning = false;
      onWin(prize);
    }
  }
  
  String _getSectorByAngle(double angle) {
    if (sectors.isEmpty) return "No sectors";
    
    int sectorsCount = sectors.length;
    double anglePerSector = (2 * pi) / sectorsCount;
    
    double normalizedAngle = angle % (2 * pi);
    if (normalizedAngle < 0) normalizedAngle += 2 * pi;
    
    double correctedAngle = normalizedAngle - pi / 2;
    if (correctedAngle < 0) correctedAngle += 2 * pi;
    
    int sectorIndex = (correctedAngle / anglePerSector).floor();
    if (sectorIndex >= sectorsCount) sectorIndex = 0;
    
    return sectors[sectorIndex];
  }
  
  void updateSectors(List<String> newSectors) {
    sectors = newSectors;
  }
  
  void dispose() {
    _controller.dispose();
  }
}
