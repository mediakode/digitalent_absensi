import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;
import 'package:async/async.dart';
import 'dart:io';
import 'package:path/path.dart' as pth;

import 'package:digitalent_absensi/employee.dart';
import 'package:digitalent_absensi/login_page.dart';
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
  int kondisi;
  File _image;

  Color color_btn_absensi;
  IconData icon_btn_absensi;

  color_btn() {
    if (kondisi == 1) {
      color_btn_absensi = Colors.blueGrey[50];
    } else {
      color_btn_absensi = Colors.orange[200];
    }
    return color_btn_absensi;
  }

  icon_btn() {
    if (kondisi == 1) {
      icon_btn_absensi = Icons.exit_to_app;
    } else {
      icon_btn_absensi = Icons.alarm_on;
    }
    return icon_btn_absensi;
  }

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
      kondisi = prefs.getInt("status_absen");
    });
  }

  bool progress = false;
  var progressBar = new Center(
      child: Container(
    height: 170.0,
    width: 240.0,
    child: Card(
      color: Colors.transparent,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          CircularProgressIndicator(),
          SizedBox(
            height: 10.0,
          ),
          Text(
            "Loading...",
            style: TextStyle(color: Colors.white),
          )
        ],
      ),
    ),
  ));

  Future getImage() async {
    var imagefile = await ImagePicker.pickImage(source: ImageSource.camera);

    final tempDir = await getTemporaryDirectory();
    final path = tempDir.path;

    img.Image image = img.decodeImage(imagefile.readAsBytesSync());
    img.Image smallerimg = img.copyResize(image, 500);

    var compressimg = new File("$path/img_$drawNip.jpeg")
      ..writeAsBytesSync(img.encodeJpg(smallerimg, quality: 85));

    //setState(() {
      _image = compressimg;
      print(_image.path);
      upload(_image);
    //});
  }

  Future _absenOut() async {
    final res = await http.post("${url}absenout", body: {"nip": drawNip});
    var datamsg = json.decode(res.body);
    setState(() {
      if (datamsg.length > 0) {
        prefs.setInt("status_absen", 0);
        prefs.commit();
        Navigator.pushReplacementNamed(context, HomePage.tag);
        _showDialogAbsensi("Absensi keluar berhasil");
      } else {
        _showDialogAbsensi("Absensi keluar gagal");
      }
    });
  }

  Future upload(File imageFile) async {
    var stream =
        new http.ByteStream(DelegatingStream.typed(imageFile.openRead()));
    var length = await imageFile.length();
    var uri = Uri.parse("${url}absensi");

    var request = new http.MultipartRequest("POST", uri);
    var multipartfile = new http.MultipartFile("photo", stream, length,
        filename: pth.basename(imageFile.path));

    request.files.add(multipartfile);
    request.fields["nip"] = drawNip;

    http.StreamedResponse response = await request.send();
    if (response.statusCode == 200) {
      prefs.setInt("status_absen", 1);
      prefs.commit();
      Navigator.pushReplacementNamed(context, HomePage.tag);
         _showDialogAbsensi("Status absensi berhasil");     
    } else if (response.statusCode == 417) {
        _showDialogAbsensi("Ini bukan wajah $drawName");    
    }
    setState(() {
      progress = false; 
    });  
  }

  void _showDialogAbsensi(String str) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            content: new Text(
              str,
              style: new TextStyle(fontSize: 18.0),
            ),
            actions: <Widget>[
              new RaisedButton(
                color: Colors.grey[400],
                child: new Text(
                  "Ok",
                  style: new TextStyle(color: Colors.black),
                ),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ],
          );
        });
  }

  void _showDialog() {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            content: new Text(
              "Apa anda akan melakukan proses absensi?",
              style: new TextStyle(fontSize: 18.0),
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
                  setState(() {
                    progress = true;
                    getImage();          
                  }); 
                  Navigator.pop(context);
                },
              ),
            ],
          );
        });
  }

  void _showDialogOut() {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            content: new Text(
              "Apa anda akan melakukan absen keluar?",
              style: new TextStyle(fontSize: 18.0),
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
                  _absenOut();
                  Navigator.pop(context);
                },
              ),
            ],
          );
        });
  }

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
        backgroundColor: Colors.blueGrey[50],
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
              onTap: () => Navigator.of(context).pushNamed(employee.tag),
              title: Text("Employee"),
              trailing: Icon(Icons.people),
            ),
            new ListTile(
              onTap: () {
                prefs.clear();
                prefs.commit();
                Navigator.pushReplacementNamed(context, LoginPage.tag);
              },
              title: Text("Sign Out"),
              trailing: Icon(Icons.power_settings_new),
            ),
          ],
        ),
      ),

      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: ExactAssetImage('img/background2.png'),
            fit: BoxFit.cover
          )
        ),
        child: Center(
          child:progress?progressBar: ListView(
            shrinkWrap: true,
            padding: EdgeInsets.only(left: 24.0, right: 24.0),
            children: <Widget>[
              RawMaterialButton(
                onPressed: () {
                  if (kondisi == 1) {
                    _showDialogOut();
                  } else {
                    _showDialog();
                  }
                },
                child: new Icon(
                  icon_btn(),
                  color: Colors.grey[800],
                  size: 100.0,
                ),
                shape: new CircleBorder( side: BorderSide(color: Colors.blueGrey[400])),
                elevation: 3.0,
                fillColor: color_btn(),
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
