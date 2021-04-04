import 'package:tele_consulting_doctor_app_v/models/shared.dart';
import 'package:flutter/material.dart';
import 'package:tele_consulting_doctor_app_v/models/firebase.dart';

class RegisterScrn extends StatefulWidget {
  final Function toggleScreen;

  RegisterScrn({this.toggleScreen});

  _RegisterScrnState createState() => _RegisterScrnState();
}

class _RegisterScrnState extends State<RegisterScrn> {
  final _formkey = GlobalKey<FormState>();
  String _username = '';
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
                icon: Icon(Icons.person),
                label: Text("Log In"))
          ]),
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 28.0, horizontal: 30.0),
        child: Form(
          key: _formkey,
          child: Column(
            children: [
              TextFormField(
                decoration: inputdecoration.copyWith(hintText: 'Username'),
                validator: (value) {
                  if (value.isEmpty) {
                    return 'Please enter some text';
                  }
                  return null;
                },
                onChanged: (val) {
                  _username = val;
                },
              ),
              SizedBox(height: 20.0),
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
              SizedBox(height: 20.0),
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
              SizedBox(height: 20.0),
              ElevatedButton(
                  onPressed: () async {
                    if (_formkey.currentState.validate()) {
                      await Authenticate().registerWithEmailAndPassword(
                          _email, _password, _username, context);
                    }
                  },
                  child: Text("Sign Up"))
            ],
          ),
        ),
      ),
    );
  }
}
