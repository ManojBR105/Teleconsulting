import 'package:doctor_app/models/firebase.dart';
import 'package:doctor_app/screens/record_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PatientList extends StatefulWidget {
  @override
  _PatientListState createState() => _PatientListState();
}

class _PatientListState extends State<PatientList> {
  @override
  Widget build(BuildContext context) {
    final patients = Provider.of<List<Patient>>(context);
    if (patients != null) {
      return ListView.builder(
        itemCount: patients.length,
        itemBuilder: (context, index) {
          return PatientTile(patient: patients[index]);
        },
      );
    }
    return Container();
  }
}

class PatientTile extends StatelessWidget {
  final Patient patient;
  PatientTile({this.patient});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Card(
        child: Column(
          children: [
            ListTile(
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => RecordListScreen(patient)));
              },
              leading: CircleAvatar(
                backgroundColor: Colors.blueGrey[100],
                radius: 25.0,
                child: Icon(
                  Icons.person_rounded,
                  color: Colors.grey[900],
                ),
              ),
              title: Text(patient.name),
              subtitle: Text(patient.email),
            ),
          ],
        ),
      ),
    );
  }
}
