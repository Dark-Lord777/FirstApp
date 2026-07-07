import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:wheel_of_fortune/screen/welcome.dart';
import 'package:wheel_of_fortune/wheel/wheel_screen.dart';
import 'package:wheel_of_fortune/services/logger.dart';


class RoutingService {
  static final RoutingService _instance = RoutingService._internal();
  factory RoutingService() => _instance;
  RoutingService._internal();

  static const String _keyNickname = 'user_nickname';
  static const String _keyIsGuest = 'is_guest';
  static const String _keyIsRegistered = 'is_registered';

  bool _isInitialized = false;
  String? _nickname;
  bool _isGuest = false;
  bool _isRegistered = false;

  bool get isRegistered => _isRegistered;
  bool get isGuest => _isGuest;
  String? get nickname => _nickname;

  Future<void> init() async {
    if (_isInitialized) return;

    final prefs = await SharedPreferences.getInstance();

    _nickname = prefs.getString(_keyNickname);
    _isGuest = prefs.getBool(_keyIsGuest) ?? false;
    _isRegistered = prefs.getBool(_keyIsRegistered) ?? false;

    if (_nickname != null && _nickname!.isNotEmpty) {
      if (_isRegistered) {
      _isRegistered = true;
    } else  if (_isGuest) {
      _isRegistered = false;
      _isGuest = true;
    }
  } else {
    _isRegistered = false;
    _isGuest = false;
  }
    _isInitialized = true;
    Log.i("RoutingService Initialized: registered=$_isRegistered, guest=$_isGuest, nick=$_nickname");
  }

  Future<void> registerUser(String nickname) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_keyNickname, nickname);
    await prefs.setBool(_keyIsRegistered, true);
    await prefs.setBool(_keyIsGuest, false);

    _nickname = nickname;
    _isRegistered = true;
    _isGuest = false;

    Log.i("User registered: $nickname");
    Log.i(' Saved to prefs: nickname=$nickname, isRegistered=true');
  }


  Future<void> registerGuest(String guestNick) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_keyNickname, guestNick);
    await prefs.setBool(_keyIsGuest, true);
    await prefs.setBool(_keyIsRegistered, false);

    _nickname = guestNick;
    _isGuest = true;
    _isRegistered = false;
    Log.i('Guest registered: $guestNick');
  }

  Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_keyNickname);
    await prefs.remove(_keyIsGuest);
    await prefs.remove(_keyIsRegistered);

    _nickname = null;
    _isGuest = false;
    _isRegistered = false;

    Log.i('RoutingService reset');
  }

  //ogic of routing 

  Widget getInitialScreen() {
    if (_isRegistered || _isGuest) {
      Log.i('User already: nickname=$nickname, goind to WheelScreen');
      return const WheelScreen();
    } else {
      Log.i('No user found, showing WelcomeScreen');
      return const WelcomeScreen();
    }
  }
  //routing 

  void  navigateToWheel(BuildContext context) {
    FocusScope.of(context).unfocus();
    Navigator.pushReplacement(
      context,
    MaterialPageRoute(builder: (context) => const WheelScreen()),
    );
  }


  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyNickname);
    await prefs.remove(_keyIsRegistered);
    await prefs.remove(_keyIsGuest);

    _nickname = null;
    _isGuest = false;
    _isRegistered = false;
  }
}
