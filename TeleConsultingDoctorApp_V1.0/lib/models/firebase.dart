import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:toast/toast.dart';

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

Future<Map> getUserDetails(MyUser user) async {
  final DocumentReference ref =
      FirebaseFirestore.instance.collection('doctors').doc(user.uid);
  DocumentSnapshot snap = await ref.get();
  return snap.data();
}
