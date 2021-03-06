import 'package:flutter/material.dart';
import 'package:doctor_app/screens/loginscreen.dart';
import 'package:doctor_app/screens/registerscreen.dart';

class AuthenticateScrn extends StatefulWidget {
  @override
  _AuthenticateScrnState createState() => _AuthenticateScrnState();
}

class _AuthenticateScrnState extends State<AuthenticateScrn> {
  bool _isloginscreen = true;

  void toggleScreen() {
    setState(() {
      _isloginscreen = !_isloginscreen;
    });
  }

  Widget build(BuildContext context) {
    if (_isloginscreen) {
      return LogInScrn(toggleScreen: toggleScreen);
    }
    return RegisterScrn(toggleScreen: toggleScreen);
  }
}
