#import "WilddogAuthPlugin.h"
#import "Wilddog.h"

// 声明NSError类
@interface NSError (FlutterError)
// 声明一个FlutterError类型的对象
// 使用readonly时表示编译器会自动生成getter方法，同时不会生成setter方法
// 原子性的控制使用nanatomic，不进行监控，线程不安全的
@property(readonly, nonatomic) FlutterError *flutterError;
// 类的声明已结束
@end

// 实现NSError类
@implementation NSError (FlutterError)
- (FlutterError *)flutterError {
  // 返回错误代码、信息和细节
  return [FlutterError errorWithCode:[NSString stringWithFormat:@"Error %d", (int)self.code]
    message:self.domain
    details:self.localizedDescription];
}
// 类的实现已结束
@end

// 返回一个包含用户属性的词典
//
// 在Objective-C中，id类型是一个独特的数据类型。在概念上，类似Java的Object类
// 可以转换为任何数据类型，换句话说，id类型的变量可以存放任何数据类型的对象
NSDictionary *toDictionary(id<WDGUserInfo> userInfo) {
  // 返回一个词典
  return @{
    // providerID用于获取用户登录方式，即身份认证提供方的ID
    //
    // Provider是身份认证提供方，WilddogAuth目前支持以下Provider
    // 电子邮件地址与密码、QQ、微信、微信公众号、微博
    @"providerId" : userInfo.providerID ?: [NSNull null],
    // displayName用于获取用户名
    @"displayName" : userInfo.displayName ?: [NSNull null],
    // uid用于获取用户ID
    @"uid" : userInfo.uid ?: [NSNull null],
    // photoURL用于获取用户头像
    @"photoUrl" : [NSString stringWithFormat:@"%@",userInfo.photoURL],
    // email用于获取用户邮箱地址
    @"email" : userInfo.email ?: [NSNull null],
    // phone用于获取用户手机号码
    @"phone" : userInfo.phone ?: [NSNull null],
  };
}

// 声明WilddogAuthPlugin类
@interface WilddogAuthPlugin ()
// 声明一个NSMutableDictionary（可变字典）类型的对像
// 原子性的控制使用nanatomic，不进行监控，线程不安全的
// 语义设置为retain，常用于对象类型（如自定义类）、数组NSArray
@property(nonatomic, retain) NSMutableDictionary *authStateChangeListeners;
// 声明一个FlutterMethodChannel类型的对像
@property(nonatomic, retain) FlutterMethodChannel *channel;
// 类的声明已结束
@end

// 实现WilddogAuthPlugin类
@implementation WilddogAuthPlugin

// 句柄是用作主动观察者的NSMutableDictionary的索引的int
int nextHandle = 0;

// 注册iOS方法通道
// registrar是客户端传递的通道注册信息
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  // 定义FlutterMethodChannel对像实例
  FlutterMethodChannel* channel = [FlutterMethodChannel
      methodChannelWithName:@"wilddog_auth"
            binaryMessenger:[registrar messenger]];
  // 初始化WilddogAuthPlugin对象实例
  // alloc方法会返回一个未被初始化的对象实例
  // init负责初始化对象，这意味着此时此对象处于可用状态，即对象的实例变量可以被赋予合理有效值
  WilddogAuthPlugin* instance = [[WilddogAuthPlugin alloc] init];
  // 设置WilddogAuthPlugin对象实例的通道为channel对象实例
  instance.channel = channel;
  // 初始化NSMutableDictionary对象实例
  instance.authStateChangeListeners = [[NSMutableDictionary alloc] init];
  // addMethodCallDelegate的值为WilddogAuthPlugin对像实例
  // channel表示通道，值为FlutterMethodChannel对像实例
  [registrar addMethodCallDelegate:instance channel:channel];
}

