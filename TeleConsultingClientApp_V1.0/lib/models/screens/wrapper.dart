import 'package:client_app/models/firebase.dart';
import 'package:flutter/material.dart';
import 'package:client_app/models/screens/authenticatescreen.dart';
import 'package:client_app/models/screens/homescreen.dart';
import 'package:provider/provider.dart';

class Wrapper extends StatelessWidget {
  Widget build(BuildContext context) {
    final user = Provider.of<MyUser>(context);
    return (user != null) ? HomeScrn(user) : AuthenticateScrn();
  }
}
