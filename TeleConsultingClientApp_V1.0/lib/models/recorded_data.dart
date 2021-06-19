import 'dart:io';

import 'package:client_app/models/shared.dart';
import 'package:client_app/models/firebase.dart';
import 'package:client_app/screens/pulse_data_screen.dart';
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
  final formkey = GlobalKey<FormState>();

  _RecordedDataState(this.uid, this.recId);

  bool loading = true;
  String tempData;
  String bpData;
  String pulsePath;
  String heartPath;
  String remark;
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

  setData(String temp, String bp, String pulse, String heart, String _remark) {
    tempData = temp;
    bpData = bp;
    remark = _remark;
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
        backgroundColor: Colors.lightBlue[700],
        title: Text(getDateFrom(recId) + "\t" + getTimeFrom(recId)),
      ),
      body: loading
          ? Center(
              child: Text("Loading"),
            )
          : Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                dataCard(AssetImage("images/thermometer.jpg"), "Temperature",
                    tempData.split(",")[1] + " F",
                    subData: "Ambient :" + tempData.split(",")[0] + " F"),
                bpData != null
                    ? dataCard(
                        AssetImage("images/blood-pressure.png"),
                        "Blood Pressure",
                        bpData.split(",")[0] +
                            " / " +
                            bpData.split(",")[1] +
                            " mmHg",
                        subData: "Pulse: " + bpData.split(",")[2] + " bpm")
                    : Container()
              ]),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                dataCard(AssetImage("images/pulse.png"), "Pulse and HRV Data",
                    "Graphical Data",
                    subData: "Tap to view", onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => PulseDataScreen(pulsePath)));
                }),
                dataCard(AssetImage("images/heart-beat.png"), "Heart Beat",
                    "Audio Data",
                    subData: "Tap to listen", onTap: () {
                  OpenFile.open(heartPath);
                })
              ]),
              remark != null
                  ? Container(
                      margin: EdgeInsets.all(
                          MediaQuery.of(context).size.width * 0.025),
                      child: ListTile(
                        tileColor: Colors.white,
                        title: Text(
                          "Remark: ",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(
                          remark,
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                      ),
                    )
                  : Container(),
            ]),
    );
  }

  Widget dataCard(AssetImage image, String tittle, String mainData,
      {String subData, Function onTap}) {
    return Container(
      margin: EdgeInsets.all(MediaQuery.of(context).size.width * 0.0125),
      width: MediaQuery.of(context).size.width * 0.45,
      height: MediaQuery.of(context).size.height * 0.35,
      child: GestureDetector(
        onTap: onTap,
        child: Card(
            child: Padding(
          padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.0125),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                tittle,
                style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
              ),
              Image(
                image: image,
                width: 200,
              ),
              Text(
                mainData,
                style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.w900),
              ),
              Text(subData)
            ],
          ),
        )),
      ),
    );
  }
}
