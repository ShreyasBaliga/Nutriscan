import 'dart:async';
import 'dart:io';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'DetailScreen.dart';
import 'getcal.dart';
import 'dispValues.dart';
import 'pedomet.dart';
import 'main.dart';

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  File _imageFile;
  Size _imageSize;
  dynamic _scanResults;
  Information data;

  List<String> labs = new List<String>();

  Future<String> makeRequest(List<String> names) async {
    for (var i = 0; i < names.length; i++) {
      var url = 'https://sheetlabs.com/DDX/FoodFacts?displayname=' + names[i];
      var response = await http.get(Uri.encodeFull(url));
      setState(() {
        var extractdata = json.decode(response.body);
        if (extractdata.length != 0) {
          data = new Information(
              names[i],
              extractdata[0]["calories"].toString(),
              extractdata[0]["saturatedfats"].toString());
          _showNutriDialoge();
          return 0;
        }
      });
    }
  }

  Future<void> cameraImage() async {
    setState(() {
      _imageFile = null;
      _imageSize = null;
    });

    final File imageFile =
        await ImagePicker.pickImage(source: ImageSource.camera);

    if (imageFile != null) {
      _getImageSize(imageFile);
      _scanImage(imageFile);
    }

    setState(() {
      _imageFile = imageFile;
    });
  }

  Future<void> storageImage() async {
    setState(() {
      _imageFile = null;
      _imageSize = null;
    });

    final File imageFile =
        await ImagePicker.pickImage(source: ImageSource.gallery);

    if (imageFile != null) {
      _getImageSize(imageFile);
      _scanImage(imageFile);
    }

    setState(() {
      _imageFile = imageFile;
    });
  }

  Future<void> _optionsDialogBox() {
    return showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            content: new SingleChildScrollView(
              child: new ListBody(
                children: <Widget>[
                  GestureDetector(
                      child: new Text('Take a picture'),
                      onTap: () {
                        cameraImage();
                        //Navigator.of(context).pop();
                      }),
                  Padding(
                    padding: EdgeInsets.all(8.0),
                  ),
                  GestureDetector(
                    child: new Text('Select from gallery'),
                    onTap: () {
                      storageImage();
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
            ),
          );
        });
  }

  Future<void> _getImageSize(File imageFile) async {
    final Completer<Size> completer = Completer<Size>();

    final Image image = Image.file(imageFile);
    // image.image.resolve(const ImageConfiguration()).addListener(
    //   (ImageInfo info, bool _) {
    //     completer.complete(Size(
    //       info.image.width.toDouble(),
    //       info.image.height.toDouble(),
    //     ));
    //   },
    // );

    final Size imageSize = await completer.future;
    setState(() {
      _imageSize = imageSize;
    });
  }

  Future<void> _scanImage(File imageFile) async {
    setState(() {
      _scanResults = null;
    });

    final FirebaseVisionImage visionImage =
        FirebaseVisionImage.fromFile(imageFile);

    dynamic results;

    final CloudLabelDetector detector =
        FirebaseVision.instance.cloudLabelDetector();
    results = await detector.detectInImage(visionImage);

    setState(() {
      _scanResults = results;
      sendData();
    });
  }

  void sendData() {
    final List<Label> labels = _scanResults;

    for (var i = 0; i < 3; i++) {
      labs.add(labels[i].label);
      print(labels[i].label);
    }
    makeRequest(labs);
  }

  void _showNutriDialoge() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DispValues(udata: data),
      ),
    );
    // flutter defined function
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0XFF262626),
      body: Center(
        child: new Column(children: [
          new Container(height: 50.0),
          new Container(
              padding: const EdgeInsets.all(10.0),
              child: StreamBuilder<QuerySnapshot>(
                stream: Firestore.instance.collection('details').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return LinearProgressIndicator();
                  final record =
                      Record.fromSnapshot(snapshot.data.documents[0]);
                  return CircularPercentIndicator(
                    radius: 200.0,
                    lineWidth: 10.0,
                    animation: true,
                    percent: (record.curCal / record.maxCal) / 1.0,
                    center: Text(
                      record.curCal.toString() +
                          "/" +
                          record.maxCal.toString() +
                          "\nCalories",
                      style: new TextStyle(
                        fontFamily: "Roboto",
                        fontSize: 20.0,
                        color: Colors.white,
                      ),
                    ),
                    backgroundColor: Colors.grey,
                    progressColor: const Color(0XFFA2C101),
                  );
                },
              )),
          Container(height: 120.0),
          Container(
            height: 100.0,
            width: 100.0,
            child: FittedBox(
              child: FloatingActionButton(
                heroTag: "camerabtn",
                backgroundColor: const Color(0XFFA2C101),
                onPressed: _optionsDialogBox,
                tooltip: ' ',
                child: const Icon(
                  Icons.camera_alt,
                  size: 35,
                  color: const Color(0XFF262626),
                ),
              ),
            ),
          ),
          new Container(height: 40.0),
          Row(
            children: <Widget>[
              new Container(width: 60.0),
              Container(
                height: 75.0,
                width: 75.0,
                child: FittedBox(
                  child: FloatingActionButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PedoMeter(),
                        ),
                      );
                    },
                    heroTag: 'stepbtn',
                    backgroundColor: const Color(0XFFFDA104),
                    tooltip: ' ',
                    child: Center(
                      child: Image.asset(
                        "assets/foot.png",
                        height: 30.0,
                        width: 30.0,
                      ),
                    ),
                  ),
                ),
              ),
              new Container(width: 120.0),
              Container(
                height: 75.0,
                width: 75.0,
                child: FittedBox(
                  child: FloatingActionButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MyHomePage(),
                        ),
                      );
                    },
                    heroTag: "bmibtn",
                    backgroundColor: const Color(0XFFFDA104),
                    tooltip: ' ',
                    child: Center(
                      child: Image.asset(
                        "assets/scale.png",
                        height: 30.0,
                        width: 30.0,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ]),
      ),
    );
  }
}
