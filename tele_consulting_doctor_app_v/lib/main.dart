import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:tele_consulting_doctor_app_v/models/firebase.dart';
import 'package:tele_consulting_doctor_app_v/screens/wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamProvider<MyUser>.value(
      value: Authenticate().user,
      initialData: null,
      child: MaterialApp(
        color: Colors.lightBlue[700],
        home: Wrapper(),
      ),
    );
  }
}
