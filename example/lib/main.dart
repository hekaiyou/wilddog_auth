import 'dart:async';
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

  // 测试获取当前用户。
  Future<String> _testCurrentUser() async {
    final WilddogUser user = await _auth.currentUser();
    return '获取当前用户成功：$user';
  }

  // 测试匿名登录。
  Future<String> _testSignInAnonymously() async {
    final WilddogUser user = await _auth.signInAnonymously();
    assert(user != null);
    return '登录匿名成功：$user';
  }

  // 测试更新用户属性
  Future<Null> _testUpdateProfile() async {
    await _auth.updateProfile(
      displayName: 'hekaiyou',
      photoURL: 'https://example.com/hekaiyou/profile.jpg'
    );
  }

  // 测试更新用户邮箱或手机号认证密码。
  Future<Null> _testUpdatePassword() async {
    final WilddogUser currentUser = await _auth.currentUser();
    assert(!currentUser.isAnonymous);
    await _auth.updatePassword('654321');
  }

  // 测试使用电子邮箱和密码登录。
  Future<String> _testSignInWithEmailAndPassword() async {
    final WilddogUser user = await _auth.signInWithEmailAndPassword(
      email: 'hky2014@yeah.net',
      password: '123456',
    );
    assert(user != null);
    return '使用电子邮箱和密码登录成功：$user';
  }

  // 测试使用电子邮箱和密码创建用户。
  Future<String> _testCreateUserWithEmailAndPassword() async {
    final WilddogUser user = await _auth.createUserWithEmailAndPassword(
      email: 'hky2014@yeah.net',
      password: '123456',
    );
    assert(user != null);
    return '使用电子邮箱和密码创建用户成功：$user';
  }

  // 测试将电子邮箱帐户与当前用户关联。
  Future<String> _testLinkWithEmailAndPassword() async {
    final WilddogUser user = await _auth.linkWithEmailAndPassword(
      email: 'hky2014@yeah.net',
      password: '123456',
    );
    assert(user != null);
    return '将电子邮箱帐户与当前用户关联成功：$user';
  }

  // 测试发送电子邮箱验证邮件。
  Future<Null> _testSendEmailVerification() async {
    await _auth.sendEmailVerification();
  }

  // 测试发送重置密码邮件。
  Future<Null> _testSendPasswordResetEmail() async {
    await _auth.sendPasswordResetEmail('hky2014@yeah.net');
  }

  // 测试更新用户邮箱地址。
  Future<Null> _testUpdateEmail() async {
    await _auth.updateEmail('952114868@qq.com');
  }

  // 测试重新进行邮箱帐户认证。
  Future<Null> _testReauthenticateEmail() async {
    await _auth.reauthenticateEmail(
      email: 'hky2014@yeah.net',
      password: '123456',
    );
  }

  // 测试退出登录。
  Future<Null> _testSignOut() async {
    await _auth.signOut();
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
              child: const Text('获取当前用户'),
              onPressed: (){
                setState((){
                  _message = _testCurrentUser();
                });
              },
            ),
            new MaterialButton(
              child: const Text('匿名登录'),
              onPressed: (){
                setState((){
                  _message = _testSignInAnonymously();
                });
              },
            ),
            new MaterialButton(
              child: const Text('更新用户属性'),
              onPressed: (){
                setState((){
                  _message = _testUpdateProfile();
                });
              },
            ),
            new MaterialButton(
              child: const Text('更新用户邮箱或手机号认证密码'),
              onPressed: (){
                setState((){
                  _message = _testUpdatePassword();
                });
              },
            ),
            new MaterialButton(
              child: const Text('使用电子邮箱和密码创建用户'),
              onPressed: (){
                setState((){
                  _message = _testCreateUserWithEmailAndPassword();
                });
              },
            ),
            new MaterialButton(
              child: const Text('将电子邮箱帐户与当前用户关联'),
              onPressed: (){
                setState((){
                  _message = _testLinkWithEmailAndPassword();
                });
              },
            ),
            new MaterialButton(
              child: const Text('使用电子邮箱和密码登录'),
              onPressed: (){
                setState((){
                  _message = _testSignInWithEmailAndPassword();
                });
              },
            ),
            new MaterialButton(
              child: const Text('发送电子邮箱验证邮件'),
              onPressed: (){
                setState((){
                  _message = _testSendEmailVerification();
                });
              },
            ),
            new MaterialButton(
              child: const Text('更新用户邮箱地址'),
              onPressed: (){
                setState((){
                  _message = _testUpdateEmail();
                });
              },
            ),
            new MaterialButton(
              child: const Text('发送重置密码邮件'),
              onPressed: (){
                setState((){
                  _message = _testSendPasswordResetEmail();
                });
              },
            ),
            new MaterialButton(
              child: const Text('重新进行邮箱帐户认证'),
              onPressed: (){
                setState((){
                  _message = _testReauthenticateEmail();
                });
              },
            ),
            new MaterialButton(
              child: const Text('退出登录'),
              onPressed: (){
                setState((){
                  _message = _testSignOut();
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
