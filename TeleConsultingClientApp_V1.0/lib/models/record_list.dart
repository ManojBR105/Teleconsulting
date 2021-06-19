import 'package:client_app/models/firebase.dart';
import 'package:client_app/models/recorded_data.dart';
import 'package:client_app/models/shared.dart';
import 'package:flutter/material.dart';

class RecordListScreen extends StatelessWidget {
  final String patientID;
  RecordListScreen(this.patientID);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: StreamBuilder(
          stream: DatabaseService(uid: patientID).records,
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
                                          patientID,
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
