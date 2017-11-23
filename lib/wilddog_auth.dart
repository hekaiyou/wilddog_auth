import 'dart:async';
import 'package:flutter/services.dart';

/// 从身份认证提供方返回的用户数据，WilddogAuth目前支持以下提供方：
/// 电子邮件地址与密码、QQ、微信、微信公众号、微博。
class UserInfo {
  // 声明数据词典。
  final Map<String, dynamic> _data;

  // 默认构造方法。
  UserInfo._(this._data);

  /// 获取身份认证提供方ID。
  String get providerId => _data['providerId'];

  /// 获取身份认证提供方用户ID。
  String get uid => _data['uid'];

  /// 获取用户的名字。
  String get displayName => _data['displayName'];

  /// 获取用户个人资料中的照片网址。
  String get photoUrl => _data['photoUrl'];

  /// 获取用户的电子邮件地址。
  String get email => _data['email'];

  /// 获取用户的手机号码。
  String get phone => _data['phone'];

  // 覆盖toString方法。
  @override
  String toString() {
    return '$runtimeType($_data)';
  }
}

/// 代表一个用户。
class WilddogUser extends UserInfo {
  // 声明UserInfo列表类型的认证提供方数据列表。
  final List<UserInfo> providerData;

  // 默认的构造方法。
  // 使用数据词典的字典分别创建UserInfo实类，并赋予认证提供方数据列表。
  //
  // 在构造函数体运行之前初始化实例变量，并调用父类的构造函数。
  // 子类构造函数手动调用父类的构造函数，在 : 号后面指定父类的构造函数。
  WilddogUser._(Map<String, dynamic> data)
      : providerData = data['providerData']
      .map((Map<String, dynamic> info) => new UserInfo._(info))
      .toList(),
        super._(data);

  // 用户是否是匿名的，是则返回true。
  // 即用户帐户是使用signInAnonymously()创建的，并且尚未绑定其他帐户。
  bool get isAnonymous => _data['isAnonymous'];

  /// 用户的电子邮件是否已验证，是则返回true。
  bool get isEmailVerified => _data['isEmailVerified'];

  /// 用户的手机号码是否已验证，是则返回true。
  bool get isPhoneVerified => _data['isPhoneVerified'];

  /// 获取当前用户的ID标识，如果需要可以强制刷新。
  /// 如果用户登出，则完成并显示错误。
  Future<String> getIdToken({bool refresh: false}) {
    // 用指定的参数在这个通道上调用一个方法。
    return WilddogAuth.channel.invokeMethod('getIdToken', <String, bool>{
      'refresh': refresh,
    });
  }

  // 覆盖toString方法。
  @override
  String toString() {
    return '$runtimeType($_data)';
  }
}

class WilddogAuth {
  // MethodChannel类是一个使用异步方法调用与平台插件通信的命名通道，
  // 这里创建一个指定名称为'wilddog_auth'的MethodChannel。
  static const MethodChannel channel = const MethodChannel('wilddog_auth');

  /*
  StreamController类是能控制stream的控制器。
  构造函数StreamController.broadcast创建一个控制器，其中stream可以被多次监听。

  Stream返回的stream是广播流，它可以监听多次。当没有监听器时，广播流不缓冲事件。

  一个stream应该是惰性的，直到用户开始监听（使用`onListen`回调开始生成事件）。
  当没有用户在stream上监听时，stream不应该泄漏资源（例如websockets）。

  当调用`add`、`addError`或`close`时，控制器会将任何事件分配给所有当前订阅的监听器。
  在前一次调用返回之前，不允许调用add、addError或close。
  控制器没有任何内部事件队列，如果在事件添加时没有监听器，它将被丢弃，
  或者如果是错误，则报告为未被捕获。

  每个监听器订阅是独立处理的，如果一个暂停，只有暂停监听器受到影响。
  暂停的监听器将在内部缓冲事件，直到取消暂停或取消。

  如果sync是true，则在add、addError或close调用期间，stream的订阅可能直接触发事件。
  返回的stream控制器是`SynchronousStreamController`，须谨慎使用，不要中断stream合同。

  如果sync为false，则在添加事件的代码完成后，事件将始终被触发。
  在这种情况下，对于多个监听器获取事件的时间不作任何保证，
  除了每个监听器将以正确的顺序获取所有事件。每个订阅单独处理事件。
  如果两个事件在具有两个监听器的异步控制器上发送，
  其中一个监听器可能会在另一个监听器获得任何事件之前获取这两个事件。
  当事件被启动时（即调用`add`时）以及事件以后发送时，必须同时订阅一个监听器，以便接收事件。

  当第一个监听器被订阅时，调用`onListen`回调，当不再有任何活动的监听器时调用`onCancel`。
  如果稍后再添加一个监听器，在调用onCancel之后，再次调用onListen。

  这里声明定义了管理StreamController<WilddogUser>的词典。
   */
  final Map<int, StreamController<WilddogUser>> _authStateChangedControllers =
  <int, StreamController<WilddogUser>>{};

