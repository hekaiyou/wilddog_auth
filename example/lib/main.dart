import 'dart:async';
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
                    //_message = _testSignInAnonymously();
                  });
                },
            ),
            new MaterialButton(
              child: const Text('测试邮箱登录'),
              onPressed: (){
                setState((){
                  //_message = _testSignInAnonymously();
                });
              },
            ),
            new FutureBuilder<String>(
                future: _message,
                builder: null)
          ],
        ),
      ),
    );
  }
}
