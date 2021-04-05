import 'dart:io';

import 'package:flutter/material.dart';
import 'package:charts_flutter/flutter.dart' as chart;

class PulseDataScreen extends StatefulWidget {
  final pulseFilePath;

  PulseDataScreen(this.pulseFilePath);
  @override
  _PulseDataScreenState createState() => _PulseDataScreenState(pulseFilePath);
}

class PulseData {
  int ibiValue;
  int index;
  PulseData(this.index, this.ibiValue);
}

class HrvData {
  String label;
  double value;
  HrvData(this.label, this.value);
}

class _PulseDataScreenState extends State<PulseDataScreen> {
  final pulseFilePath;
  bool loading = true;
  List<chart.Series<PulseData, int>> lineGraphData = [];
  List<chart.Series<HrvData, String>> barGraphData = [];

  @override
  void initState() {
    super.initState();
    _loadGraph();
  }

  _loadGraph() async {
    var lines = await File(pulseFilePath).readAsLines();
    var hrvResults = lines.sublist(2, 6);
    var ibiValues = lines.sublist(7);
    int i = 0;
    List<PulseData> pulseData = [];
    ibiValues.forEach((element) {
      pulseData.add(PulseData(i, int.parse(element)));
      i++;
    });

    List<HrvData> hrvData = [];
    hrvResults.forEach((element) {
      hrvData.add(HrvData(element.split(":").first.replaceAll(" ", ""),
          double.parse(element.split(":").last.replaceAll(" ", ""))));
      i++;
    });

    lineGraphData.add(
      chart.Series(
        colorFn: (__, _) =>
            chart.ColorUtil.fromDartColor(Colors.indigoAccent[700]),
        id: 'IBI values',
        data: pulseData,
        domainFn: (PulseData pulse, _) => pulse.index,
        measureFn: (PulseData pulse, _) => pulse.ibiValue,
      ),
    );

    barGraphData.add(
      chart.Series(
        domainFn: (HrvData hrv, _) => hrv.label,
        measureFn: (HrvData hrv, _) => hrv.value,
        id: 'HRV Results',
        data: hrvData,
        fillPatternFn: (_, __) => chart.FillPatternType.solid,
        fillColorFn: (HrvData hrv, _) =>
            chart.ColorUtil.fromDartColor(Colors.indigoAccent[700]),
      ),
    );

    loading = false;
    setState(() {});
    print(hrvResults);
  }

  _PulseDataScreenState(this.pulseFilePath);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.indigo[50],
      appBar: AppBar(
        backgroundColor: Colors.indigoAccent[700],
        title: Text("Pulse Data"),
      ),
      body: loading
          ? Center(child: Text("Loading.."))
          : Column(
              children: [
                ListTile(
                  tileColor: Colors.indigoAccent[100],
                  title: Text("IBI Values"),
                ),
                Expanded(child: chart.LineChart(lineGraphData)),
                ListTile(
                  tileColor: Colors.indigoAccent[100],
                  title: Text("HRV parameters"),
                ),
                Expanded(child: chart.BarChart(barGraphData))
              ],
            ),
    );
  }
}
