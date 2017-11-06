import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:wilddog_auth/wilddog_auth.dart';

final WilddogAuth _auth = WilddogAuth.instance;

void main() {
  runApp(new MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => new _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Future<String> _message = new Future<String>.value('');

  Future<String> _testSignInAnonymously() async {
    final WilddogUser user = await _auth.signInAnonymously();
    assert(user != null);
    assert(user.isAnonymous);
    assert(!user.isEmailVerified);
    assert(await user.getIdToken() != null);
    if (Platform.isIOS) {
      // 匿名身份验证不会在iOS上显示认证提供方
      assert(user.providerData.isEmpty);
    } else if (Platform.isAndroid) {
      // 匿名身份验证在Android上显示认证提供方
      assert(user.providerData.length == 1);
      assert(user.providerData[0].providerId == 'wilddog');
      assert(user.providerData[0].uid != null);
      assert(user.providerData[0].displayName == null);
      assert(user.providerData[0].photoUrl == null);
      assert(user.providerData[0].email == null);
    }

    final WilddogUser currentUser = await _auth.currentUser();
    assert(user.uid == currentUser.uid);

    return 'signInAnonymously succeeded: $user';
  }

  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      home: new Scaffold(
        appBar: new AppBar(
          title: new Text('野狗身份认证'),
        ),
        body: new Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            new MaterialButton(
                child: const Text('测试匿名登录'),
                onPressed: (){
                  setState((){
                    _message = _testSignInAnonymously();
                  });
                },
            ),
            new MaterialButton(
              child: const Text('测试邮箱登录'),
              onPressed: (){
//                setState((){
                  //_message = _testSignInAnonymously();
//                });
              },
            ),
//            new FutureBuilder<String>(
//                future: _message,
//                builder: null)
          ],
        ),
      ),
    );
  }
}
