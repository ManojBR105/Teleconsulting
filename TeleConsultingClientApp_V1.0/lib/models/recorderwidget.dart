import 'dart:typed_data';
import 'dart:async';
import 'dart:io';

import 'package:client_app/models/firebase.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:toast/toast.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:path_provider/path_provider.dart';
import 'package:client_app/models/utils/base64.dart';
import 'package:open_file/open_file.dart';

enum DeviceState {
  IDLE,
  RECORDING_TEMP,
  RECORDING_PULSE,
  RECORDING_HEART,
  RECORDING_BP,
  SUCCESS
}

class RecorderWidget extends StatefulWidget {
  final BluetoothConnection connection;
  final Function disconnectDevice;
  final MyUser user;

  RecorderWidget({this.user, this.connection, this.disconnectDevice()});
  @override
  _RecorderWidgetState createState() =>
      _RecorderWidgetState(user, connection, disconnectDevice);
}

class _RecorderWidgetState extends State<RecorderWidget> {
  final MyUser user;
  BluetoothConnection _connection;
  Function _disconnectDevice;
  List<List<int>> _chunks = <List<int>>[];
  int totLength = 0;
  List<FileSystemEntity> files = [];
  bool loaded = false;

  String _recordDuration;
  String _recordParam;
  List<String> _durationChoices = ["Short", "Long"];
  List<String> _parameterChoices = ["Temp", "Pulse", "Heart", "BP"];
  double _ambientTempF;
  double _objectTempF;
  double _systolic;
  double _diastolic;
  double _pulse;
  bool _isTempRecorded = false;
  bool _isPulseRecorded = false;
  bool _isHeartRecorded = false;
  bool _isBpRecorded = false;

  DeviceState _deviceState = DeviceState.IDLE;

  _RecorderWidgetState(this.user, this._connection, this._disconnectDevice);

  @override
  void initState() {
    super.initState();
    _listofFles();
    _connection.input.listen(_onDataReceived).onDone(() {
      _disconnectDevice();
      _deletePrevFiles();
    });
  }

  @override
  void dispose() async {
    super.dispose();
    await _deletePrevFiles();
  }

  _onDataReceived(Uint8List data) async {
    if (data != null && data.length > 0) {
      // print(String.fromCharCodes(data));
      print(data.length);
      await _dataHandler(data);
    }
  }

  _dataHandler(Uint8List data) async {
    switch (new String.fromCharCodes(data)) {
      case "RECORDING STARTED,0\n":
        setState(() {
          _deviceState = DeviceState.RECORDING_TEMP;
        });
        break;
      case "RECORDING STARTED,1\n":
        setState(() {
          _deviceState = DeviceState.RECORDING_PULSE;
        });
        break;
      case "RECORDING STARTED,2\n":
        setState(() {
          _deviceState = DeviceState.RECORDING_HEART;
        });
        break;
      case "RECORDING STARTED,3\n":
        setState(() {
          _deviceState = DeviceState.RECORDING_BP;
        });
        break;
      case "SENT\n":
        if (_chunks.length > 0) {
          await _decodeAndSaveFile();
          setState(() {
            _deviceState = DeviceState.SUCCESS;
          });
        }
        break;
      case "DONE\n":
        setState(() {
          _deviceState = DeviceState.IDLE;
        });
        break;
      default:
        setState(() {
          _chunks.add(data);
          totLength += data.length;
        });
    }
  }

  Future<String> get _path async {
    final directory = await getExternalStorageDirectory();
    return directory.path;
  }

