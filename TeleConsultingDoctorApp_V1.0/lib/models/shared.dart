import 'package:flutter/material.dart';

InputDecoration inputdecoration = InputDecoration(
  fillColor: Colors.white,
  filled: true,
  contentPadding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
  enabledBorder: OutlineInputBorder(
      borderSide: BorderSide(color: Colors.grey[600], width: 1.2),
      borderRadius: BorderRadius.circular(8.0)),
  errorBorder: OutlineInputBorder(
      borderSide: BorderSide(color: Colors.redAccent[400]),
      borderRadius: BorderRadius.circular(8.0)),
  focusedBorder: OutlineInputBorder(
      borderSide: BorderSide(color: Colors.lightBlue[200], width: 1.6),
      borderRadius: BorderRadius.circular(8.0)),
  focusedErrorBorder: OutlineInputBorder(
      borderSide: BorderSide(color: Colors.redAccent[400]),
      borderRadius: BorderRadius.circular(8.0)),
);
