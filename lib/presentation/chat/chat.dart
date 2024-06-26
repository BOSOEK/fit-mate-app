import 'dart:convert';
import 'dart:ui';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitmate/ui/colors.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_bubble/clippers/chat_bubble_clipper_1.dart';
import 'package:flutter_svg/svg.dart';
import 'package:http/http.dart' as http;

import 'package:flutter_chat_bubble/bubble_type.dart';
import 'package:flutter_chat_bubble/chat_bubble.dart';

import '../../domain/util.dart';
import '../../ui/show_toast.dart';
import '../make_promise/make_promise.dart';
import '../profile/other_profile.dart';

class ChatPage extends StatefulWidget {
  String name;
  String imageUrl;
  String uid;
  String userId;
  String chatId;
  ChatPage({Key? key, required this.chatId, required this.name, required this.imageUrl, required this.uid, required this.userId}) : super(key: key);

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  CollectionReference chats = FirebaseFirestore.instance.collection('chats');
  var chatDocId;
  var _textController = new TextEditingController();
  var data;


  @override
  void initState() {
    super.initState();
  }

  Future<bool> checkUser() async {
    while(chatDocId.runtimeType.toString() != 'String') {
      await chats
          .where('users', isEqualTo: {widget.uid: null, UserData['social']['user_id']: null})
          .limit(1)
          .get()
          .then(
            (QuerySnapshot querySnapshot) async {
          if (querySnapshot.docs.isNotEmpty) {
            setState(() {
              chatDocId = querySnapshot.docs.single.id;
            });

          } else {
            await chats.add({
              'users': {widget.uid: null, UserData['social']['user_id']: null},
              'names':{widget.uid:widget.name, UserData['social']['user_id']:UserData['social']['user_name'] }
            }).then((value) {
              setState(() {
                chatDocId = value;
              });
            });
          }
        },
      )
          .catchError((error) {
      });
    }
    return true;
  }

  void sendMessage(String msg) {
    if (msg == '') return;
    chats.doc(chatDocId).collection('messages').add({
      'createdOn': FieldValue.serverTimestamp(),
      'uid': UserData['social']['user_id'],
      'friendName':widget.uid,
      'msg': msg
    }).then((value) {
      _textController.text = '';
    });
  }

  bool isSender(String friend) {
    return friend == UserData['social']['user_id'];
  }

  Alignment getAlignment(friend) {
    if (friend == UserData['social']['user_id']) {
      return Alignment.topRight;
    }
    return Alignment.topLeft;
  }