  _decodeAndSaveFile() async {
    if (String.fromCharCodes(_chunks[0]).startsWith("file")) {
      String extension = String.fromCharCodes(_chunks[0]).substring(5, 8);
      final path = await _path;
      String fileName = (extension == "txt") ? "Pulse_Data" : "Heart_Beat";
      var myFile = File('$path/$fileName.$extension');
      print(path);
      if (extension == "txt") {
        String base64 = String.fromCharCodes(_chunks[0]).substring(9);
        for (int i = 1; i < _chunks.length; i++)
          base64 += String.fromCharCodes(_chunks[i]);
        Uint8List _bytes = Base64Util.base64Decoder(base64);
        myFile.writeAsBytesSync(_bytes, mode: FileMode.append, flush: true);
        _isPulseRecorded = true;
      } else {
        myFile.writeAsBytesSync(_chunks[0].sublist(9),
            mode: FileMode.append, flush: true);
        for (int i = 1; i < _chunks.length; i++)
          myFile.writeAsBytesSync(_chunks[i],
              mode: FileMode.append, flush: true);
        _isHeartRecorded = true;
      }
      _listofFles();
      setState(() {
        _chunks.clear();
        totLength = 0;
      });
    } else if (String.fromCharCodes(_chunks[0]).startsWith("data,temp")) {
      String data = String.fromCharCodes(_chunks[0]).substring(10);
      if (_chunks.length > 1) data += String.fromCharCodes(_chunks[1]);
      _ambientTempF = double.parse(data.split(",")[0]);
      _objectTempF = double.parse(data.split(",")[1]);
      _isTempRecorded = true;
      setState(() {
        _chunks.clear();
        totLength = 0;
      });
    } else if (String.fromCharCodes(_chunks[0]).startsWith("data,bp")) {
      String data = String.fromCharCodes(_chunks[0]).substring(8);
      if (_chunks.length > 1) data += String.fromCharCodes(_chunks[1]);
      _systolic = double.parse(data.split(",")[0]);
      _diastolic = double.parse(data.split(",")[1]);
      _pulse = double.parse(data.split(",")[2]);
      setState(() {
        _chunks.clear();
        totLength = 0;
      });
      if (_systolic == 0 || _diastolic == 0 || _systolic - _diastolic < 20)
        Toast.show(
            "The BP recording was not successful, please record again", context,
            duration: Toast.LENGTH_LONG, gravity: Toast.BOTTOM);
      else
        _isBpRecorded = true;
    } else {
      Toast.show("Something went wrong while recieving the file", context,
          duration: Toast.LENGTH_LONG, gravity: Toast.BOTTOM);
    }
    await _sendSuccessSignal();
  }

  Future<void> _deletePrevFiles() async {
    try {
      File file = File(await _path + "/Pulse_Data.txt");
      if (await file.exists()) {
        print("deletting ${file.path}");
        await file.delete();
      }
    } catch (e) {
      // Error in getting access to the file.
    }
    try {
      File file = File(await _path + "/Heart_Beat.wav");
      if (await file.exists()) {
        print("deletting ${file.path}");
        await file.delete();
      }
    } catch (e) {
      // Error in getting access to the file.
    }
  }

  String _getStatus() {
    String state = '';
    switch (_deviceState) {
      case DeviceState.IDLE:
        state = 'Waiting To Start Recording';
        break;
      case DeviceState.RECORDING_TEMP:
        state = 'Recording Temperature';
        break;
      case DeviceState.RECORDING_PULSE:
        state = 'Recording Pulse Data';
        break;
      case DeviceState.RECORDING_HEART:
        state = 'Recording Heart Beat';
        break;
      case DeviceState.RECORDING_BP:
        state = 'Recording Blood Pressure';
        break;
      case DeviceState.SUCCESS:
        state = 'Recording Successfull';
        break;
    }
    return state;
  }

  _sendRecordSignal() async {
    try {
      _connection.output.add(Uint8List.fromList(
          "START,$_recordDuration,$_recordParam\n".codeUnits));
      await _connection.output.allSent;
    } catch (e) {
      Toast.show("Something went Wrong, Couldn't Send Signal", context,
          duration: Toast.LENGTH_LONG, gravity: Toast.BOTTOM);
    }
  }

  _sendSuccessSignal() async {
    try {
      _connection.output.add(Uint8List.fromList("SUCCESS\n".codeUnits));
      await _connection.output.allSent;
    } catch (e) {
      Toast.show(
          "Something went Wrong, Couldn't Send Signal to the device", context,
          duration: Toast.LENGTH_LONG, gravity: Toast.BOTTOM);
    }
  }

  _listofFles() async {
    final path = await _path;
    var fileList = Directory(path).list();
    files.clear();
    await fileList.forEach((file) {
      if (file.path.contains("wav") || file.path.contains("txt")) {
        files.insert(0, file);
      }
    });
    setState(() {});
  }

