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
    if(user == null){
      return '当前没有用户登录';
    }else{
      return '获取当前用户成功：$user';
    }
  }

  // 测试匿名登录。
  Future<String> _testSignInAnonymously() async {
    final WilddogUser user = await _auth.signInAnonymously();
    if(user != null){
      return '匿名登录成功：$user';
    }else{
      return '匿名登录失败';
    }
  }

  // 测试更新用户属性
  Future<String> _testUpdateProfile() async {
    String result = await _auth.updateProfile(
      displayName: 'hekaiyou',
      photoURL: 'https://example.com/hekaiyou/profile.jpg'
    );
    if(result == null){
      return '更新用户属性成功';
    }else{
      return '异常信息：$result';
    }
  }

  // 测试更新用户邮箱或手机号认证密码。
  Future<String> _testUpdatePassword() async {
    String result = await _auth.updatePassword('654321');
    if(result == null){
      return '更新邮箱或手机密码成功';
    }else{
      return '异常信息：$result';
    }
  }

  // 测试使用电子邮箱和密码登录。
  Future<String> _testSignInWithEmailAndPassword() async {
    final WilddogUser user = await _auth.signInWithEmailAndPassword(
      email: 'hky2014@yeah.net',
      password: '123456',
    );
    if(user != null){
      return '使用电子邮箱和密码登录成功：$user';
    }else{
      return '使用电子邮箱和密码登录失败';
    }
  }

  // 测试使用电子邮箱和密码创建用户。
  Future<String> _testCreateUserWithEmailAndPassword() async {
    final WilddogUser user = await _auth.createUserWithEmailAndPassword(
      email: 'hky2014@yeah.net',
      password: '123456',
    );
    if(user != null){
      return '使用电子邮箱和密码创建用户成功：$user';
    }else{
      return '使用电子邮箱和密码创建用户失败';
    }
  }

  // 测试将电子邮箱帐户与当前用户关联。
  Future<String> _testLinkWithEmailAndPassword() async {
    final WilddogUser user = await _auth.linkWithEmailAndPassword(
      email: 'hky2014@yeah.net',
      password: '123456',
    );
    if(user != null){
      return '将电子邮箱帐户与当前用户关联成功：$user';
    }else{
      return '将电子邮箱帐户与当前用户关联失败';
    }
  }

  // 测试发送电子邮箱验证邮件。
  Future<String> _testSendEmailVerification() async {
    String result = await _auth.sendEmailVerification();
    if(result == null){
      return '发送电子邮箱验证邮件成功';
    }else{
      return '异常信息：$result';
    }
  }

  // 测试发送重置密码邮件。
  Future<String> _testSendPasswordResetEmail() async {
    String result = await _auth.sendPasswordResetEmail('hky2014@yeah.net');
    if(result == null){
      return '发送重置密码邮件成功';
    }else{
      return '异常信息：$result';
    }
  }

  // 测试更新用户邮箱地址。
  Future<String> _testUpdateEmail() async {
    String result = await _auth.updateEmail('new_hky2014@qq.com');
    if(result == null){
      return '更新用户邮箱地址成功';
    }else{
      return '异常信息：$result';
    }
  }

  // 测试重新进行邮箱帐户认证。
  Future<String> _testReauthenticateEmail() async {
    String result = await _auth.reauthenticateEmail(
      email: 'hky2014@yeah.net',
      password: '123456',
    );
    if(result == null){
      return '重新进行邮箱帐户认证成功';
    }else{
      return '异常信息：$result';
    }
  }

  // 测试使用手机号和密码创建用户。
  Future<String> _testCreateUserWithPhoneAndPassword() async {
    final WilddogUser user = await _auth.createUserWithPhoneAndPassword(
      phone: '13800000000',
      password: '123456',
    );
    if(user != null){
      return '使用手机号和密码创建用户成功：$user';
    }else{
      return '使用手机号和密码创建用户失败';
    }
  }

  // 测试使用手机号和密码登录。
  Future<String> _testSignInWithPhoneAndPassword() async {
    final WilddogUser user = await _auth.signInWithPhoneAndPassword(
      phone: '13800000000',
      password: '123456',
    );
    if(user != null){
      return '使用手机号和密码登录成功：$user';
    }else{
      return '使用手机号和密码登录失败';
    }
  }

  // 测试发送验证用户的手机验证码。
  Future<String> _testSendPhoneVerification() async {
    String result = await _auth.sendPhoneVerification();
    if(result == null){
      return '发送验证用户的手机验证码成功';
    }else{
      return '异常信息：$result';
    }
  }

  // 测试确认验证用户的手机验证码。
  Future<String> _testVerifyPhoneSmsCode() async {
    String result = await _auth.verifyPhoneSmsCode('208345');
    if(result == null){
      return '确认验证用户的手机验证码正确';
    }else{
      return '异常信息：$result';
    }
  }

  // 测试发送重置密码的手机验证码。
  Future<String> _testSendPasswordResetSms() async {
    String result = await _auth.sendPasswordResetSms('13800000000');
    if(result == null){
      return '发送重置密码的手机验证码成功';
    }else{
      return '异常信息：$result';
    }
  }

  // 测试确认重置密码的手机验证码。
  Future<String> _testConfirmPasswordResetSms() async {
    String result = await _auth.confirmPasswordResetSms(
      phone: '13800000000',
      realSms: '849371',
      newPassword: '123456',
    );
    if(result == null){
      return '确认重置密码的手机验证码正确';
    }else{
      return '异常信息：$result';
    }
  }

  // 测试更新用户手机号码。
  Future<String> _testUpdatePhone() async {
    String result = await _auth.updatePhone('13800000000');
    if(result == null){
      return '更新用户手机号码成功';
    }else{
      return '异常信息：$result';
    }
  }

  // 测试重新进行手机帐户认证。
  Future<String> _testReauthenticatePhone() async {
    String result = await _auth.reauthenticatePhone(
      phone: '13800000000',
      password: '123456',
    );
    if(result == null){
      return '重新进行手机帐户认证成功';
    }else{
      return '异常信息：$result';
    }
  }

  // 测试退出登录。
  Future<String> _testSignOut() async {
    String result = await _auth.signOut();
    if(result == null){
      return '退出登录成功';
    }else{
      return '异常信息：$result';
    }
  }

  // 测试删除用户。
  Future<String> _testDelete() async {
    String result = await _auth.delete();
    if(result == null){
      return '删除用户成功';
    }else{
      return '异常信息：$result';
    }
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
              child: const Text('使用手机号和密码创建用户'),
              onPressed: (){
                setState((){
                  _message = _testCreateUserWithPhoneAndPassword();
                });
              },
            ),
            new MaterialButton(
              child: const Text('使用手机号和密码登录'),
              onPressed: (){
                setState((){
                  _message = _testSignInWithPhoneAndPassword();
                });
              },
            ),
            new MaterialButton(
              child: const Text('重新进行手机帐户认证'),
              onPressed: (){
                setState((){
                  _message = _testReauthenticatePhone();
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
