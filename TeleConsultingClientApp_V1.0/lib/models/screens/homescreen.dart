import 'package:client_app/models/firebase.dart';
import 'package:client_app/models/record_list.dart';
import 'package:flutter/material.dart';
import 'package:client_app/models/screens/recorderscreen.dart';

class HomeScrn extends StatefulWidget {
  final MyUser user;
  HomeScrn(this.user);
  @override
  _HomeScrnState createState() => _HomeScrnState(user);
}

class _HomeScrnState extends State<HomeScrn> {
  final MyUser user;
  bool loading = true;
  Map userData;
  _HomeScrnState(this.user);

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  _loadUserData() async {
    userData = await getUserDetails(user);
    setState(() {
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.lightBlue[50],
        appBar: AppBar(
          title: Text("Profile"),
          backgroundColor: Colors.lightBlue[700],
          actions: <Widget>[
            TextButton.icon(
                style: ButtonStyle(
                    foregroundColor:
                        MaterialStateProperty.all<Color>(Colors.white)),
                onPressed: () async {
                  await Authenticate().signOut();
                },
                icon: Icon(Icons.person),
                label: Text("Logout"))
          ],
        ),
        body: Container(child: _userDetailsPage()),
        floatingActionButton: TextButton.icon(
          icon: Icon(
            Icons.add_circle,
            color: Colors.white,
          ),
          label: Text(
            "Start New Recording",
            style: TextStyle(
                fontSize: 16.0,
                letterSpacing: 1.2,
                color: Colors.white,
                fontFamily: 'OdibeeSans'),
          ),
          style: ButtonStyle(
              backgroundColor: MaterialStateProperty.all(Colors.redAccent[700]),
              shape: MaterialStateProperty.all(RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0)))),
          onPressed: () {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => RecordScrn(user)));
          },
        ));
  }

  Widget _userDetailsPage() {
    return Column(
      children: [
        Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
          margin: EdgeInsets.fromLTRB(10.0, 20.0, 10.0, 0.0),
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: CircleAvatar(
                    backgroundColor: Colors.blueGrey[100],
                    child: Icon(Icons.person_rounded,
                        size: 30.0, color: Colors.grey[800]),
                    radius: 30.0,
                  ),
                ),
                SizedBox(width: 20.0),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loading ? "Username" : userData["name"].toString(),
                      style: TextStyle(fontSize: 25.0, fontFamily: 'Rubik'),
                    ),
                    Text(
                      loading
                          ? "email@domain.com"
                          : userData["email"].toString(),
                      style: TextStyle(
                          fontSize: 15.0,
                          color: Colors.grey[600],
                          letterSpacing: 1.2),
                    )
                  ],
                )
              ],
            ),
          ),
        ),
        SizedBox(height: 10),
        ListTile(
          title: Text("Recordings",
              style: TextStyle(color: Colors.white, fontSize: 18.0)),
          tileColor: Colors.lightBlue[700],
        ),
        RecordListScreen(user.uid)
      ],
    );
  }
}
