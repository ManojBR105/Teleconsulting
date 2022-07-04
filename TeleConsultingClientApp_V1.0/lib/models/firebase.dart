import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';
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
    print(email);
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      User user = result.user;

      final DocumentReference myDoc =
          FirebaseFirestore.instance.collection('patients').doc(user.uid);

      await myDoc.set({"name": username, "email": email});

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
    double systolicPressure,
    double diastolicPressure,
    double pulse,
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
          SnackBar(content: Text("Uploading Temperature and BP data ...")));

      final DocumentReference temperatureRef = FirebaseFirestore.instance
          .collection('patients')
          .doc(user.uid)
          .collection('records')
          .doc(formattedDateTime);

      await temperatureRef.set({
        "Ambient Temperature": ambientTemperature.toString(),
        "Body Temperature": bodyTemperature.toString(),
        "Systolic Pressure": systolicPressure.toString(),
        "Diastolic Pressure": diastolicPressure.toString(),
        "Pulse": pulse.toString()
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

class Records {
  final String recID;
  final String uid;
  Records({this.recID, this.uid});
}

class DatabaseService {
  final String uid;
  DatabaseService({this.uid});

  // collection reference
  final CollectionReference patientCollection =
      FirebaseFirestore.instance.collection('patients');

  List<Records> _recordListFromSnapshot(QuerySnapshot snapshot) {
    return snapshot.docs.map((doc) {
      return Records(
        recID: doc.id ?? '',
        uid: uid ?? '',
      );
    }).toList();
  }

  Stream<List<Records>> get records {
    final CollectionReference recordCollection =
        patientCollection.doc(uid).collection('records');
    return recordCollection
        .snapshots()
        .map((snapshot) => _recordListFromSnapshot(snapshot));
  }

  static Future<Map> getUserDetails(MyUser user) async {
    final DocumentReference ref =
        FirebaseFirestore.instance.collection('doctors').doc(user.uid);
    DocumentSnapshot snap = await ref.get();
    return snap.data();
  }

  static Future<void> getRecordData(
      String uid, String recId, Function setData) async {
    final DocumentSnapshot recordDocument = await FirebaseFirestore.instance
        .collection('patients')
        .doc(uid)
        .collection('records')
        .doc(recId)
        .get();

    Map data = recordDocument.data();

    double ambTemp = double.parse(data["Ambient Temperature"]);
    double bodTemp = double.parse(data["Body Temperature"]);
    String remark = data["remark"];
    print(remark);

    var tempData =
        "${ambTemp.toStringAsFixed(2)},${bodTemp.toStringAsFixed(2)}";

    var bpData;
    if (data["Systolic Pressure"] != "null") {
      double systolic = double.parse(data["Systolic Pressure"]);
      double diastolic = double.parse(data["Diastolic Pressure"]);
      double pulse = double.parse(data["Pulse"]);
      bpData =
          "${systolic.toStringAsFixed(1)},${diastolic.toStringAsFixed(1)}, ${pulse.toStringAsFixed(1)}";
    }

    Directory appDocDir = await getApplicationDocumentsDirectory();
    File downloadToFilepulse = File('${appDocDir.path}/download-pulse.txt');
    var pulsePath = downloadToFilepulse.path;

    File downloadToFileheart = File('${appDocDir.path}/download-heart.wav');
    var heartPath = downloadToFileheart.path;

    try {
      await FirebaseStorage.instance
          .ref()
          .child(uid)
          .child(recId)
          .child('pulse.txt')
          .writeToFile(downloadToFilepulse);

      await FirebaseStorage.instance
          .ref()
          .child(uid)
          .child(recId)
          .child('heart.wav')
          .writeToFile(downloadToFileheart);
    } catch (e) {
      print('Not Downloaded');
    }

    setData(tempData, bpData, pulsePath, heartPath, remark);
  }

  static Future<void> setRemark(patientID, recID, remark) async {
    final DocumentReference ref = FirebaseFirestore.instance
        .collection('patients')
        .doc(patientID)
        .collection('records')
        .doc(recID);
    await ref.update({"remark": remark});
  }
}
