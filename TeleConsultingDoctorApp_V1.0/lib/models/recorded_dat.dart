import 'dart:io';

import 'package:doctor_app/models/firebase.dart';
import 'package:doctor_app/models/shared.dart';
import 'package:doctor_app/screens/pulse_data_screen.dart';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';

import '../utils/ml_classifier.dart';

//import 'ml_classifier.dart';

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

  // final isRecording = ValueNotifier<bool>(false);
  // Stream<Map<dynamic, dynamic>> result;
  // final String model = 'assets/model.tflite';
  // final String label = 'assets/label.txt';
  // final String inputType = 'rawAudio';
  // final int sampleRate = 16000;
  // final int audioLength = 160000;

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
    // TfliteAudio.loadModel(
    //   // numThreads: this.numThreads,
    //   // isAsset: this.isAsset,
    //   // outputRawScores: outputRawScores,
    //   inputType: inputType,
    //   model: model,
    //   label: label,
    // );
    // TfliteAudio.setSpectrogramParameters(nMFCC: 40, shouldTranspose: true);
  }

  // void getResult(audioPath) {
  //   result = TfliteAudio.startFileRecognition(
  //     audioDirectory: audioPath,
  //     sampleRate: sampleRate,
  //     audioLength: audioLength,
  //   );

  //   result
  //       .listen((event) =>
  //           log("Recognition Result: " + event["recognitionResult"].toString()))
  //       .onDone(() => isRecording.value = false);
  // }

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
      floatingActionButton: TextButton(
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.all(Colors.indigoAccent[700]),
          foregroundColor: MaterialStateProperty.all(Colors.white),
        ),
        child: Text("Add Remark"),
        onPressed: () {
          showPopUpDescription();
        },
      ),
      appBar: AppBar(
        backgroundColor: Colors.indigoAccent[700],
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
              ElevatedButton(
                  style: ButtonStyle(
                    backgroundColor:
                        MaterialStateProperty.all(Colors.indigoAccent[700]),
                    foregroundColor: MaterialStateProperty.all(Colors.white),
                  ),
                  onPressed: () async {
                    // getResult(heartPath);
                    List<double> result = await MLClassifier(heartPath);
                    showPopUpResult(result);
                  },
                  child: Text("Try ML Heart Beat Audio Classifier")),
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
      width: MediaQuery.of(context).size.width * 0.46,
      height: MediaQuery.of(context).size.height * 0.3,
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
                style: TextStyle(fontSize: 12.0, fontWeight: FontWeight.bold),
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

  showPopUpDescription() {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Row(
              children: [
                Text("Add Remark to this recording"),
              ],
            ),
            content: Form(
              key: formkey,
              child: TextFormField(
                  initialValue: remark,
                  decoration: inputdecoration.copyWith(hintText: 'remark'),
                  keyboardType: TextInputType.name,
                  maxLines: 3,
                  maxLength: 100,
                  validator: (value) {
                    if (value.characters.length > 100) {
                      return 'remark should be below 100 characters';
                    }
                    return null;
                  },
                  onChanged: (val) {
                    remark = val;
                    setState(() {});
                  }),
            ),
            actions: [
              ElevatedButton(
                  style: ButtonStyle(
                      backgroundColor:
                          MaterialStateProperty.all(Colors.indigoAccent[700])),
                  onPressed: () async {
                    await DatabaseService.setRemark(uid, recId, remark);
                    Navigator.pop(context);
                  },
                  child: Text("Update")),
              IconButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: Icon(
                  Icons.cancel,
                  size: 35.0,
                ),
              )
            ],
          );
        });
  }

  showPopUpResult(List<double> result) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Ml Classifier Result",
                    style: TextStyle(
                        color: Colors.indigoAccent[700],
                        fontSize: 22,
                        fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: Icon(
                      Icons.cancel,
                      size: 35.0,
                    ),
                  )
                ]),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  "Artifact: ${(result[0] * 100).round()}%",
                  style: TextStyle(
                      color: Colors.redAccent[700],
                      fontSize: 20,
                      fontWeight: FontWeight.bold),
                ),
                Text("Murmur: ${(result[1] * 100).round()}%",
                    style: TextStyle(
                        color: Colors.amberAccent[700],
                        fontSize: 20,
                        fontWeight: FontWeight.bold)),
                Text("Normal: ${(result[2] * 100).round()}%",
                    style: TextStyle(
                        color: Colors.greenAccent[700],
                        fontSize: 20,
                        fontWeight: FontWeight.bold)),
                Text(
                  "Note: \nIf the audio is noisy the results might not be accurate.",
                  style: TextStyle(fontStyle: FontStyle.italic),
                )
              ],
            ),
          );
        });
  }
}
