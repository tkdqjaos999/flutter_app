import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_app/src/detail_page.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

final FirebaseMessaging _firebaseMessaging = FirebaseMessaging();

class ChatPage extends StatefulWidget {
  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {

  bool didTokenUpdated = false;
  File _image;
  var screeWidth, screenHeight;
  var chat = [];
  var textController;
  String device_id = '';
  List<Choice> choices = <Choice>[
    Choice(title: 'Settings', icon: Icons.settings),
    Choice(title: 'Log out', icon: Icons.exit_to_app),
  ];

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    textController = TextEditingController();
    firebaseCloudMessaging_Listeners();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    textController.dispose();
    super.dispose();
  }

  void firebaseCloudMessaging_Listeners() {
    _firebaseMessaging.getToken().then((token) {
      device_id = token;
    });

    _firebaseMessaging.configure(
      onMessage: (Map<String, dynamic> message) async {
        print('on message $message');
      },
      onLaunch: (Map<String, dynamic> message) async {
        print('on resume $message');
      },
      onResume: (Map<String, dynamic> message) async {
        print('on launch $message');
      },
    );
  }

  Future getImage() async {
    var image = await ImagePicker.pickImage(source: ImageSource.gallery);

    setState(() {
      _image = image;
    });
  }

  @override
  Widget build(BuildContext context) {
    if(!didTokenUpdated)updateToken();
    return Scaffold(
      backgroundColor: Color(0xFF4A4A58),
      body: ListView(
        children: <Widget>[
          SizedBox(height: MediaQuery.of(context).padding.top),
          Stack(
            children: <Widget>[
              Container(
                height: 50,
              ),
              Padding(
                padding: EdgeInsets.only(left: 15, right: 15),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Icon(
                        Icons.arrow_back_ios,
                        color: Colors.white,
                      ),
                      PopupMenuButton(
                          color: Color(0xFF4A4A58),
                          child: Icon(
                            Icons.menu,
                            color: Colors.white,
                          ),

                          itemBuilder: (context) {
                            return choices.map((Choice choice) {
                              return PopupMenuItem<Choice>(
                                  value: choice,
                                  child: Row(
                                    children: <Widget>[
                                      Icon(
                                        choice.icon,
                                        color: Colors.white,
                                      ),
                                      SizedBox(
                                        width: 10,
                                      ),
                                      Text(
                                        choice.title,
                                        style: TextStyle(color: Colors.white),
                                      )
                                    ],
                                  ));
                            }).toList();
                          })
                    ],
                  ),
                ),
              )
            ],
          ),
          Container(
            height: MediaQuery.of(context).size.height -
                100 -
                2 * MediaQuery.of(context).padding.top,
            child: StreamBuilder(
                stream: Firestore.instance.collection('log').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Container();
                  }
                  chat = snapshot.data.documents ?? [];
                  if (!chat.isEmpty) {
                    chat.sort((a, b) => (b['order']).compareTo(a['order']));
                  }

                  return ListView.builder(
                      reverse: true,
                      itemCount: chat.length,
                      itemBuilder: (context, index) {
                        if (chat[index]['path'] == null&&chat[index]['msg']!=null) {
                          return _buildChat(chat[index]['msg'],
                              chat[index]['dId'], chat[index]['time']);
                        } else if(chat[index]['msg']==null&&chat[index]['path']!=null){
                          return _buildImageFile(chat[index]['path'],
                              chat[index]['dId'], chat[index]['time']);
                        } else {
                          return _buildDate(chat[index]['date']);
                        }
                      });
                }),
          ),
          Container(
            height: 50,
            decoration: BoxDecoration(color: Colors.white, boxShadow: [
              BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  blurRadius: 3,
                  spreadRadius: 3)
            ]),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                IconButton(
                    icon: Icon(
                      Icons.add_circle_outline,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      dateSubmit();
                      getImage().then((onValue){
                        final firebaseStorageRef = FirebaseStorage.instance
                            .ref()
                            .child('image')
                            .child('${DateTime.now().millisecondsSinceEpoch}.png');
                        final task = firebaseStorageRef.putFile(
                          _image, StorageMetadata(contentType: 'image/png')
                        );
                        task.onComplete.then((value){
                          var downloadUrl = value.ref.getDownloadURL();
                          downloadUrl.then((uri){
                            var doc = Firestore.instance.collection('log').document();
                            doc.setData({
                              'id': doc.documentID,
                              'msg': null,
                              'time':
                              '${DateTime.now().hour < 12 ? '오전' : '오후'} ${DateFormat('kk:mm').format(DateTime.now())}',
                              'order': '${DateTime.now().millisecondsSinceEpoch}',
                              'dId': device_id,
                              'path': uri.toString(),
                              'date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
                            });
                          });
                        });
                      });
                    }),
                SizedBox(
                  width: 10,
                ),
                Flexible(
                  fit: FlexFit.tight,
                  child: TextField(
                    onSubmitted: textSubmit,
                    controller: textController,
                    decoration: InputDecoration(border: InputBorder.none),
                    autofocus: false,
                    maxLines: null,
                    keyboardType: TextInputType.text,
                    textInputAction: TextInputAction.newline,
                  ),
                ),
                SizedBox(
                  width: 10,
                ),
                IconButton(
                    icon: Icon(
                      Icons.send,
                      color: Colors.yellow,
                    ),
                    onPressed: () {
                      textSubmit(textController.text);
                    }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void dateSubmit(){
    if(chat.isEmpty)return;
    if(chat[0]['date']!=DateFormat('yyyy-MM-dd').format(DateTime.now())){
      var doc = Firestore.instance.collection('log').document();
      doc.setData({
        'id': doc.documentID,
        'msg': null,
        'time': null,
        'order': '${DateTime.now().millisecondsSinceEpoch}',
        'dId': device_id,
        'path': null,
        'date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
      });
    }
  }

  void textSubmit(String text) {
    textController.clear();
    if (text != '') {
      dateSubmit();
      var doc = Firestore.instance.collection('log').document();
      doc.setData({
        'id': doc.documentID,
        'msg': text,
        'time':
            '${DateTime.now().hour < 12 ? '오전' : '오후'} ${DateFormat('kk:mm').format(DateTime.now())}',
        'order': '${DateTime.now().millisecondsSinceEpoch}',
        'dId': device_id,
        'path': null,
        'date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
      });
    }
  }

  Widget idConfigure(bool idSame) {
    if (idSame) {
      return Flexible(fit: FlexFit.tight, child: Container());
    } else {
      return Container();
    }
  }

  Widget _buildChat(String msg, String id, String time) {
    return Container(
        margin: EdgeInsets.only(left: 15, right: 15, top: 5, bottom: 5),
        decoration: BoxDecoration(
          color: Colors.transparent,
        ),
        child: Row(
          children: <Widget>[
            idConfigure(id == device_id),
            Container(
              width: MediaQuery.of(context).size.width * 0.8,
              child: Column(
                crossAxisAlignment: id == device_id
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.only(left: 10, right: 10, top: 5, bottom: 10),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5),
                        boxShadow: [
                          BoxShadow(color: Colors.grey.withOpacity(0.2))
                        ],
                        border: Border.all(color: Colors.grey.withOpacity(0.3)),
                        color: Colors.white),
                    child: Text(
                      msg,
                      style: TextStyle(height: 1.6, fontFamily: 'josun', fontSize: 14, color: Colors.black),
                    ),
                  ),
                  SizedBox(height: 5,),
                  Text(
                    time,
                    style: TextStyle(fontFamily: 'josun', fontSize: 10, color: Colors.white),
                  ),
                ],
              ),
            ),
            idConfigure(id != device_id),
          ],
        ));
  }

  Widget _buildImageFile(String imgPath, String id, String time) {
    return Container(
        margin: EdgeInsets.only(left: 15, right: 15, top: 5, bottom: 5),
        decoration: BoxDecoration(
          color: Colors.transparent,
        ),
        child: Row(
          children: <Widget>[
            idConfigure(id == device_id),
            Container(
              width: MediaQuery.of(context).size.width * 0.8,
              child: Column(
                crossAxisAlignment: id == device_id
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: <Widget>[
                  InkWell(
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => DetailPage(
                              heroTag: imgPath,
                            ))),
                    child: Hero(
                      tag: imgPath,
                      child: Container(
                        padding: const EdgeInsets.all(10.0),
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(5),
                            boxShadow: [
                              BoxShadow(color: Colors.grey.withOpacity(0.2))
                            ],
                            border:
                                Border.all(color: Colors.grey.withOpacity(0.3)),
                            color: Colors.white),
                        child: CachedNetworkImage(
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                          imageUrl: imgPath,
                          placeholder: (context, url) => CircularProgressIndicator(),
                          errorWidget: (context, url, error) => Icon(Icons.error_outline),
                        )
                      ),
                    ),
                  ),
                  SizedBox(height: 5,),
                  Text(
                    time,
                    style: TextStyle(fontFamily: 'josun', fontSize: 10, color: Colors.white),
                  ),
                ],
              ),
            ),
            idConfigure(id != device_id),
          ],
        ));
  }

  Widget _buildDate(String date) {
    return Container(
      margin: EdgeInsets.only(top: 5, bottom: 5),
      padding: EdgeInsets.only(top: 5, bottom: 5),
      width: MediaQuery.of(context).size.width,
      decoration: BoxDecoration(
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2),
        spreadRadius: 1,
        blurRadius: 1)]
      ),
      child: Center(
        child: Text(date, style: TextStyle(
            fontFamily: 'josun', fontSize: 12, color: Colors.white
        ),),
      ),
    );
  }

  void updateToken() async {

    var token = await _firebaseMessaging.getToken();

    var doc = Firestore.instance.collection('tokens').document(token);
    doc.setData({
      'token': token
    }).then((value){
      setState(() {
        didTokenUpdated = true;
      });
    });
  }
}

class Choice {
  Choice({this.title, this.icon});

  final String title;
  final IconData icon;
}
