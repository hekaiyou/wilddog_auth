import 'dart:async';

import 'package:flutter/services.dart';
import 'package:meta/meta.dart';

/// 代表从身份提供者返回的用户数据。
class UserInfo {
  final Map<String, dynamic> _data;

  UserInfo._(this._data);

  /// 提供者标识符。
  String get providerId => _data['providerId'];

  /// 提供者的用户ID。
  String get uid => _data['uid'];

  /// 用户的名字。
  String get displayName => _data['displayName'];

  /// 用户的个人资料照片的网址。
  String get photoUrl => _data['photoUrl'];

  /// 用户的电子邮件地址。
  String get email => _data['email'];

  @override
  String toString() {
    return '$runtimeType($_data)';
  }
}

/// 代表一个用户。
class WilddogUser extends UserInfo {
  final List<UserInfo> providerData;

  WilddogUser._(Map<String, dynamic> data)
      : providerData = data['providerData']
      .map((Map<String, dynamic> info) => new UserInfo._(info))
      .toList(),
        super._(data);

  // 如果用户是匿名的，则返回true；也就是说，用户帐户是使用signInAnonymously()创建的，
  // 并且尚未链接到其他帐户。
  bool get isAnonymous => _data['isAnonymous'];

  /// 如果用户的电子邮件已验证，则返回true。
  bool get isEmailVerified => _data['isEmailVerified'];

  /// 获取当前用户的id标识，如果需要，强制刷新。
  ///
  /// 如果用户登出，则完成并显示错误。
  Future<String> getIdToken({bool refresh: false}) {
    return WilddogAuth.channel.invokeMethod('getIdToken', <String, bool>{
      'refresh': refresh,
    });
  }

  @override
  String toString() {
    return '$runtimeType($_data)';
  }
}

class WilddogAuth {
  @visibleForTesting
  static const MethodChannel channel = const MethodChannel('wilddog_auth');

  final Map<int, StreamController<WilddogUser>> _authStateChangedControllers =
  <int, StreamController<WilddogUser>>{};

  /// 提供与默认应用程序相对应的此类的实例。
  ///
  /// 支持非默认的应用程序。
  static WilddogAuth instance = new WilddogAuth._();

  WilddogAuth._() {
    channel.setMethodCallHandler(_callHandler);
  }

  /// 每次用户登录或登录时接收[WilddogUser]。
  Stream<WilddogUser> get onAuthStateChanged {
    Future<int> _handle;

    StreamController<WilddogUser> controller;
    controller = new StreamController<WilddogUser>.broadcast(onListen: () {
      _handle = channel.invokeMethod('startListeningAuthState');
      _handle.then((int handle) {
        _authStateChangedControllers[handle] = controller;
      });
    }, onCancel: () {
      _handle.then((int handle) async {
        await channel.invokeMethod(
            "stopListeningAuthState", <String, int>{"id": handle});
        _authStateChangedControllers.remove(handle);
      });
    });

    return controller.stream;
  }

  /// 异步创建并成为匿名用户。
  ///
  /// 如果已经有一个匿名用户登录，则该用户将被返回。如果有其他现有用户登录，该用户将被注销。
  ///
  /// 如果WDGAuthErrorCodeOperationNotAllowed将抛出PlatformException，
  /// 表示匿名帐户未启用，在Wilddog控制台的"身份认证"部分启用它们。
  /// 请参阅WDGAuthErrors以获取所有API方法通用的错误代码列表。
  Future<WilddogUser> signInAnonymously() async {
    final Map<String, dynamic> data =
    await channel.invokeMethod('signInAnonymously');
    final WilddogUser currentUser = new WilddogUser._(data);
    return currentUser;
  }

  Future<Null> _callHandler(MethodCall call) async {
    switch (call.method) {
      case "onAuthStateChanged":
        _onAuthStageChangedHandler(call);
        break;
    }
    return null;
  }

  void _onAuthStageChangedHandler(MethodCall call) {
    final Map<String, dynamic> data = call.arguments["user"];
    final int id = call.arguments["id"];

    final WilddogUser currentUser =
    data != null ? new WilddogUser._(data) : null;
    _authStateChangedControllers[id].add(currentUser);
  }
}
