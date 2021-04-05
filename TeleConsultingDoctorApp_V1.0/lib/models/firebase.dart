import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:toast/toast.dart';

class MyUser {
  String uid;

  MyUser(User user) {
    this.uid = user.uid;
  }
}

class Patient {
  final String name;
  final String email;
  final String uid;
  Patient({this.name, this.email, this.uid});
}

class Records {
  final String recID;
  final String uid;
  Records({this.recID, this.uid});
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
          FirebaseFirestore.instance.collection('doctors').doc(user.uid);

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

class DatabaseService {
  final String uid;
  DatabaseService({this.uid});

  // collection reference
  final CollectionReference patientCollection =
      FirebaseFirestore.instance.collection('patients');

  // Patient List From Snapshot
  List<Patient> _patientListFromSnapshot(QuerySnapshot snapshot) {
    return snapshot.docs.map((doc) {
      return Patient(
        name: doc.data()['name'] ?? '',
        email: doc.data()['email'] ?? '',
        uid: doc.id ?? '',
      );
    }).toList();
  }

  // get Patients stream
  Stream<List<Patient>> get patients {
    return patientCollection.snapshots().map(_patientListFromSnapshot);
  }

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

    var tempData =
        "Ambeint Temp: ${data["Ambient Temperature"]} F, Body Temp: ${data["Body Temperature"]} F";

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

    setData(tempData, pulsePath, heartPath);
  }
}
