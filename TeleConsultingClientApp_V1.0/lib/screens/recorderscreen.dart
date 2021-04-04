import 'package:client_app/models/firebase.dart';
import 'package:flutter/material.dart';
import 'package:client_app/models/bluetoothdevicelist.dart';
import 'package:client_app/models/recorderwidget.dart';
import 'package:flutter_switch/flutter_switch.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:toast/toast.dart';

class RecordScrn extends StatefulWidget {
  final MyUser user;
  RecordScrn(this.user);
  @override
  _RecordScrnState createState() => _RecordScrnState(user);
}

class _RecordScrnState extends State<RecordScrn> with WidgetsBindingObserver {
  final MyUser user;
  _RecordScrnState(this.user);
  BluetoothState _bluetoothState = BluetoothState.UNKNOWN;
  BluetoothConnection _connection;
  List<BluetoothDevice> _devices = [];

  BluetoothDevice _selectedDevice;
  bool _selectedDeviceCurrState = false;

  bool _isConnected(device) {
    return (_selectedDevice == device) ? _selectedDeviceCurrState : false;
  }

  void _selectedDeviceDisconnect() {
    setState(() {
      _selectedDevice = null;
      _selectedDeviceCurrState = false;
      _connection.dispose();
      _connection = null;
    });
  }

  void _listBondedDevices() {
    FlutterBluetoothSerial.instance
        .getBondedDevices()
        .then((List<BluetoothDevice> bondedDevices) {
      setState(() {
        _devices = bondedDevices;
      });
    });
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);
    _connection = null;

    // Get current state
    FlutterBluetoothSerial.instance.state.then((state) {
      setState(() {
        _bluetoothState = state;
      });
      if (_bluetoothState.isEnabled) {
        _listBondedDevices();
      }
    });

    // listen for further changes
    FlutterBluetoothSerial.instance
        .onStateChanged()
        .listen((BluetoothState state) {
      setState(() {
        _bluetoothState = state;
      });
      if (_bluetoothState.isEnabled) {
        _listBondedDevices();
      }
    });
  }

  @override
  void dispose() async {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
    try {
      if (_connection != null) await _connection.close();
      if (_connection != null) _connection.dispose();
    } catch (exception) {
      Toast.show("Connection Error, Please Reconnect", context,
          duration: Toast.LENGTH_SHORT, gravity: Toast.BOTTOM);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state.index == 0) {
      //resume
      if (_bluetoothState.isEnabled) {
        _listBondedDevices();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.lightBlue[50],
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text('Record'),
        backgroundColor: Colors.lightBlue[700],
      ),
      endDrawer: _bluetoothSettingsDrawer(),
      body: (_connection == null)
          ? Container(
              alignment: Alignment.center,
              child: Padding(
                  padding: const EdgeInsets.fromLTRB(20.0, 0, 0, 15.0),
                  child: Text(
                    "No device Selected, Click on three horizontal lines in top right corner to select a device",
                  )),
            )
          : RecorderWidget(
              user: user,
              connection: _connection,
              disconnectDevice: _selectedDeviceDisconnect),
    );
  }

  Widget _bluetoothSettingsDrawer() {
    return Drawer(
      semanticLabel: 'Connect',
      child: Column(
        children: <Widget>[
          DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.lightBlue[700],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text(
                  "Select Your Device",
                  style: TextStyle(fontSize: 20.0, color: Colors.white),
                ),
                Icon(
                  Icons.bluetooth,
                  color: Colors.white,
                  size: 40.0,
                ),
                FlutterSwitch(
                  activeColor: Colors.blueGrey[100],
                  inactiveColor: Colors.blueGrey[100],
                  activeTextColor: Colors.lightBlue[700],
                  activeToggleColor: Colors.lightBlue[700],
                  width: 80.0,
                  height: 30.0,
                  valueFontSize: 15.0,
                  toggleSize: 20.0,
                  value: _bluetoothState == BluetoothState.STATE_ON,
                  borderRadius: 20.0,
                  padding: 5.0,
                  showOnOff: true,
                  onToggle: (val) async {
                    if (val)
                      await FlutterBluetoothSerial.instance.requestEnable();
                    else
                      await FlutterBluetoothSerial.instance.requestDisable();
                    setState(() {});
                  },
                ),
              ],
            ),
          ),
          _listPairedAndSelect(),
        ],
      ),
    );
  }

  Widget _listPairedAndSelect() {
    return _bluetoothState == BluetoothState.STATE_ON
        ? Column(
            children: [
              ListTile(
                title: Text("Paired Devices"),
                trailing: IconButton(
                    icon: Icon(Icons.settings),
                    onPressed: () {
                      FlutterBluetoothSerial.instance.openSettings();
                    }),
              ),
              Divider(),
              Column(
                children: _devices
                    .map((_device) => BluetoothDeviceListEntry(
                          device: _device,
                          getConnectionStatus: _isConnected,
                          enabled: true,
                          onTap: () async {
                            Navigator.pop(context);
                            if (_selectedDevice != _device &&
                                _selectedDevice != null)
                              Toast.show(
                                  "A device is already Connected, Please Disconnect before trying to connect another",
                                  context,
                                  duration: Toast.LENGTH_LONG,
                                  gravity: Toast.BOTTOM);
                            else
                              await _connectionHandler(_device, true);
                          },
                          onLongPress: () async {
                            await _connectionHandler(_device, false);
                          },
                        ))
                    .toList(),
              )
            ],
          )
        : Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text("Please Turn On Bluetooth",
                style: TextStyle(fontSize: 16.0)),
          );
  }

  Future<void> _connectionHandler(
      BluetoothDevice _device, bool _selectedDeviceDesiredState) async {
    String message = '';
    int legnth = Toast.LENGTH_SHORT;
    setState(() {
      _selectedDevice = _device;
    });
    if (_selectedDevice != null) {
      if (!_selectedDeviceCurrState && _selectedDeviceDesiredState) {
        try {
          await BluetoothConnection.toAddress(_selectedDevice.address)
              .then((connection) {
            setState(() {
              _connection = connection;
              _selectedDeviceCurrState = true; //connected
            });
            _listBondedDevices();
            message = 'Connected';
          });
        } catch (exception) {
          message =
              "Couldn't connect, check the device you are trying to connect is on";
          legnth = Toast.LENGTH_LONG;
          setState(() {
            _selectedDevice = null;
          });
        }
      } else if (_selectedDeviceCurrState && _selectedDeviceDesiredState)
        message = 'Device already connected';
      else if (_selectedDeviceCurrState && !_selectedDeviceDesiredState) {
        try {
          await _connection.finish();
          setState(() {
            _connection = null;
            _selectedDeviceCurrState = false; //disconnected
            _selectedDevice = null;
          });
          _listBondedDevices();
          message = 'Disconnected';
        } catch (exception) {
          message =
              "Couldn't connect, check the device connected is responding";
          legnth = Toast.LENGTH_LONG;
        }
      } else {
        message = 'Device already Disconnected';
        setState(() {
          _selectedDevice = null;
        });
      }
    } else
      print("Something is not right");
    Toast.show(message, context, duration: legnth, gravity: Toast.BOTTOM);
  }
}