  /// 提供与默认应用程序相对应的此类的实例，支持非默认的应用程序。
  static WilddogAuth instance = new WilddogAuth._();

  // 默认的构造方法。
  WilddogAuth._() {
    // setMethodCallHandler方法在此通道上设置接收方法调用的回调。
    channel.setMethodCallHandler(_callHandler);
  }

  /// 每次用户登录或登录时接收[WilddogUser]。
  Stream<WilddogUser> get onAuthStateChanged {
    // 声明句柄变量。
    Future<int> _handle;
  // 声明StreamController类的实例变量。
    StreamController<WilddogUser> controller;
    // 构造函数StreamController.broadcast创建一个控制器。
    // 使用onListen回调开始生成事件。
    controller = new StreamController<WilddogUser>.broadcast(onListen: () {
      // 定义句柄变量，并接收startListeningAuthState方法调用的结果。
      _handle = channel.invokeMethod('startListeningAuthState');
      // then方法注册回调将在这个Future完成时被调用。
      _handle.then((int handle) {
        // 在_authStateChangedControllers词典中添加一个字典。
        _authStateChangedControllers[handle] = controller;
      });
    // 当不再有任何活动的监听器时调用onCancel。
    }, onCancel: () {
      // then方法注册回调将在这个Future完成时被调用。
      _handle.then((int handle) async {
        // 接收stopListeningAuthState方法调用的结果。
        await channel.invokeMethod(
            "stopListeningAuthState", <String, int>{"id": handle});
        // 在_authStateChangedControllers词典中移除指定字典。
        _authStateChangedControllers.remove(handle);
      });
    });

    // Stream返回的stream是广播流，它可以监听多次。
    return controller.stream;
  }

  /// 异步创建并成为匿名用户。
  ///
  /// 如果已经有一个匿名用户登录，则该用户将被返回。如果有其他现有用户登录，该用户将被注销。
  ///
  /// 如果抛出异常，表示匿名帐户未启用，在Wilddog控制台的"身份认证"部分启用它们。
  /// 请参阅WDGAuthErrors以获取所有API方法通用的错误代码列表。
  ///
  /// 实现匿名身份认证需要在“控制面板 身份认证—登录方式”中打开匿名登录方式。
  /// 匿名帐号数据将不会被保存，可以通过绑定邮箱认证或第三方认证方式将匿名帐号转成永久帐号。
  Future<WilddogUser> signInAnonymously() async {
    // 声明数据词典。
    WilddogUser currentUser;
    // 调用signInAnonymously方法。
    await channel.invokeMethod('signInAnonymously').then((onValue){
      if(onValue.runtimeType==String){
        // 返回null说明操作失败。
        currentUser = null;
      }else{
        // 定义数据词典，并接收调用的结果。
        currentUser = new WilddogUser._(onValue);
      }
    });
    // 返回WilddogUser实例。
    return currentUser;
  }

  /// 更新用户邮箱或手机号认证密码。
  ///
  /// 更新当前登录认证用户的密码信息。
  /// 需要注意的是，要更新密码，该用户必须最近登录过（重新进行身份认证）。
  Future<String> updatePassword(String password) async {
    // 认证密码不能为空。
    assert(password != null);
    // 接收updateEmail方法调用的结果。
    return await channel.invokeMethod(
      'updatePassword',
      <String, String>{
        'password': password,
      },
    );
  }