  _uploadData() async {
    await uploadDataToFirebase(
        user,
        _ambientTempF,
        _objectTempF,
        _systolic,
        _diastolic,
        _pulse,
        File(await _path + "/Pulse_Data.txt"),
        File(await _path + "/Heart_Beat.wav"),
        context, () async {
      await _deletePrevFiles();
      _isPulseRecorded = false;
      _isTempRecorded = false;
      _isBpRecorded = false;
      _isHeartRecorded = false;
      await _listofFles();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Card(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                "Select Recording Duration and Parameter",
                style: TextStyle(color: Colors.lightBlue[700], fontSize: 18.0),
              ),
            ),
            Form(
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.all(16.0),
                    child: DropdownButtonFormField(
                      value: _recordDuration,
                      items: _durationChoices
                          .map<DropdownMenuItem<String>>(
                            (String label) => DropdownMenuItem<String>(
                              child: Text(label),
                              value: label,
                            ),
                          )
                          .toList(),
                      hint: Text("Recording time"),
                      onChanged: (value) {
                        setState(() {
                          _recordDuration = value;
                        });
                      },
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(16.0),
                    child: DropdownButtonFormField(
                      value: _recordParam,
                      items: _parameterChoices
                          .map<DropdownMenuItem<String>>(
                            (String label) => DropdownMenuItem<String>(
                              child: Text(label),
                              value: label,
                            ),
                          )
                          .toList(),
                      hint: Text("Recording Parameter"),
                      onChanged: (value) {
                        setState(() {
                          _recordParam = value;
                        });
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: (_deviceState != DeviceState.IDLE)
                        ? Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: SpinKitRing(
                              color: Colors.lightBlue[700],
                              size: 30.0,
                              lineWidth: 5.0,
                            ),
                          )
                        : TextButton.icon(
                            style: ButtonStyle(
                              foregroundColor:
                                  MaterialStateProperty.all(Colors.white),
                              backgroundColor: MaterialStateProperty.all(
                                  Colors.lightBlue[700]),
                              padding: MaterialStateProperty.all(
                                  EdgeInsets.fromLTRB(10.0, 10.0, 20.0, 10.0)),
                            ),
                            onPressed: () async {
                              //start recording
                              await _sendRecordSignal();
                            },
                            icon: Icon(Icons.play_arrow),
                            label: Text(
                              "Start Recording",
                              style: TextStyle(fontFamily: 'Rubik'),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      _showStatus(),
      SizedBox(height: 10.0),
      _loadFiles()
    ]);
  }

  Widget _showStatus() {
    return Card(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _getStatus(),
                    style: TextStyle(fontSize: 16.0, fontFamily: 'Rubik'),
                  ),
                  SizedBox(height: 50.0),
                  _options(),
                ]),
          ),
          Divider(),
          _getInstructions(),
        ],
      ),
    );
  }

  Widget _getInstructions() {
    String instruction = "";
    var img;
    switch (_deviceState) {
      case DeviceState.RECORDING_TEMP:
        instruction =
            "Point the Temperature Sensor at your skin surface at a distance of 3-5cm and press the button on the device to record.";
        img = AssetImage("images/temperature.jpg");
        break;
      case DeviceState.RECORDING_PULSE:
        instruction =
            "Place and hold your finger gently on the Pulseoximeter sensor to start recording pulse data.";
        img = AssetImage("images/pulse.jpg");
        break;
      case DeviceState.RECORDING_HEART:
        instruction =
            "Hold the sthethoscope chest head near the chest slightly towards left and press the button on the device to start recording.";
        img = AssetImage("images/sthethoscope.jpg");
        break;
      case DeviceState.RECORDING_BP:
        instruction =
            "Connect the BP add-on and wear the cuff firmly and press the button on the device to start recording.";
        img = AssetImage("images/bloodpressure.jpg");
        break;
      default:
        break;
    }
    return img != null
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image(
                image: img,
                height: 150.0,
                alignment: Alignment.center,
              ),
              Divider(),
              Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(instruction),
              )
            ],
          )
        : Container();
  }

  Widget _options() {
    return (_isHeartRecorded && _isPulseRecorded && _isTempRecorded)
        ? TextButton.icon(
            style: ButtonStyle(
                backgroundColor:
                    MaterialStateProperty.all(Colors.lightBlue[700]),
                foregroundColor: MaterialStateProperty.all(Colors.white)),
            onPressed: () async {
              await _uploadData();
            },
            icon: Icon(Icons.upload_file),
            label: Text("Upload"))
        : Container();
  }

  Widget _loadFiles() {
    return Expanded(
      child: ListView(
          children: [
                ListTile(
                  title: Text("Recorded Data",
                      style: TextStyle(color: Colors.white)),
                  tileColor: Colors.lightBlue[700],
                ),
                _isTempRecorded
                    ? ListTile(
                        title: Text("Temperature"),
                        tileColor: Colors.white,
                        subtitle: Text(
                            "Ambient Temp: $_ambientTempF F, Body Temp: $_objectTempF F"),
                      )
                    : SizedBox(height: 0),
              ] +
              files.map((file) {
                return ListTile(
                  tileColor: Colors.white,
                  title: Text((file.path).split("/").last.split(".").first),
                  subtitle: Text("${file.statSync().size} bytes"),
                  onTap: () async {
                    OpenFile.open(file.path);
                  },
                  onLongPress: () async {
                    File(file.path).deleteSync();
                    await _listofFles();
                    setState(() {});
                  },
                );
              }).toList() +
              [
                _isBpRecorded
                    ? ListTile(
                        title: Text("Blood Pressure"),
                        tileColor: Colors.white,
                        subtitle: Text(
                            "Systolic: $_systolic mmHg, diastolic: $_diastolic mmHg, Pulse: $_pulse bpm"),
                      )
                    : SizedBox(height: 0),
              ]),
    );
  }
}
