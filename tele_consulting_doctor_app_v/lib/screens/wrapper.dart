import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tele_consulting_doctor_app_v/models/firebase.dart';
import 'package:tele_consulting_doctor_app_v/screens/authenticatescreen.dart';
import 'package:tele_consulting_doctor_app_v/screens/homescreen.dart';

class Wrapper extends StatelessWidget {
  Widget build(BuildContext context) {
    final user = Provider.of<MyUser>(context);
    return (user != null) ? HomeScrn(user) : AuthenticateScrn();
  }
}