  /// 使用电子邮件和密码异步创建用户。
  /// 
  /// 创建一个新用户，创建成功后会自动登录
  Future<WilddogUser> createUserWithEmailAndPassword({
    String email,
    String password,
  }) async {
    // 电子邮件和密码不能为空。
    assert(email != null);
    assert(password != null);
    // 声明数据词典。
    WilddogUser currentUser;
    // 调用createUserWithEmailAndPassword方法。
    await channel.invokeMethod(
      'createUserWithEmailAndPassword',
      <String, String>{
        'email': email,
        'password': password,
      },
    ).then((onValue){
      if(onValue.runtimeType==String){
        // 返回null说明操作失败。
        currentUser = null;
      }else{
        // 定义数据词典，并接收调用的结果。
        currentUser = new WilddogUser._(onValue);
      }
    });
    // 返回WilddogUser实例。
    return currentUser;
  }

  /// 使用电子邮箱和密码异步登录。
  Future<WilddogUser> signInWithEmailAndPassword({
    String email,
    String password,
  }) async {
    // 电子邮件和密码不能为空。
    assert(email != null);
    assert(password != null);
    // 声明数据词典。
    WilddogUser currentUser;
    // 调用signInWithEmailAndPassword方法。
    await channel.invokeMethod(
      'signInWithEmailAndPassword',
      <String, String>{
        'email': email,
        'password': password,
      },
    ).then((onValue){
      if(onValue.runtimeType==String){
        // 返回null说明操作失败。
        currentUser = null;
      }else{
        // 定义数据词典，并接收调用的结果。
        currentUser = new WilddogUser._(onValue);
      }
    });
    // 返回WilddogUser实例。
    return currentUser;
  }

  /// 异步发送电子邮箱验证邮件。
  ///
  /// 在控制面板“身份认证—登录方式—邮箱登录—配置”中定制邮箱验证邮件模版。
  Future<String> sendEmailVerification() async {
    // 接收sendEmailVerification方法调用的结果。
    return await channel.invokeMethod("sendEmailVerification");
  }

  /// 异步发送重置密码邮件。
  ///
  /// 在控制面板“身份认证—登录方式—邮箱登录—配置”中定制重置密码邮件模版。
  Future<String> sendPasswordResetEmail(String email) async {
    // 帐号邮箱不能为空。
    assert(email != null);
    // 接收sendPasswordResetEmail方法调用的结果。
    return await channel.invokeMethod(
      'sendPasswordResetEmail',
      <String, String>{
        'email': email,
      },
    );
  }

  /// 异步更新用户邮箱地址。
  ///
  /// 更新帐号邮箱，如果更新成功，本地缓存也会刷新。
  /// 如果这个邮箱已经创建过用户，则会更新失败。
  /// 需要注意的是，要更新用户的邮箱地址，该用户必须最近登录过。
  ///
  /// 更新邮箱地址会向旧邮箱发送提醒邮件，
  /// 在控制面板“身份认证—登录方式—邮箱登录—配置”中定制更新邮箱邮件模版。
  Future<String> updateEmail(String email) async {
    // 帐号邮箱不能为空。
    assert(email != null);
    // 接收updateEmail方法调用的结果。
    return await channel.invokeMethod(
      'updateEmail',
      <String, String>{
        'email': email,
      },
    );
  }

  /// 异步注销登录。
  ///
  /// 登出当前用户，清除登录数据。
  Future<String> signOut() async {
    // 接收signOut方法调用的结果。
    return await channel.invokeMethod("signOut");
  }

  /// 删除用户
  ///
  /// 从Wilddog Auth系统中删除当前用户，
  /// 也可以在控制面板"身份认证—用户"中手动删除。
  Future<String> delete() async {
    // 接收delete方法调用的结果。
    return await channel.invokeMethod("delete");
  }

  /// 异步重新进行邮箱帐户认证。
  ///
  /// 用户长时间未登录的情况下进行下列安全敏感操作会失败：
  /// 删除帐户、设置主邮箱地址、更改密码。此时需要重新对用户进行身份认证。
  Future<String> reauthenticateEmail({
    String email,
    String password,
  }) async {
    // 电子邮件和密码不能为空。
    assert(email != null);
    assert(password != null);
    // 接收reauthenticateEmail方法调用的结果。
    return await channel.invokeMethod(
      'reauthenticateEmail',
      <String, String>{
        'email': email,
        'password': password,
      },
    );
  }

