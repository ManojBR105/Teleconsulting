import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:doctor_app/models/firebase.dart';
import 'package:doctor_app/screens/authenticatescreen.dart';
import 'package:doctor_app/screens/homescreen.dart';

class Wrapper extends StatelessWidget {
  Widget build(BuildContext context) {
    final user = Provider.of<MyUser>(context);
    return (user != null) ? HomeScrn(user) : AuthenticateScrn();
  }
}