// 重写对象的init方法
- (instancetype)init {
  // 调用父类的初始化方法
  self = [super init];
  // 初始化是否成功
  if (self) {
    // defaultApp方法返回默认的WDGApp实例，即通过configureWithOptions:配置的实例
    // 如果默认app不存在，则返回nil，这个方法是线程安全的
    if (![WDGApp defaultApp]) {
      // 返回默认的WDGApp实例
      [WDGApp defaultApp];
    }
  }
  // 即self不为nil的情况下，就可以开始做子类的初始化
  return self;
}

// 接受客户端参数并调用方法
// call为客户端传递的调用参数，result为返回客户端的结果
- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
  // 当前用户
  if ([@"currentUser" isEqualToString:call.method]) {
    // addAuthStateDidChangeListener用于添加身份验证状态变更监听程序
    id __block listener = [[WDGAuth auth]
                           addAuthStateDidChangeListener:^(WDGAuth *_Nonnull auth, WDGUser *_Nullable user) {
      // 发送结果给Flutter客户端
      [self sendResult:result forUser:user error:nil];
      // removeAuthStateDidChangeListener用于移除身份验证状态变更监听程序
      [auth removeAuthStateDidChangeListener:listener];
    }];
  // 匿名登录
  } else if ([@"signInAnonymously" isEqualToString:call.method]) {
    // 调用signInAnonymouslyWithCompletion:方法完成匿名登录
    // signInAnonymouslyWithCompletion:方法调用成功后，可以在当前用户对象中获取用户数据
    [[WDGAuth auth] signInAnonymouslyWithCompletion:^(WDGUser *user, NSError *error) {
      // 发送结果给Flutter客户端
      [self sendResult:result forUser:user error:error];
    }];
  // 更新用户属性
  } else if ([@"updateProfile" isEqualToString:call.method]) {
    // 声明定义用户名变量，并获取调用参数中的用户名
    NSString *displayName = call.arguments[@"displayName"];
    // 声明定义用户头像变量，并获取调用参数中的用户头像
    NSString *photoURL = call.arguments[@"photoURL"];
    // profileChangeRequest创建一个可以改变用户信息的对象
    WDGUserProfileChangeRequest *changeRequest = [[WDGAuth auth].currentUser profileChangeRequest];
    // 更新用户名属性
    changeRequest.displayName = displayName;
    // 更新用户头像属性
    changeRequest.photoURL = [NSURL URLWithString:photoURL];
    // 修改完这个返回对象的属性，然后调用commitChangesWithCallback:来完成用户信息的修改
    [changeRequest commitChangesWithCompletion:^(NSError *_Nullable error) {
      // 发送结果给Flutter客户端
      [self sendResult:result forUser:nil error:error];
    }];
  // 更新用户邮箱或手机号认证密码
  } else if ([@"updatePassword" isEqualToString:call.method]) {
    // 声明定义密码变量，并获取调用参数中的密码
    NSString *password = call.arguments[@"password"];
    // updatePassword:completion:方法用于更新用户邮箱或手机号认证密码
    [[WDGAuth auth].currentUser updatePassword:password completion:^(NSError *_Nullable error) {
      // 发送结果给Flutter客户端
      [self sendResult:result forUser:nil error:error];
    }];
  // 使用电子邮件和密码创建用户
  } else if ([@"createUserWithEmailAndPassword" isEqualToString:call.method]) {
    // 声明定义邮箱变量，并获取调用参数中的邮箱
    NSString *email = call.arguments[@"email"];
    // 声明定义密码变量，并获取调用参数中的密码
    NSString *password = call.arguments[@"password"];
    // 使用createUserWithEmail:password:completion:方法创建新用户
    // 如果新用户创建成功，默认会处于登录状态，并且你可以在回调方法中获取登录用户
    [[WDGAuth auth] createUserWithEmail:email password:password
                             completion:^(WDGUser *user, NSError *error) {
      // 发送结果给Flutter客户端
      [self sendResult:result forUser:user error:error];
    }];
  // 用电子邮件和密码登录
  } else if ([@"signInWithEmailAndPassword" isEqualToString:call.method]) {
    // 声明定义邮箱变量，并获取调用参数中的邮箱
    NSString *email = call.arguments[@"email"];
    // 声明定义密码变量，并获取调用参数中的密码
    NSString *password = call.arguments[@"password"];
    // 将用户的邮件地址和密码传递到signInWithEmail:password:completion:方法
    // 即可在你的应用中登录此用户
    [[WDGAuth auth] signInWithEmail:email password:password
                         completion:^(WDGUser *user, NSError *error) {
      // 发送结果给Flutter客户端
      [self sendResult:result forUser:user error:error];
    }];
  // 发送电子邮箱验证邮件
  } else if ([@"sendEmailVerification" isEqualToString:call.method]) {
    // 发送邮箱验证
    [[WDGAuth auth].currentUser sendEmailVerificationWithCompletion:^(NSError *_Nullable error) {
      // 发送结果给Flutter客户端
      [self sendResult:result forUser:nil error:error];
    }];
  // 发送重置密码邮件
  } else if ([@"sendPasswordResetEmail" isEqualToString:call.method]) {
    // 声明定义邮箱变量，并获取调用参数中的邮箱
    NSString *email = call.arguments[@"email"];
    // sendPasswordResetWithEmail:completion:方法用于向用户发送重置密码邮件
    [[WDGAuth auth] sendPasswordResetWithEmail:email completion:^(NSError *_Nullable error) {
      // 发送结果给Flutter客户端
      [self sendResult:result forUser:nil error:error];
    }];
  // 更新帐号邮箱
  } else if ([@"updateEmail" isEqualToString:call.method]) {
    // 声明定义邮箱变量，并获取调用参数中的邮箱
    NSString *email = call.arguments[@"email"];
    // 更新帐号邮箱。如果更新成功，本地缓存也会刷新
    [[WDGAuth auth].currentUser updateEmail: email completion:^(NSError *_Nullable error) {
      // 发送结果给Flutter客户端
      [self sendResult:result forUser:nil error:error];
    }];
  // 登出
  } else if ([@"signOut" isEqualToString:call.method]) {
    // 声明注销错误变量
    NSError *signOutError;
    // signOut方法用于退出当前登录用户
    [[WDGAuth auth] signOut:&signOutError];
    // 发送结果给Flutter客户端
    [self sendResult:result forUser:nil error:signOutError];
  // 删除用户
  } else if ([@"delete" isEqualToString:call.method]) {
    // 删除这个帐号（如果是当前用户，则退出登录）
    [[WDGAuth auth].currentUser deleteWithCompletion:^(NSError *_Nullable error) {
      // 发送结果给Flutter客户端
      [self sendResult:result forUser:nil error:error];
    }];
  // 重新进行邮箱帐户认证
  } else if ([@"reauthenticateEmail" isEqualToString:call.method]) {
    // 声明定义邮箱变量，并获取调用参数中的邮箱
    NSString *email = call.arguments[@"email"];
    // 声明定义密码变量，并获取调用参数中的密码
    NSString *password = call.arguments[@"password"];
    // 使用credentialWithEmail:password:方法创建邮件和密码登录方式的WDGAuthCredential凭证
    // 使用credentialWithPhone:password:方法创建手机号和密码登录方式的WDGAuthCredential凭证
    // 返回WDGAuthCredential对象，里面包含email&password或phone&password登录方式凭证
    WDGAuthCredential *credential = [WDGWilddogAuthProvider credentialWithEmail:email password:password];
    // reauthenticateWithCredential:方法用于重新登录，刷新本地idToken
    [[WDGAuth auth].currentUser reauthenticateWithCredential:credential completion:^(NSError *_Nullable error) {
      // 发送结果给Flutter客户端
      [self sendResult:result forUser:nil error:error];
    }];
  // 使用手机号和密码创建用户
  } else if ([@"createUserWithPhoneAndPassword" isEqualToString:call.method]) {
    // 声明定义手机号变量，并获取调用参数中的手机号
    NSString *phone = call.arguments[@"phone"];
    // 声明定义密码变量，并获取调用参数中的密码
    NSString *password = call.arguments[@"password"];
    // 使用createUserWithPhone:password:completion:方法创建新用户
    // 用手机号的方式创建一个新用户，创建成功后会自动登录
    [[WDGAuth auth] createUserWithPhone:phone password:password
                            completion:^(WDGUser *_Nullable user, NSError *_Nullable error) {
      // 发送结果给Flutter客户端
      [self sendResult:result forUser:user error:error];
    }];
  // 用手机号和密码登录
  } else if ([@"signInWithPhoneAndPassword" isEqualToString:call.method]) {
    // 声明定义手机号变量，并获取调用参数中的手机号
    NSString *phone = call.arguments[@"phone"];
    // 声明定义密码变量，并获取调用参数中的密码
    NSString *password = call.arguments[@"password"];
    // 将手机号和密码传递到signInWithPhone:password:completion:即可登录此用户
    [[WDGAuth auth] signInWithPhone:phone password:password
                        completion:^(WDGUser *_Nullable user, NSError *_Nullable error) {
      // 发送结果给Flutter客户端
      [self sendResult:result forUser:user error:error];
    }];
  // 发送验证用户的手机验证码
  } else if ([@"sendPhoneVerification" isEqualToString:call.method]) {
    // 发送验证手机的验证码
    [[WDGAuth auth].currentUser sendPhoneVerificationWithCompletion:^(NSError *_Nullable error) {
      // 发送结果给Flutter客户端
      [self sendResult:result forUser:nil error:error];
    }];
  // 确认验证用户的手机验证码
  } else if ([@"verifyPhoneSmsCode" isEqualToString:call.method]) {
    // 声明定义验证码变量，并获取调用参数中的验证码
    NSString *realSms = call.arguments[@"realSms"];
    // 发送验证用户的手机验证码后，收到的验证码需要用此方法验证。
    [[WDGAuth auth].currentUser verifyPhoneWithSmsCode:realSms completion:^(NSError * _Nullable error) {
      // 发送结果给Flutter客户端
      [self sendResult:result forUser:nil error:error];
    }];
  // 发送重置密码的手机验证码
  } else if ([@"sendPasswordResetSms" isEqualToString:call.method]) {
    // 声明定义手机号变量，并获取调用参数中的手机号
    NSString *phone = call.arguments[@"phone"];
    // 发送重置密码的手机验证码
    [[WDGAuth auth] sendPasswordResetSmsWithPhone:phone completion:^(NSError * _Nullable error) {
      // 发送结果给Flutter客户端
      [self sendResult:result forUser:nil error:error];
    }];
  // 确认重置密码的手机验证码
  } else if ([@"confirmPasswordResetSms" isEqualToString:call.method]) {
    // 声明定义手机号变量，并获取调用参数中的手机号
    NSString *phone = call.arguments[@"phone"];
    // 声明定义验证码变量，并获取调用参数中的验证码
    NSString *realSms = call.arguments[@"realSms"];
    // 声明定义密码变量，并获取调用参数中的密码
    NSString *newPassword = call.arguments[@"newPassword"];
    // 发送重置密码的手机验证码后，收到的验证码需要用此方法验证。
    [[WDGAuth auth] confirmPasswordResetSmsWithPhone:phone smsCode:realSms newPassword:newPassword
                                            completion:^(NSError * _Nullable error) {
      // 发送结果给Flutter客户端
      [self sendResult:result forUser:nil error:error];
    }];
  // 更新帐号手机号码
  } else if ([@"updatePhone" isEqualToString:call.method]) {
    // 声明定义手机号码变量，并获取调用参数中的手机号码
    NSString *phone = call.arguments[@"phone"];
    // 更新帐号手机号码。如果更新成功，本地缓存也会刷新
    [[WDGAuth auth].currentUser updatePhone: phone completion:^(NSError *_Nullable error) {
      // 发送结果给Flutter客户端
      [self sendResult:result forUser:nil error:error];
    }];
  // 重新进行手机帐户认证
  } else if ([@"reauthenticatePhone" isEqualToString:call.method]) {
    // 声明定义手机号码变量，并获取调用参数中的手机号码
    NSString *phone = call.arguments[@"phone"];
    // 声明定义密码变量，并获取调用参数中的密码
    NSString *password = call.arguments[@"password"];
    // 使用credentialWithEmail:password:方法创建邮件和密码登录方式的WDGAuthCredential凭证
    // 使用credentialWithPhone:password:方法创建手机号和密码登录方式的WDGAuthCredential凭证
    // 返回WDGAuthCredential对象，里面包含email&password或phone&password登录方式凭证
    WDGAuthCredential *credential = [WDGWilddogAuthProvider credentialWithPhone:phone password:password];
    // reauthenticateWithCredential:方法用于重新登录，刷新本地idToken
    [[WDGAuth auth].currentUser reauthenticateWithCredential:credential completion:^(NSError *_Nullable error) {
      // 发送结果给Flutter客户端
      [self sendResult:result forUser:nil error:error];
    }];
  // 微博登录
  } else if ([@"WB" isEqualToString:call.method]) {
    //WBAuthorizeRequest *request = [WBAuthorizeRequest request];
    //request.redirectURI = @"https://api.weibo.com/oauth2/default.html";
  // 获取用户ID标识符
  } else if ([@"getIdToken" isEqualToString:call.method]) {
    // 获取用户token
    [[WDGAuth auth].currentUser getTokenWithCompletion: ^(NSString *_Nullable token,
                                                      NSError *_Nullable error) {
      // error变量是否不为空，是则返回error变量，否则返回token变量
      result(error != nil ? error.flutterError : token);
    }];
  // 绑定电子邮件和密码登录方式
  } else if ([@"linkWithEmailAndPassword" isEqualToString:call.method]) {
    // 声明定义邮箱变量，并获取调用参数中的邮箱
    NSString *email = call.arguments[@"email"];
    // 声明定义密码变量，并获取调用参数中的密码
    NSString *password = call.arguments[@"password"];
    // 使用credentialWithEmail方法创建邮件和密码登录方式的WDGAuthCredential凭证
    // 返回WDGAuthCredential对象，里面包含email&password登录方式凭证
    WDGAuthCredential *credential =
      [WDGWilddogAuthProvider credentialWithEmail:email password:password];
    // linkWithCredential:方法将第三方帐号绑定到当前用户，以实现通过不同方式登录
    [[WDGAuth auth].currentUser linkWithCredential:credential
                                        completion:^(WDGUser *user, NSError *error) {
      // 发送结果给Flutter客户端
      [self sendResult:result forUser:user error:error];
    }];
  // 开始监听认证状态
  } else if ([@"startListeningAuthState" isEqualToString:call.method]) {
    // 声明定义标识符变量
    // 使用numberWithInteger:方法创建一个整型数
    NSNumber *identifier = [NSNumber numberWithInteger:nextHandle++];
    // 声明定义WDGAuthStateDidChangeListenerHandle类型的WDG认证状态改变监听器句柄变量
    // 这个变量是返回block的唯一标示，用于移除这个block
    //
    // addAuthStateDidChangeListener:方法监听用户auth状态，发生以下条件时会被调用
    // 第一次调用时、当前用户切换时、或者当前用户的 idToken 变化时
    //
    // 这个方法被调用时就会触发block的回调，之后会一直处于监听状态
    // 并且block会被WDGAuth持有，直到移除这个监听，需要防止引用循环
    WDGAuthStateDidChangeListenerHandle listener = [[WDGAuth auth]
                addAuthStateDidChangeListener:^(WDGAuth *_Nonnull auth, WDGUser *_Nullable user) {
      // 声明一个NSMutableDictionary（可变字典）类型的对像
      // alloc方法会返回一个未被初始化的对象实例
      // init负责初始化对象，这意味着此时此对象处于可用状态，即对象的实例变量可以被赋予合理有效值
      NSMutableDictionary *response = [[NSMutableDictionary alloc] init];
      // 可变字典的id属性为标识符变量
      response[@"id"] = identifier;
      // user变量是否为真值
      if (user) {
        // 可变字典的user属性为user变量
        response[@"user"] = [self dictionaryFromUser:user];
      }
      // 用指定的参数调用指定的Flutter方法，期望获得异步结果
      [self.channel invokeMethod:@"onAuthStateChanged" arguments:response];
    }];
    // 在authStateChangeListeners变量中添加字典
    [self.authStateChangeListeners setObject:listener forKey:identifier];
    // 返回识别码变量
    result(identifier);
  // 停止监听认证状态
  } else if ([@"stopListeningAuthState" isEqualToString:call.method]) {
    // 声明定义标识符变量，并获取调用参数中的标识符
    NSNumber *identifier = [NSNumber numberWithInteger:[call.arguments[@"id"] unsignedIntegerValue]];
    // 声明定义WDGAuthStateDidChangeListenerHandle类型的WDG认证状态改变监听器句柄变量
    // 在authStateChangeListeners变量中获取指定标识符的listener
    WDGAuthStateDidChangeListenerHandle listener = self.authStateChangeListeners[identifier];
    // WDG认证状态改变监听器句柄变量是否为真值
    if (listener) {
      // removeAuthStateDidChangeListener:方法移除auth状态变更监听
      [[WDGAuth auth] removeAuthStateDidChangeListener:self.authStateChangeListeners];
      // 在authStateChangeListeners变量中移除字典
      [self.authStateChangeListeners removeObjectForKey:identifier];
      result(nil);
    } else {
      // 返回错误信息
      result([FlutterError errorWithCode:@"not_found"
                 message:[NSString stringWithFormat:@"找不到标识符为 '%d' 的监听器。",
                 identifier.intValue] details:nil]);
    }
  // 未实现的方法
  } else {
    // 返回未实现方法的提示
    result(FlutterMethodNotImplemented);
  }
}

