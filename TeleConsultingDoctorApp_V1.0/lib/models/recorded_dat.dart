import 'dart:io';

import 'package:doctor_app/models/firebase.dart';
import 'package:doctor_app/screens/pulse_data_screen.dart';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';

class RecordedData extends StatefulWidget {
  final String uid;
  final String recId;
  RecordedData(this.uid, this.recId);

  @override
  _RecordedDataState createState() => _RecordedDataState(uid, recId);
}

class _RecordedDataState extends State<RecordedData> {
  final String uid;
  final String recId;
  _RecordedDataState(this.uid, this.recId);

  bool loading = true;
  String tempData;
  String pulsePath;
  String heartPath;
  @override
  void initState() {
    super.initState();
    _getData();
  }

  @override
  void dispose() async {
    super.dispose();
    await _deleteFiles();
  }

  _deleteFiles() async {
    if (await File(pulsePath).exists()) {
      print("deleting $pulsePath");
      await File(pulsePath).delete();
    }
    if (await File(heartPath).exists()) {
      print("deleting $heartPath");
      await File(heartPath).delete();
    }
  }

  setData(String temp, String pulse, String heart) {
    tempData = temp;
    pulsePath = pulse;
    heartPath = heart;
    loading = false;
    setState(() {});
  }

  Future<void> _getData() async {
    await DatabaseService.getRecordData(uid, recId, setData);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.indigo[50],
      appBar: AppBar(
        backgroundColor: Colors.indigoAccent[700],
        title: Text("Recorded Data"),
      ),
      body: ListView(children: [
        ListTile(
          tileColor: Colors.white,
          title: Text('Temperature'),
          subtitle: loading ? Text("loading..") : Text(tempData),
        ),
        Divider(
          height: 1.0,
        ),
        ListTile(
          tileColor: Colors.white,
          onLongPress: () {
            OpenFile.open(pulsePath);
          },
          onTap: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => PulseDataScreen(pulsePath)));
          },
          title: Text('Pulse.txt'),
          subtitle: loading ? Text("loading..") : Text('Tap To View'),
        ),
        Divider(
          height: 1.0,
        ),
        ListTile(
          tileColor: Colors.white,
          onTap: () {
            OpenFile.open(heartPath);
          },
          title: Text('Heart.wav'),
          subtitle: loading ? Text("loading..") : Text('Tap To Listen'),
        ),
        Divider(
          height: 1.0,
        ),
      ]),
    );
  }
}
