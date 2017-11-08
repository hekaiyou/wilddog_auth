import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:wilddog_auth/wilddog_auth.dart';

// 为应用程序提供默认的WilddogAuth类实例。
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

  // 测试匿名登录。
  Future<String> _testSignInAnonymously() async {
    // 异步创建并成为匿名用户。
    final WilddogUser user = await _auth.signInAnonymously();
    // 匿名用户不能等于null。
    assert(user != null);
    // 用户需要是匿名的。
    assert(user.isAnonymous);
    // 用户的电子邮件需要是未验证。
    assert(!user.isEmailVerified);
    // 当前用户的ID标识不能等于null。
    assert(await user.getIdToken() != null);
    // 判断平台类型。
    // 匿名身份验证不会在iOS上显示认证提供方。
    // 匿名身份验证在Android上显示认证提供方。
    if (Platform.isIOS) {
      // 认证提供方数据列表需要是空的。
      assert(user.providerData.isEmpty);
    } else if (Platform.isAndroid) {
      // 认证提供方数据列表的长度需要等于1。
      assert(user.providerData.length == 1);
      // 认证提供方数据列表下标[0]的提供方ID需要等于wilddog。
      assert(user.providerData[0].providerId == 'wilddog');
      // 认证提供方数据列表下标[0]的用户ID不能等于null。
      assert(user.providerData[0].uid != null);
      // 认证提供方数据列表下标[0]的用户名字需要等于null。
      assert(user.providerData[0].displayName == null);
      // 认证提供方数据列表下标[0]的个人照片网址需要等于null。
      assert(user.providerData[0].photoUrl == null);
      // 认证提供方数据列表下标[0]的电子邮件地址需要等于null。
      assert(user.providerData[0].email == null);
    }

    // 异步获取当前用户，如果没有则返回null。
    final WilddogUser currentUser = await _auth.currentUser();
    // 认证提供方用户ID需要等于当前用户ID。
    assert(user.uid == currentUser.uid);

    // 返回结果。
    return '登录匿名成功：$user';
  }

  // 测试使用电子邮件和密码创建用户。
  Future<String> _testCreateUserWithEmailAndPassword() async {
    // 使用电子邮件和密码异步创建用户。
    final WilddogUser user = await _auth.createUserWithEmailAndPassword(
      email: 'hky2014@yeah.net',
      password: '123456',
    );
//    assert(user.email != null);
//    assert(user.displayName != null);
//    assert(!user.isAnonymous);
//    assert(await user.getIdToken() != null);

    // 异步获取当前用户，如果没有则返回null。
    //final WilddogUser currentUser = await _auth.currentUser();
    // 认证提供方用户ID需要等于当前用户ID。
    //assert(user.uid == currentUser.uid);

    // 返回结果。
    return '使用电子邮件和密码创建用户成功：$user';
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
                setState((){
                  _message = _testCreateUserWithEmailAndPassword();
                });
              },
            ),
            new FutureBuilder<String>(
                future: _message,
                builder: (_, AsyncSnapshot<String> snapshot) {
                  return new Text(
                      snapshot.data ?? '',
                      style: const TextStyle(
                          color: const Color.fromARGB(255, 0, 155, 0))
                  );
                }
            ),
          ],
        ),
      ),
    );
  }
}
