import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:toast/toast.dart';
import 'package:intl/intl.dart';

class MyUser {
  String uid;

  MyUser(User user) {
    this.uid = user.uid;
  }
}

class Authenticate {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  //auth change user change
  Stream<MyUser> get user {
    return _auth.authStateChanges().map((User user) {
      return (user == null) ? null : MyUser(user);
    });
  }

  //register with email and password
  Future<MyUser> registerWithEmailAndPassword(String email, String password,
      String username, BuildContext context) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      User user = result.user;

      final DocumentReference myDoc =
          FirebaseFirestore.instance.collection('patients').doc(user.uid);

      await myDoc.set({"Name": username, "email": email});

      return MyUser(user);
    } catch (e) {
      Toast.show(e.message.toString(), context,
          duration: Toast.LENGTH_LONG, gravity: Toast.TOP);
      return null;
    }
  }

  //sign in with email and password
  Future<MyUser> signInWithEmailAndPassword(
      String email, String password, BuildContext context) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      return MyUser(result.user);
    } catch (e) {
      print(e.toString());
      Toast.show(e.message.toString(), context,
          duration: Toast.LENGTH_LONG, gravity: Toast.TOP);
      return null;
    }
  }

  //signout
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print(e.toString());
    }
  }
}

Future<Map> getUserDetails(MyUser user) async {
  final DocumentReference ref =
      FirebaseFirestore.instance.collection('patients').doc(user.uid);
  DocumentSnapshot snap = await ref.get();
  return snap.data();
}

Future<void> uploadDataToFirebase(
    MyUser user,
    double ambientTemperature,
    double bodyTemperature,
    File pulseFile,
    File heartFile,
    BuildContext context,
    Function callbackAfterSuccess) async {
  DateTime now = DateTime.now();
  String formattedDateTime = DateFormat("yyyy_MM_dd_HH_mm_ss").format(now);
  try {
    if (!await pulseFile.exists()) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("File doesn't exist please record again")));
    } else if (!await heartFile.exists()) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("File doesn't exist please record again")));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Uploading Temperature data ...")));

      final DocumentReference temperatureRef = FirebaseFirestore.instance
          .collection('patients')
          .doc(user.uid)
          .collection('records')
          .doc(formattedDateTime);

      await temperatureRef.set({
        "Ambient Temperature": ambientTemperature.toString(),
        "Body Temperature": bodyTemperature.toString()
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Uploading Pulse data ...")));

      final Reference pulseRef = FirebaseStorage.instance
          .ref()
          .child("/${user.uid}/$formattedDateTime/pulse.txt");

      final Task uploadPulse = pulseRef.putFile(pulseFile);

      uploadPulse.whenComplete(() async {
        if (uploadPulse.snapshot.state == TaskState.success) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Uploading heart beat ...")));

          final Reference heartRef = FirebaseStorage.instance
              .ref()
              .child("/${user.uid}/$formattedDateTime/heart.wav");

          final Task uploadHeart = heartRef.putFile(heartFile);
          uploadHeart.whenComplete(() async {
            if (uploadHeart.snapshot.state == TaskState.success) {
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text("Upload Complete!!")));

              callbackAfterSuccess();
            } else {
              print(uploadHeart.snapshot.state);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(
                      "Sorry, Couldn't Upload! upload state: ${uploadHeart.snapshot.state.toString()}")));
            }
          });
        } else {
          print(uploadPulse.snapshot.state);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(
                  "Sorry, Couldn't Upload! upload state: ${uploadPulse.snapshot.state.toString()}")));
        }
      });
    }
  } catch (e) {
    Toast.show(e.message.toString(), context,
        duration: Toast.LENGTH_LONG, gravity: Toast.BOTTOM);
  }
}