  /// 异步获取当前用户，如果没有则返回null。
  ///
  /// Wilddog Auth中用户有一组基本属性：Wilddog ID、主邮箱地址、名称、照片地址，
  /// 获取当前登录用户是管理用户的基础。
  Future<WilddogUser> currentUser() async {
    // 声明定义数据词典，并接收currentUser方法调用的结果。
    final Map<String, dynamic> data = await channel.invokeMethod("currentUser");
    // 声明定义WilddogUser类的实例变量，如果数据词典为空，则返回null值。
    final WilddogUser currentUser = data == null ? null : new WilddogUser._(data);
    // 返回WilddogUser实例。
    return currentUser;
  }

  /// 将电子邮件帐户与当前用户关联并返回[Future<WilddogUser>]，
  /// 基本上是当前用户与附加的电子邮件信息。
  ///
  /// 抛出[PlatformException]时：
  /// 1. 电子邮件地址已被使用。
  /// 2. 提供错误的电子邮件和密码。
  ///
  /// 如果用户使用其他认证方式登录，可以将当前用户与给定的邮箱认证方式绑定，
  /// 之后支持绑定的邮箱认证方式登录。（必须是未被使用的邮箱）
  Future<WilddogUser> linkWithEmailAndPassword({
    String email,
    String password,
  }) async {
    // 电子邮件和密码不能为空。
    assert(email != null);
    assert(password != null);
    // 声明数据词典。
    WilddogUser currentUser;
    // 调用createUserWithPhoneAndPassword方法。
    await channel.invokeMethod(
      'linkWithEmailAndPassword',
      <String, String>{
        'email': email,
        'password': password,
      },
    ).then((onValue){
      if(onValue.runtimeType==String){
        // 返回null说明操作失败。
        currentUser = null;
      }else{
        // 定义数据词典，并接收调用的结果。
        currentUser = new WilddogUser._(onValue);
      }
    });
    // 返回WilddogUser实例。
    return currentUser;
  }

  /// 异步更新用户属性，更新用户的姓名和头像URL。
  Future<String> updateProfile({
    String displayName,
    String photoURL,
  }) async {
    // 用户姓名和头像不能为空。
    assert(displayName != null);
    assert(photoURL != null);
    // 接收updateProfile方法调用的结果。
    return await channel.invokeMethod(
      'updateProfile',
      <String, String>{
        'displayName': displayName,
        'photoURL': photoURL,
      },
    );
  }

  /// 使用手机号和密码异步创建用户。
  ///
  /// 创建一个新用户，创建成功后会自动登录
  Future<WilddogUser> createUserWithPhoneAndPassword({
    String phone,
    String password,
  }) async {
    // 手机号和密码不能为空。
    assert(phone != null);
    assert(password != null);
    // 声明数据词典。
    WilddogUser currentUser;
    // 调用createUserWithPhoneAndPassword方法。
    await channel.invokeMethod(
      'createUserWithPhoneAndPassword',
      <String, String>{
        'phone': phone,
        'password': password,
      },
    ).then((onValue){
      if(onValue.runtimeType==String){
        // 返回null说明操作失败。
        currentUser = null;
      }else{
        // 定义数据词典，并接收调用的结果。
        currentUser = new WilddogUser._(onValue);
      }
    });
    // 返回WilddogUser实例。
    return currentUser;
  }

  /// 使用手机号和密码异步登录。
  Future<WilddogUser> signInWithPhoneAndPassword({
    String phone,
    String password,
  }) async {
    // 手机号和密码不能为空。
    assert(phone != null);
    assert(password != null);
    // 声明数据词典。
    WilddogUser currentUser;
    // 调用signInWithPhoneAndPassword方法。
    await channel.invokeMethod(
      'signInWithPhoneAndPassword',
      <String, String>{
        'phone': phone,
        'password': password,
      },
    ).then((onValue){
      if(onValue.runtimeType==String){
        // 返回null说明操作失败。
        currentUser = null;
      }else{
        // 定义数据词典，并接收调用的结果。
        currentUser = new WilddogUser._(onValue);
      }
    });
    // 返回WilddogUser实例。
    return currentUser;
  }

  /// 异步发送验证用户的手机验证码。
  ///
  /// 在控制面板“身份认证—登录方式—手机登录—配置”中定制验证号码短信模版。
  Future<String> sendPhoneVerification() async {
    // 接收sendPhoneVerification方法调用的结果。
    return await channel.invokeMethod("sendPhoneVerification");
  }

