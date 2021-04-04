import 'package:flutter/material.dart';
import 'package:doctor_app/models/firebase.dart';

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
      body: _userDetailsPage(),
    );
  }

  Widget _userDetailsPage() {
    return Column(
      children: [
        Card(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15.0)),
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
                          size: 50.0, color: Colors.grey[800]),
                      radius: 50.0,
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
                      ),
                      SizedBox(height: 10.0),
                    ],
                  )
                ],
              ),
            )),
        Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
          margin: EdgeInsets.fromLTRB(10.0, 10.0, 10.0, 0.0),
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(10.0, 0.0, 0.0, 0.0),
                  child: Text(
                    "Patients",
                    style:
                        TextStyle(fontSize: 18.0, fontWeight: FontWeight.w600),
                  ),
                ),
                SizedBox(
                  width: 250.0,
                  child: TextField(
                    decoration: InputDecoration(
                        hintText: 'Search',
                        border: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.blueGrey[100]),
                            borderRadius: BorderRadius.circular(20.0)),
                        fillColor: Colors.blueGrey[100],
                        filled: true,
                        suffixIcon: Icon(Icons.search_rounded)),
                  ),
                ),
              ],
            ),
          ),
        )
      ],
    );
  }
}