  void _showBlockUserDialog() {
    showDialog(
        context: context,
        barrierDismissible: true, // 바깥 영역 터치시 닫을지 여부
        builder: (BuildContext context) {
          return AlertDialog(
            content: Text("사용자를 차단하시겠습니까?",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            insetPadding: const EdgeInsets.fromLTRB(50, 80, 20, 80),
            actions: [
              Container(
                margin: EdgeInsets.fromLTRB(0, 0, 0, 10),
                width: 40,
                height: 32,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Color(0xFFF2F3F7),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFFffffff),
                      spreadRadius: 2,
                      blurRadius: 8,
                      offset: Offset(-2, -2),
                    ),
                    BoxShadow(
                      color: Color.fromRGBO(55, 84, 170, 0.1),
                      spreadRadius: 2,
                      blurRadius: 2,
                      offset: Offset(2, 2),
                    ),
                  ],
                ),
                child: Theme(
                  data: ThemeData(
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                  ),
                  child: TextButton(
                    child: Text(
                      "확인",
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.black,
                          fontWeight: FontWeight.bold),
                    ),
                    onPressed: () async {
                      print('차단');
                      http.Response response = await http.post(
                          Uri.parse(
                              "https://fitmate.co.kr/v2/users/blockuser"),
                          headers: {
                            "Authorization": "bearer $IdToken",
                          },
                          body: {
                            "blocked_user_id": "${widget.userId}"
                          });
                      var resBody =
                      jsonDecode(utf8.decode(response.bodyBytes));
                      print(resBody);
                      if (response.statusCode != 200 &&
                          resBody["error"]["code"] ==
                              "auth/id-token-expired") {
                        IdToken = (await FirebaseAuth.instance.currentUser
                            ?.getIdTokenResult(true))!
                            .token
                            .toString();

                        response = await http.post(
                            Uri.parse(
                                "https://fitmate.co.kr/v2/users/blockuser"),
                            headers: {
                              "Authorization": "bearer $IdToken",
                            },
                            body: {
                              "blocked_user_id": "${widget.userId}"
                            });
                        resBody = jsonDecode(utf8.decode(response.bodyBytes));
                      }
                      print("before toast");
                      if (resBody['success'] == true) {
                        FlutterToastBottom('사용자가 차단되었습니다.');
                      } else {
                        FlutterToastBottom('에러가 발생했습니다.');
                      }
                      var temp = await UpdateUserData();
                      Navigator.pop(context);
                    },
                  ),
                ),
              ),
              SizedBox(
                width: 20,
              ),
              Container(
                margin: EdgeInsets.fromLTRB(0, 0, 20, 10),
                width: 60,
                height: 32,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Color(0xFFF2F3F7),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFFffffff),
                      spreadRadius: 2,
                      blurRadius: 8,
                      offset: Offset(-2, -2),
                    ),
                    BoxShadow(
                      color: Color.fromRGBO(55, 84, 170, 0.1),
                      spreadRadius: 2,
                      blurRadius: 2,
                      offset: Offset(2, 2),
                    ),
                  ],
                ),
                child: Theme(
                  data: ThemeData(
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                  ),
                  child: TextButton(
                    child: Text(
                      '아니오',
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.black,
                          fontWeight: FontWeight.bold),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ),
              ),
            ],
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    print("chat Id : ${widget.chatId}");
    print("docId : $chatDocId");
    return FutureBuilder(
      future: checkUser(),
      builder: (context, snapshot) {
        print("snapshot : ${snapshot.data}");
        if (snapshot.hasData) {
          return StreamBuilder<QuerySnapshot>(
            stream: chats
                .doc(chatDocId)
                .collection('messages')
                .orderBy('createdOn', descending: true)
                .snapshots(),
            builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
              print("snapshot : $snapshot");
              print("snapshot data : ${snapshot.data}");
              print("snapshot hasdata : ${snapshot.hasData}");
              if (snapshot.hasError) {
                return Center(
                  child: Text("Something went wrong"),
                );
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
                /*
                return Center(
                  child: Text(
                    "Loading",
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFFffffff),
                    ),
                  ),
                );
                 */
              }
              if (snapshot.hasData) {
                print('snapshot data : ${snapshot.data}');
                var data;
                return Scaffold(
                  backgroundColor: whiteTheme,
                  appBar: AppBar(
                    toolbarHeight: 60,
                    backgroundColor: whiteTheme,
                    elevation: 0,
                    automaticallyImplyLeading: false,
                    leadingWidth: 64,
                    leading: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 0, 8),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Color(0xFFF2F3F7),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0xFFffffff),
                              spreadRadius: 2,
                              blurRadius: 8,
                              offset: Offset(-2, -2),
                            ),
                            BoxShadow(
                              color: Color.fromRGBO(55, 84, 170, 0.1),
                              spreadRadius: 2,
                              blurRadius: 2,
                              offset: Offset(2, 2),
                            ),
                          ],
                        ),
                        child: Theme(
                          data: ThemeData(
                            splashColor: Colors.transparent,
                            highlightColor: Colors.transparent,
                          ),
                          child: IconButton(
                            icon: SvgPicture.asset(
                              "assets/icon/bar_icons/back_icon.svg",
                              width: 16,
                              height: 16,
                            ),
                            onPressed: () {
                              Navigator.pop(context);
                            },
                          ),
                        ),
                      ),
                    ),
                    title: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          CupertinoPageRoute(
                            builder: (context) => OtherProfilePage(
                              profileId: widget.userId,
                              profileName: '${widget.name}',
                            ),
                          ),
                        );
                      },
                      child: Container(
                        margin: EdgeInsets.only(left: 10),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(100.0),
                              child: Image(
                                image: CachedNetworkImageProvider('${widget.imageUrl}'),
                                width: 32,
                                height: 32,
                                fit: BoxFit.cover,
                                errorBuilder: (BuildContext context, Object exception, StackTrace? stackTrace) {
                                  return Image.asset(
                                    'assets/images/profile_null_image.png',
                                    width: 32.0,
                                    height: 32.0,
                                    fit: BoxFit.cover,
                                  );
                                },
                              ),
                            ),
                            SizedBox(
                              width: 16,
                            ),
                            Text(
                              '${widget.name}',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    actions: [
                      Padding(
                        padding: EdgeInsets.fromLTRB(0, 8, 20, 8),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: Color(0xFFF2F3F7),
                            boxShadow: [
                              BoxShadow(
                                color: Color(0xFFffffff),
                                spreadRadius: 2,
                                blurRadius: 8,
                                offset: Offset(-2, -2),
                              ),
                              BoxShadow(
                                color: Color.fromRGBO(55, 84, 170, 0.1),
                                spreadRadius: 2,
                                blurRadius: 2,
                                offset: Offset(2, 2),
                              ),
                            ],
                          ),
                          child: Theme(
                            data: ThemeData(
                              splashColor: Colors.transparent,
                              highlightColor: Colors.transparent,
                            ),
                            child: IconButton(
                              icon: SvgPicture.asset(
                                "assets/icon/burger_icon.svg",
                                width: 16,
                                height: 16,
                              ),
                              onPressed: () {
                                showModalBottomSheet(
                                    isScrollControlled: true,
                                    context: context,
                                    shape: const RoundedRectangleBorder(
                                      // <-- SEE HERE
                                      borderRadius: BorderRadius.vertical(
                                        top: Radius.circular(40.0),
                                      ),
                                    ),
                                    backgroundColor: Color(0xFFF2F3F7),
                                    builder: (BuildContext context) {
                                      return Wrap(
                                        children: [
                                          Column(
                                            children: [
                                              SizedBox(
                                                height: 20,
                                              ),
                                              Container(
                                                width: 40,
                                                height: 4,
                                                decoration: BoxDecoration(
                                                  borderRadius: BorderRadius.circular(2.0),
                                                  color: Color(0xFFD1D9E6),
                                                ),
                                              ),
                                              SizedBox(
                                                height: 36,
                                              ),
                                              GestureDetector(
                                                onTap: () {
                                                  print("Container clicked");
                                                  Navigator.push(
                                                    context,
                                                    PageRouteBuilder(
                                                      pageBuilder: (context, animation, secondaryAnimation) => MakePromisePage(partnerId: widget.userId),
                                                      transitionDuration: Duration.zero,
                                                      reverseTransitionDuration: Duration.zero,
                                                    ),
                                                  );
                                                },
                                                child: Container(
                                                  padding:
                                                  EdgeInsets.fromLTRB(20, 22, 20, 20),
                                                  height: 64,
                                                  color: whiteTheme,
                                                  child: Row(
                                                    mainAxisAlignment: MainAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        '매칭 잡기',
                                                        style: TextStyle(
                                                          color: Color(0xFF000000),
                                                          fontSize: 16,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              GestureDetector(
                                                onTap: () async {
                                                  _showBlockUserDialog();
                                                },
                                                child: Container(
                                                  padding:
                                                  EdgeInsets.fromLTRB(20, 22, 20, 20),
                                                  height: 64,
                                                  color: whiteTheme,
                                                  child: Row(
                                                    mainAxisAlignment:
                                                    MainAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        '사용자 차단',
                                                        style: TextStyle(
                                                          color: Colors.black,
                                                          fontSize: 16,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              GestureDetector(
                                                onTap: () async {
                                                  http.Response response = await http.delete(Uri.parse("${baseUrlV1}chats/${widget.chatId}"),
                                                    headers: {
                                                      "Authorization" : "bearer $IdToken",
                                                      "chatroomId" : "${widget.chatId}"
                                                    },
                                                  );
                                                  var resBody = jsonDecode(utf8.decode(response.bodyBytes));
                                                  if(response.statusCode != 200 && resBody["error"]["code"] == "auth/id-token-expired") {
                                                    IdToken = (await FirebaseAuth.instance.currentUser?.getIdTokenResult(true))!.token.toString();

                                                    response = await http.delete(Uri.parse("${baseUrlV1}chats/${widget.chatId}"),
                                                      headers: {
                                                        "Authorization" : "bearer $IdToken",
                                                        "chatroomId" : "${widget.chatId}"
                                                      },
                                                    );
                                                    resBody = jsonDecode(utf8.decode(response.bodyBytes));
                                                  }

                                                  for(int i = 0; i < chatList.length; i++) {
                                                    if(chatList[i]['_id'] == widget.chatId) {
                                                      chatList.removeAt(i);
                                                      break;
                                                    }
                                                  }
                                                  Navigator.pop(context);
                                                  Navigator.pop(context, true);
                                                },
                                                child: Container(
                                                  padding:
                                                  EdgeInsets.fromLTRB(20, 22, 20, 20),
                                                  color: whiteTheme,
                                                  height: 64,
                                                  child: Row(
                                                    mainAxisAlignment: MainAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        '채팅방 나가기',
                                                        style: TextStyle(
                                                          color: Color(0xFFCF2933),
                                                          fontSize: 16,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              (Platform.isIOS)
                                                  ? SizedBox(height: 30,)
                                                  : SizedBox(
                                              ),
                                            ],
                                          ),
                                        ],
                                      );
                                    });
                              },
                            ),
                          ),
                        ),
                      )
                    ],
                    /*
                    leading: IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: Icon(
                        Icons.arrow_back,
                      ),
                    ),
                    shape: Border(
                      bottom: BorderSide(
                        color: Color(0xFF3D3D3D),
                        width: 1,
                      ),
                    ),
                    title: Transform(
                      transform: Matrix4.translationValues(-20.0, 0.0, 0.0),
                      child: Text(
                        "${widget.name}",
                        style: TextStyle(
                          color: Color(0xFFffffff),
                          fontSize: 20.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    actions: [
                      Padding(
                        padding: EdgeInsets.fromLTRB(0, 10, 0, 10),
                        child: ElevatedButton(
                          onPressed: () async {
                            Navigator.push(
                              context,
                              PageRouteBuilder(
                                pageBuilder: (context, animation, secondaryAnimation) => MakePromisePage(partnerId: widget.userId),
                                transitionDuration: Duration.zero,
                                reverseTransitionDuration: Duration.zero,
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            minimumSize: Size(80, 35),
                            primary: Color(0xFF22232A),
                            alignment: Alignment.center,
                            side: BorderSide(
                              width: 1.5,
                              color: Color(0xFFffffff),
                            ),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(7.0)),
                          ),
                          child:Text(
                            '약속잡기',
                            style: TextStyle(
                              color: Color(0xFFffffff),
                              fontSize: 16.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      PopupMenuButton(
                        iconSize: 30,
                        color: Color(0xFF22232A),
                        shape: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Color(0xFF757575),
                            width: 1,
                          ),
                          borderRadius: BorderRadius.all(Radius.circular(5.0)),
                        ),
                        elevation: 40,
                        onSelected: (value) async {
                          if (value == '/chatout') {
                            showDialog(
                              context: context,
                              //barrierDismissible: false,
                              builder: (BuildContext ctx) {
                                return AlertDialog(
                                  backgroundColor: Color(0xFF22232A),
                                  content: Text(
                                    '채팅방을 나가시면 채팅 목록 및 대화 내용이 삭제되고 복구 할 수 없어요. 채팅방을 나가시겠어요?',
                                    style: TextStyle(
                                      color: Color(0xFFffffff),
                                    ),
                                  ),

                                  actions: [
                                    Center(
                                      child: Column(
                                        children: [
                                          ElevatedButton(
                                            child: Text('네, 나갈레요.'),
                                            onPressed: () async {
                                              http.Response response = await http.delete(Uri.parse("${baseUrlV1}chats/${widget.chatId}"),
                                                headers: {
                                                  "Authorization" : "bearer $IdToken",
                                                  "chatroomId" : "${widget.chatId}"
                                                },
                                              );
                                              var resBody = jsonDecode(utf8.decode(response.bodyBytes));
                                              if(response.statusCode != 200 && resBody["error"]["code"] == "auth/id-token-expired") {
                                                IdToken = (await FirebaseAuth.instance.currentUser?.getIdTokenResult(true))!.token.toString();

                                                response = await http.delete(Uri.parse("${baseUrlV1}chats/${widget.chatId}"),
                                                  headers: {
                                                    "Authorization" : "bearer $IdToken",
                                                    "chatroomId" : "${widget.chatId}"
                                                  },
                                                );
                                                resBody = jsonDecode(utf8.decode(response.bodyBytes));
                                              }
                                              Navigator.pushReplacement(
                                                context,
                                                PageRouteBuilder(
                                                  pageBuilder: (context, animation, secondaryAnimation) => ChatListPage(),
                                                  transitionDuration: Duration.zero,
                                                  reverseTransitionDuration: Duration.zero,
                                                ),
                                              );
                                            },
                                          ),
                                          ElevatedButton(
                                            child: Text('취소'),
                                            onPressed: () {
                                              Navigator.pop(context);
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              },
                            );
                          }
                        },
                        itemBuilder: (BuildContext bc) {
                          return [
                            PopupMenuItem(
                              child: Text(
                                '채팅방 나가기',
                                style: TextStyle(
                                  color: Color(0xFFffffff),
                                ),
                              ),
                              value: '/chatout',
                            ),
                          ];
                        },
                      ),
                    ],

                     */
                  ),
                  body: SafeArea(
                    child: Column(
                      children: [
                        Expanded(
                          child: ListView(
                            reverse: true,
                            children: snapshot.data!.docs.map(
                                  (DocumentSnapshot document) {
                                data = document.data()!;
                                print('document : ${document.toString()}');
                                print(data);
                                String time = data['createdOn'] == null
                                    ? DateTime.now().toString().substring(11, 16)
                                    : data['createdOn']
                                    .toDate()
                                    .toString().substring(11, 16);
                                String amPm = '오전';
                                if(int.parse(time.substring(0,2)) > 12) {
                                  amPm = '오후';
                                  time = '${int.parse(time.substring(0,2))-12}:${time.substring(3,5)}';
                                }
                                else time = '${int.parse(time.substring(0,2))}:${time.substring(3,5)}';
                                return Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                  child: ChatBubble(
                                    elevation: 0,
                                    clipper: ChatBubbleClipper1(
                                      nipWidth: 10,
                                      nipHeight: 5,
                                      type: isSender(data['uid'].toString())
                                          ? BubbleType.sendBubble
                                          : BubbleType.receiverBubble,
                                      //nipSize: 8,
                                      //radius: 0,
                                      //type: isSender(data['uid'].toString())
                                      //    ? BubbleType.sendBubble
                                      //    : BubbleType.receiverBubble,
                                    ),
                                    alignment: getAlignment(data['uid'].toString()),
                                    margin: EdgeInsets.only(top: 20),
                                    backGroundColor: isSender(data['uid'].toString())
                                        ? Color(0xFF6E7995)
                                        : Color(0xFFFFFFFF),
                                    child: IntrinsicWidth(
                                      child: Container(
                                        constraints: BoxConstraints(
                                          maxWidth: MediaQuery.of(context).size.width * 0.7,
                                        ),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Column(
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.start,
                                              crossAxisAlignment: CrossAxisAlignment.end,
                                              children: [
                                                Flexible(
                                                  child: RichText(
                                                    overflow: TextOverflow.ellipsis,
                                                    maxLines: 100,
                                                    strutStyle: StrutStyle(fontSize: 14),
                                                    text: TextSpan(
                                                      text: data['msg'],
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        color: isSender(data['uid'].toString()) ? Color(0xFFffffff) : Color(0xFF000000),
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(width: 16,),
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.end,
                                                  children: [
                                                    Text(
                                                      '${amPm} ${time}',
                                                      style: TextStyle(
                                                          fontSize: 10,
                                                          color: isSender(
                                                              data['uid'].toString())
                                                              ? Color(0xFFD1D9E6)
                                                              : Colors.black),
                                                    )
                                                  ],
                                                )
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ).toList(),
                          ),
                        ),
                        SizedBox(height: 24,),
                        Container(
                          padding: EdgeInsets.fromLTRB(20, 0, 14, 0),
                          height: 60,
                          decoration: BoxDecoration(
                            color: Color(0xFFF2F3F7),
                            boxShadow: [
                              BoxShadow(
                                color: Color.fromRGBO(55, 84, 170, 0.1),
                                spreadRadius: 4,
                                blurRadius: 12,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(0, 5, 0, 10),
                                  child: TextField(
                                    style: TextStyle(
                                      color: Color(0xFF757575),
                                      fontSize: 17,
                                    ),
                                    decoration: InputDecoration(
                                      //contentPadding: EdgeInsets.symmetric(vertical: 2.0),
                                      contentPadding: EdgeInsets.fromLTRB(15, 0, 10, 0),
                                      focusedBorder: InputBorder.none,
                                      enabledBorder: InputBorder.none,
                                      filled: true,
                                      hintText: '메시지 작성..',
                                      hintStyle: TextStyle(
                                        color: Color(0xFFD1D9E6),
                                      ),
                                      fillColor: whiteTheme,
                                    ),
                                    controller: _textController,
                                  ),
                                ),
                              ),
                              CupertinoButton(
                                  child: Icon(
                                    Icons.send_sharp,
                                    size: 18,
                                  ),
                                  onPressed: () {
                                    sendMessage(_textController.value.text.toString());
                                  }
                              )
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                );
              } else {
                print("시발");
                return Container();
              }
            },
          );
        } else if (snapshot.hasError) {
          return Text("${snapshot.error}");
        }
        // 기본적으로 로딩 Spinner를 보여줍니다.
        return Center(child: CircularProgressIndicator());
      },
    );
  }
}