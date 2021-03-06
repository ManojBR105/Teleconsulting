import 'package:doctor_app/models/firebase.dart';
import 'package:doctor_app/models/recorded_dat.dart';
import 'package:doctor_app/models/shared.dart';
import 'package:flutter/material.dart';

class RecordListScreen extends StatelessWidget {
  final Patient patient;
  RecordListScreen(this.patient);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.indigo[50],
      appBar: AppBar(
        backgroundColor: Colors.indigoAccent[700],
        title: Text("Recordings of " + patient.name),
      ),
      body: StreamBuilder(
          stream: DatabaseService(uid: patient.uid).records,
          builder:
              (BuildContext context, AsyncSnapshot<List<Records>> records) {
            return records.data == null
                ? Center(child: Text("Loading..."))
                : ListView.builder(
                    itemCount: records.data.length,
                    itemBuilder: (context, ind) {
                      var index = records.data.length - ind - 1;
                      return Column(
                        children: [
                          ListTile(
                            tileColor: Colors.white,
                            onTap: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => RecordedData(
                                          patient.uid,
                                          records.data[index].recID)));
                            },
                            title: Text(getDateFrom(records.data[index].recID)),
                            subtitle:
                                Text(getTimeFrom(records.data[index].recID)),
                          ),
                          Divider(
                            height: 1.0,
                          )
                        ],
                      );
                    },
                  );
          }),
    );
  }
}
