import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:doctor_app/models/firebase.dart';
import 'package:doctor_app/screens/wrapper.dart';

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