// 返回包装了用户属性词典的自定义字典
- (NSMutableDictionary *)dictionaryFromUser:(WDGUser *)user {
    // 声明定义NSMutableArray（可变数组）类型的提供方数据变量
    // providerData用于获取Provider属性
    NSMutableArray<NSDictionary<NSString *, NSString *> *> *providerData =
    [NSMutableArray arrayWithCapacity:user.providerData.count];
    // 快速for循环
    for (id<WDGUserInfo> userInfo in user.providerData) {
      // 返回一个包含用户属性的词典，并添加到提供方数据变量（可变数组）中
      [providerData addObject:toDictionary(userInfo)];
    }
    // 声明定义NSMutableDictionary（可变字典）类型的用户数据变量
    // 使用mutableCopy（对象复制）了一个包含用户属性的词典
    NSMutableDictionary *userData = [toDictionary(user) mutableCopy];
    // 当前用户是否是匿名登录
    userData[@"isAnonymous"] = [NSNumber numberWithBool:user.isAnonymous];
    // 当前用户是否已验证电子邮件
    userData[@"isEmailVerified"] = [NSNumber numberWithBool:user.isEmailVerified];
    // 当前用户是否已验证手机号码
    userData[@"isPhoneVerified"] = [NSNumber numberWithBool:user.isPhoneVerified];
    // 当前用户的提供方数据
    userData[@"providerData"] = providerData;
    // 返回用户数据变量
    return userData;
}

// 发送结果给Flutter客户端
- (void)sendResult:(FlutterResult)result forUser:(WDGUser *)user error:(NSError *)error {
  // error变量是否不为空
  if (error != nil) {
    // 打印错误信息
    NSLog(@"%@",error);
    // 返回错误信息
    result([NSString stringWithFormat: @"%@",error]);
  // user变量是否为空
  } else if (user == nil) {
    // 返回空值
    result(nil);
  } else {
    // 返回包装了用户属性词典的自定义字典
    result([self dictionaryFromUser:user]);
  }
}

@end