  /// 异步确认验证用户的手机验证码。
  ///
  /// 发送验证用户的手机验证码后，用户手机验证码需要用此方法验证。
  Future<String> verifyPhoneSmsCode(String realSms) async {
    // 验证码不能为空。
    assert(realSms != null);
    // 接收verifyPhoneSmsCode方法调用的结果。
    return await channel.invokeMethod(
      'verifyPhoneSmsCode',
      <String, String>{
        'realSms': realSms,
      },
    );
  }

  /// 异步发送重置密码的手机验证码。
  ///
  /// 在控制面板“身份认证—登录方式—手机登录—配置”中定制重置密码短信模版。
  Future<String> sendPasswordResetSms(String phone) async {
    // 手机号不能为空。
    assert(phone != null);
    // 接收sendPasswordResetSms方法调用的结果。
    return await channel.invokeMethod('sendPasswordResetSms',
      <String, String>{
        'phone': phone,
      },
    );
  }

  /// 异步确认重置密码的手机验证码。
  ///
  /// 发送重置密码的手机验证码后，用户手机验证码需要用此方法验证。
  /// 通过手机号码，验证码来修改密码。之后可以使用新密码进行手机号认证方式登录。
  Future<String> confirmPasswordResetSms({
    String phone,
    String realSms,
    String newPassword,
  }) async {
    // 手机号、验证码和密码不能为空。
    assert(phone != null);
    assert(realSms != null);
    assert(newPassword != null);
    // 接收confirmPasswordResetSms方法调用的结果。
    return await channel.invokeMethod(
      'confirmPasswordResetSms',
      <String, String>{
        'phone': phone,
        'realSms': realSms,
        'newPassword': newPassword,
      },
    );
  }

  /// 异步更新用户手机号码。
  ///
  /// 更新手机号码，如果更新成功，本地缓存也会刷新。
  /// 如果这个手机号码已经创建过用户，则会更新失败。
  /// 需要注意的是，要更新用户的手机号码，该用户必须最近登录过。
  Future<String> updatePhone(String phone) async {
    // 手机号不能为空。
    assert(phone != null);
    // 接收updatePhone方法调用的结果。
    return await channel.invokeMethod(
      'updatePhone',
      <String, String>{
        'phone': phone,
      },
    );
  }

  /// 异步重新进行手机帐户认证。
  ///
  /// 用户长时间未登录的情况下进行下列安全敏感操作会失败：
  /// 删除帐户、设置主邮箱地址、更改密码。此时需要重新对用户进行身份认证。
  Future<String> reauthenticatePhone({
    String phone,
    String password,
  }) async {
    // 手机号和密码不能为空。
    assert(phone != null);
    assert(password != null);
    // 接收reauthenticateEmail方法调用的结果。
    return await channel.invokeMethod(
      'reauthenticatePhone',
      <String, String>{
        'phone': phone,
        'password': password,
      },
    );
  }

  // 接收方法调用的回调。
  // MethodCall类表示调用命名方法的命令对象，method属性是要调用的方法的名称。
  Future<Null> _callHandler(MethodCall call) async {
    // 判断要调用的方法的名称
    switch (call.method) {
      // 如果方法名称等于指定字符串
      case "onAuthStateChanged":
        // 在认证阶段更改处理程序。
        _onAuthStageChangedHandler(call);
        // 结束判断
        break;
    }
    // 返回空值
    return null;
  }

  // 在认证阶段更改处理程序。
  // arguments属性是该方法的参数，返回的是dynamic(动态)类型数据。
  void _onAuthStageChangedHandler(MethodCall call) {
    // 声明定义数据词典，并获取调用参数中的user键
    final Map<String, dynamic> data = call.arguments["user"];
    // 声明定义ID变量，并获取调用参数中的id键
    final int id = call.arguments["id"];
    // 声明定义WilddogUser类实例，
    // 数据词典不等于空，则调用WilddogUser的默认构造方法，否则返回空值。
    final WilddogUser currentUser = data != null ? new WilddogUser._(data) : null;
    // 在管理StreamController<WilddogUser>的词典中添加一个字典
    _authStateChangedControllers[id].add(currentUser);
  }
}