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
    // providerID用于获取身份认证提供方的ID
    //
    // Provider是身份认证提供方，WilddogAuth目前支持以下Provider
    // 电子邮件地址与密码、QQ、微信、微信公众号、微博
    @"providerId" : userInfo.providerID,
    // displayName用于获取用户的名称
    @"displayName" : userInfo.displayName ?: [NSNull null],
    // uid用于获取用户的UID
    @"uid" : userInfo.uid,
    // photoURL用于获取用户的照片网址
    @"photoUrl" : userInfo.photoURL.absoluteString ?: [NSNull null],
    // email用于获取用户的电子邮箱
    @"email" : userInfo.email ?: [NSNull null],
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
  // 登出
  } else if ([@"signOut" isEqualToString:call.method]) {
    // 声明注销错误变量
    NSError *signOutError;
    // signOut方法用于退出当前登录用户
    BOOL status = [[WDGAuth auth] signOut:&signOutError];
    // 登出操作是否失败
    if (!status) {
      // 打印错误信息
      NSLog(@"登出时出错: %@", signOutError);
      // 发送结果给Flutter客户端
      [self sendResult:result forUser:nil error:signOutError];
    } else {
      // 发送结果给Flutter客户端
      [self sendResult:result forUser:nil error:nil];
    }
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
    // 当前用户的提供方数据
    userData[@"providerData"] = providerData;
    // 返回用户数据变量
    return userData;
}

// 发送结果给Flutter客户端
- (void)sendResult:(FlutterResult)result forUser:(WDGUser *)user error:(NSError *)error {
  // error变量是否不为空
  if (error != nil) {
    // 返回错误信息
    result(error.flutterError);
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
