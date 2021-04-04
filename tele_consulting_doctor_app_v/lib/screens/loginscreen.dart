import 'package:flutter/material.dart';
import 'package:tele_consulting_doctor_app_v/models/firebase.dart';
import 'package:tele_consulting_doctor_app_v/models/shared.dart';

class LogInScrn extends StatefulWidget {
  final Function toggleScreen;
  LogInScrn({this.toggleScreen});

  _LogInScrnState createState() => _LogInScrnState();
}

class _LogInScrnState extends State<LogInScrn> {
  final _formkey = GlobalKey<FormState>();
  String _email = '';
  String _password = '';

  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.lightBlue[50],
      appBar: AppBar(
          title: Text("Tele-Consulting Doctor"),
          backgroundColor: Colors.lightBlue[700],
          actions: <Widget>[
            TextButton.icon(
                style: ButtonStyle(
                    foregroundColor:
                        MaterialStateProperty.all<Color>(Colors.white)),
                onPressed: () {
                  widget.toggleScreen();
                },
                icon: Icon(Icons.person_add),
                label: Text("Register"))
          ]),
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60.0, horizontal: 30.0),
        child: Form(
          key: _formkey,
          child: Column(
            children: [
              TextFormField(
                decoration: inputdecoration.copyWith(hintText: 'Email'),
                validator: (value) {
                  if (value.isEmpty) {
                    return 'Please enter some text';
                  }
                  return null;
                },
                onChanged: (val) {
                  _email = val;
                },
              ),
              SizedBox(height: 30.0),
              TextFormField(
                obscureText: true,
                decoration: inputdecoration.copyWith(hintText: 'Password'),
                validator: (value) {
                  if (value.characters.length <= 6) {
                    return 'Password length should be atleast 6';
                  }
                  return null;
                },
                onChanged: (val) {
                  setState(() {
                    _password = val;
                  });
                },
              ),
              SizedBox(height: 30.0),
              ElevatedButton(
                  onPressed: () async {
                    if (_formkey.currentState.validate()) {
                      await Authenticate().signInWithEmailAndPassword(
                          _email, _password, context);
                    }
                  },
                  child: Text("Sign In"))
            ],
          ),
        ),
      ),
    );
  }
}
