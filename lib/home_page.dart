import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;
import 'package:async/async.dart';
import 'dart:io';
import 'package:path/path.dart' as pth;

import 'package:digitalent_absensi/employee.dart';
import 'package:digitalent_absensi/absensi_today.dart';
import 'package:digitalent_absensi/log_absensi.dart';
import 'package:digitalent_absensi/notify.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatefulWidget {
  static String tag = 'home-page';

  @override
  HomePageState createState() {
    return new HomePageState();
  }
}

class HomePageState extends State<HomePage> {
  SharedPreferences prefs;
  var url;
  String drawNip;
  String drawName;
  String drawEmail;
  File _image;

  void initState() {
    super.initState();
    getCredential();
  }

  getCredential() async {
    prefs = await SharedPreferences.getInstance();
    setState(() {
      drawNip = prefs.getString("nip");
      drawName = prefs.getString("nama");
      drawEmail = prefs.getString("email");
      url = prefs.getString("url");
    });
  }

  Future getImage() async {
    var imagefile = await ImagePicker.pickImage(source: ImageSource.camera);

    final tempDir = await getTemporaryDirectory();
    final path = tempDir.path;

    img.Image image = img.decodeImage(imagefile.readAsBytesSync());
    img.Image smallerimg = img.copyResize(image, 500);

    var compressimg = new File("$path/img_$drawNip.jpeg")
    ..writeAsBytesSync(img.encodeJpg(smallerimg, quality: 85));

    setState(() {
      _image = compressimg;
      print(_image.path);
      upload(_image);
    });
  }

  Future upload(File imageFile) async{
    var stream = new http.ByteStream(DelegatingStream.typed(imageFile.openRead()));
    var length = await imageFile.length();
    var uri = Uri.parse("${url}absensi");

    var request = new http.MultipartRequest("POST", uri);
    var multipartfile = new http.MultipartFile("photo", stream, length, filename: pth.basename(imageFile.path));

    request.files.add(multipartfile);
    request.fields["nip"] = drawNip;

    var response = await request.send();
    if(response.statusCode == 200){
      print("Image Uploaded");
    }else{
      print("Image Fail");
    }
  }

  void _showDialog() {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            content: new Text(
              "Apa anda akan melakukan proses absensi?",
              style: new TextStyle(fontSize: 20.0),
            ),
            actions: <Widget>[
              new RaisedButton(
                color: Colors.red[200],
                child: new Text(
                  "Tidak",
                  style: new TextStyle(color: Colors.black),
                ),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
              new RaisedButton(
                color: Colors.lightBlue[400],
                child: new Text(
                  "Ya",
                  style: new TextStyle(color: Colors.black),
                ),
                onPressed: () {
                  getImage();
                },
              ),
            ],
          );
        });
  }

  final btnAbsen = RawMaterialButton(
    onPressed: () {},
    child: new Icon(
      Icons.alarm_on,
      color: Colors.grey[800],
      size: 100.0,
    ),
    shape: new CircleBorder(),
    elevation: 2.0,
    fillColor: Colors.orange[300],
    padding: const EdgeInsets.all(35.0),
  );

  final iconDepan = Container(
    padding: EdgeInsets.only(top: 30.0),
    child: Row(
      children: <Widget>[
        new Iconteks(
          icon: Icons.people,
          teks: "Absen Today",
          route: new absensiToday(),
        ),
        new Iconteks(
            icon: Icons.timeline, teks: "Log Absen", route: new logAbsensi()),
        new Iconteks(
            icon: Icons.notifications,
            teks: "Notification",
            route: new notifyAbsen()),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //Ini bagian AppBar
      appBar: AppBar(
        title: Text("Absensi Project"),
        backgroundColor: Colors.lightBlue[600],
      ),

      //Ini bagian drawer
      drawer: new Drawer(
        child: new ListView(
          children: <Widget>[
            new UserAccountsDrawerHeader(
              accountName: Text(
                drawName,
                style: TextStyle(color: Colors.white),
              ),
              accountEmail:
                  Text(drawEmail, style: TextStyle(color: Colors.white)),
              currentAccountPicture: new GestureDetector(
                onTap: () {
                  //need your logic
                },
                child: new CircleAvatar(
                  backgroundImage:
                      new NetworkImage("${url}static/fp/${drawNip}.jpg"),
                ),
              ),
              decoration: new BoxDecoration(
                  image: new DecorationImage(
                      image: new NetworkImage(
                          "https://png.pngtree.com/thumb_back/fw800/back_pic/04/43/89/3458538e62581d8.jpg"),
                      fit: BoxFit.cover)),
            ),
            new ListTile(
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (BuildContext context) => new employee())),
              title: Text("Employee"),
              trailing: Icon(Icons.people),
            ),
            new ListTile(
              title: Text("Sign Out"),
              trailing: Icon(Icons.power_settings_new),
            ),
          ],
        ),
      ),

      body: Container(
        decoration: BoxDecoration(
            gradient: LinearGradient(
                begin: FractionalOffset.topCenter,
                end: FractionalOffset.bottomCenter,
                colors: [Colors.lightBlue[700], Colors.white30])),
        child: Center(
          child: ListView(
            shrinkWrap: true,
            padding: EdgeInsets.only(left: 24.0, right: 24.0),
            children: <Widget>[
              RawMaterialButton(
                onPressed: () {
                  _showDialog();
                },
                child: new Icon(
                  Icons.alarm_on,
                  color: Colors.grey[800],
                  size: 100.0,
                ),
                shape: new CircleBorder(),
                elevation: 2.0,
                fillColor: Colors.orange[300],
                padding: const EdgeInsets.all(35.0),
              ),
              iconDepan,
            ],
          ),
        ),
      ),
    );
  }
}

class Iconteks extends StatelessWidget {
  Iconteks({this.icon, this.teks, this.route});
  final IconData icon;
  final String teks;
  final route;

  @override
  Widget build(BuildContext context) {
    return FlatButton(
      onPressed: () => Navigator.of(context)
          .push(MaterialPageRoute(builder: (BuildContext context) => route)),
      child: Column(
        children: <Widget>[
          Icon(
            icon,
            size: 50.0,
            color: Colors.grey[800],
          ),
          Text(
            teks,
            style: TextStyle(fontSize: 13.0, color: Colors.grey[800]),
          ),
        ],
      ),
    );
  }
}
