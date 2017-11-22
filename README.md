# Flutter插件一野狗云身份认证

[![pub package](https://img.shields.io/pub/v/wilddog_auth.svg)](https://pub.dartlang.org/packages/wilddog_auth)

使用[野狗身份认证（Wilddog Auth）](https://docs.wilddog.com/auth/Web/index.html)的Flutter插件。野狗云身份认证即Auth，用于帮助企业和开发者将野狗快速接入应用的身份认证系统，一次身份认证打通野狗所有产品。还可以用于增强已有帐户体系和简化新应用中账号系统的开发。

开发者使用Auth能让新应用避开从0开始的帐户系统开发，轻松搞定用户注册登录、用户信息存储。同时野狗采用行业标准的JWT格式对传输数据进行加密，有效提高帐号系统的安全性，防止用户信息泄漏。

*注意*：此插件还不是很完善，有些功能仍在开发中，如果你发现任何问题，请加入QQ群：271733776【Flutter程序员】，期待你的反馈。

## 安装与配置

打开[野狗云官网](https://www.wilddog.com/)，注册一个野狗云帐号，已有账号的直接登陆。

### 创建一个新Wilddog项目

在Flutter项目上配置Wilddog Sync的第一步是创建一个新的Wilddog项目，在浏览器中打开[Wilddog控制台](https://www.wilddog.com/dashboard)，选择“创建应用”，输入项目名称，然后单击“创建”。

![这里写图片描述](http://img.blog.csdn.net/20171116225958005?watermark/2/text/aHR0cDovL2Jsb2cuY3Nkbi5uZXQvaGVrYWl5b3U=/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70/gravity/SouthEast)

Wilddog生成了一个App ID的字符串，这是Wilddog项目唯一ID，用于连接到刚创建的Wilddog服务。复制这个ID字符串值，下面在Android、iOS平台上配置Wilddog时需要用到这个值。

注意，新项目需要*开启身份认证服务*才能正常使用，不然会报无权限异常。

### 将插件添加到应用程序

将以下内容添加到的Flutter项目的`pubspec.yaml`文件中。

```
dependencies:
  wilddog_auth: "^0.0.3"
```

更新并保存此文件后，点击顶部的“Packages Get”，等待下载完成。打开`main.dart`文件，IntelliJ IDEA或其他编辑器可能会在上方显示一个提示，提醒我们重新加载`pubspec.yaml`文件，点击“Get dependencies”以检索其他软件包，并在Flutter项目中使用它们。

开发iOS必须使用macOS，而在macOS中，想要在Flutter应用程序中使用Flutter插件，需要安装[homebrew](https://brew.sh/index_zh-cn.html)，并打开终端运行以下命令来安装CocoaPods。

```
brew install cocoapods
pod setup
```

### 为Android配置Wilddog

启动Android Studio后选择项目的`android`文件夹，打开Flutter项目的Android部分，然后再打开“android/app/src/main/java/<项目名>”文件夹中的`MainActivity.java`文件，将Wilddog的初始化代码添加到文件中。

```
//...
import com.wilddog.wilddogcore.WilddogOptions;
import com.wilddog.wilddogcore.WilddogApp;

public class MainActivity extends FlutterActivity {
  @Override
  protected void onCreate(Bundle savedInstanceState) {
    //...
    super.onCreate(savedInstanceState);
    WilddogOptions options = new WilddogOptions.Builder().setSyncUrl("https://<前面复制的AppID>.wilddogio.com/").build();
    WilddogApp.initializeApp(this, options);
    GeneratedPluginRegistrant.registerWith(this);
  }
}
```

注意，如果应用程序编译时出现文件重复导致的编译错误时，可以选择在`android/app/build.gradle`中添加“packagingOptions”。

```
android {
    ...
    packagingOptions {
        exclude 'META-INF/LICENSE'
        exclude 'META-INF/NOTICE'
    }
}
```

如果出现tools:replace="android:label"的异常，在`AndroidManifest.xml`中添加下面的两行代码即可解决。

```
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    +[xmlns:tools="http://schemas.android.com/tools"]
    package="com.hekaiyou.wilddogauthexample">
    
    <uses-permission android:name="android.permission.INTERNET"/>
    
    <application
        +[tools:replace="android:label"]
        android:name="io.flutter.app.FlutterApplication"
```

完成配置后，建议先在IntelliJ IDEA中执行一次项目，编译Android应用程序，以确保Flutter项目下载所有依赖文件。

### 为iOS配置Wilddog

在Flutter项目的`ios`目录下，使用Xcode打开“Runner.xcworkspace”文件。然后打开“ios/Runner”文件夹中的`AppDelegate.m`文件，将Wilddog的初始化代码添加到文件中。

```
//...
#import "Wilddog.h"
//...
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  //...
  WDGOptions *option = [[WDGOptions alloc] initWithSyncURL:@"https://<前面复制的AppID>.wilddogio.com/"];
  [WDGApp configureWithOptions:option];
  //...
}
```

完成配置后，建议先在IntelliJ IDEA中执行一次项目，编译iOS应用程序，以确保Flutter项目下载所有依赖文件。

## 使用与入门

要使用Flutter的平台插件，必须在Dart代码中导入对应包，使用以下代码导入`wilddog_auth`包。

```
import 'package:wilddog_auth/wilddog_auth.dart';
```

同时，要为应用程序提供默认的WilddogAuth类实例。

```
final WilddogAuth _auth = WilddogAuth.instance;
```

### 用户管理

用户生命周期包含以下三种状态：用户注册或登录成功、当前的Wilddog ID Token已刷新（重新进行身份认证）、退出登录。

#### 获取当前登录用户

Wilddog Auth中用户有一组基本属性：WilddogID、邮箱地址、名称、照片地址，获取当前登录用户是管理用户的基础。

```
final WilddogUser user = await _auth.currentUser();
```

#### 获取用户属性

通过返回的`WilddogUser`实例可以用于获取用户以下属性：

 - providerId：身份认证提供方ID（QQ、微信）
 -  uid：Wilddog ID（用户唯一的标识）
 - displayName：用户名称
 - photoUrl：用户头像Url
 - email：电子邮箱地址
 - phone：手机号码
 - isAnonymous：是否匿名用户
 - isEmailVerified：电子邮箱是否已验证
 - isPhoneVerified：手机号码是否已验证

#### 更新用户属性

更新当前用户的昵称信息和头像URL。

```
await _auth.updateProfile(
  displayName: 'hekaiyou',
  photoURL: 'https://example.com/hekaiyou/profile.jpg'
);
```

#### 更新用户认证密码

如果当前用户使用邮箱或手机号认证登录，可以更新用户的密码信息。需要注意的是，要更新密码，该用户必须最近登录过（重新进行身份认证）。

```
await _auth.updatePassword('654321');
```

#### 退出登录

登出当前用户，清除登录数据。

```
await _auth.signOut();
```

#### 删除用户

从Wilddog Auth系统中删除当前用户，也可以在控制面板"身份认证—用户"中手动删除。

```
await _auth.delete();
```

### 匿名登录

实现匿名身份认证需要在控制面板“身份认证—登录方式”中打开匿名登录方式。

#### 匿名身份认证

匿名登录的帐号数据将不会被保存，可以通过绑定邮箱认证或第三方认证方式将匿名帐号转成永久帐号。

```
final WilddogUser user = await _auth.signInAnonymously();
```

#### 绑定邮箱认证方式

可以将当前用户与给定的邮箱认证方式绑定，之后支持绑定的邮箱认证方式登录。（必须是未被使用的邮箱）

```
final WilddogUser user = await _auth.linkWithEmailAndPassword(
  email: 'hky2014@yeah.net',
  password: '123456',
);
```

### 邮箱登录

实现邮箱登录需要在控制面板“身份认证—登录方式”中打开邮箱登录方式。

#### 创建用户

用邮箱地址和密码创建一个新用户，新用户创建成功后会自动登录。

```
final WilddogUser user = await _auth.createUserWithEmailAndPassword(
  email: 'hky2014@yeah.net',
  password: '123456',
);
```

#### 登录用户

使用电子邮箱和密码登录。

```
final WilddogUser user = await _auth.signInWithEmailAndPassword(
  email: 'hky2014@yeah.net',
  password: '123456',
);
```

#### 更新邮箱地址

更新帐号邮箱，如果更新成功，本地缓存也会刷新。如果这个邮箱已经创建过用户，则会更新失败。需要注意的是，要更新用户的邮箱地址，该用户必须最近登录过（重新进行身份认证）。

更新邮箱地址会向旧邮箱发送提醒邮件，在控制面板“身份认证—登录方式—邮箱登录—配置”中定制更新邮箱邮件模版。

```
await _auth.updateEmail('hky2014@yeah.net');
```

#### 发送邮箱验证邮件

在控制面板“身份认证—登录方式—邮箱登录—配置”中定制邮箱验证邮件模版。

```
await _auth.sendEmailVerification();
```

#### 发送重置密码邮件

在控制面板“身份认证—登录方式—邮箱登录—配置”中定制重置密码邮件模版。

```
await _auth.sendPasswordResetEmail('hky2014@yeah.net');
```

#### 重新认证邮箱帐户

用户长时间未登录的情况下进行下列安全敏感操作会失败：删除帐户、设置主邮箱地址、更改密码，此时需要重新对用户进行身份认证。

```
await _auth.reauthenticateEmail(
  email: 'hky2014@yeah.net',
  password: '123456',
);
```

### 手机登录

现邮箱登录需要在控制面板“身份认证—登录方式”中打开手机号登录方式。

#### 创建用户

用手机号和密码创建一个新用户，新用户创建成功后会自动登录。

```
final WilddogUser user = await _auth.createUserWithPhoneAndPassword(
  phone: '13800000000',
  password: '123456',
);
```

#### 登录用户

使用手机号和密码登录。

```
final WilddogUser user = await _auth.signInWithPhoneAndPassword(
  phone: '13800000000',
  password: '123456',
);
```

#### 发送验证号码短信

发送验证手机的验证码，在控制面板“身份认证—登录方式—手机登录—配置”中定制验证号码短信模版。

```
await _auth.sendPhoneVerification();
```

#### 确认手机验证码

发送验证用户的手机验证码后，通过此方法确认手机验证码是否正确。

```
await _auth.verifyPhoneSmsCode('208345');
```

#### 发送重置密码短信

发送重置密码的手机验证码，在控制面板“身份认证—登录方式—手机登录—配置”中定制重置密码短信模版。

```
await _auth.sendPhoneVerification();
```

#### 确认重置验证码

发送重置密码的手机验证码后，通过此方法确认重置验证码是否正确。通过手机号码，验证码来修改密码。之后可以使用新密码进行手机号认证方式登录。

```
await _auth.confirmPasswordResetSms(
  phone: '13800000000',
  realSms: '685773',
  newPassword: '654321',
);
```

#### 更新手机号码

更换用户手机号，如果成功，本地缓存也会被刷新。需要注意的是，要更新用户的邮箱地址，该用户必须最近登录过（重新进行身份认证）。

```
await _auth.updatePhone('13800000000');
```

#### 重新认证手机帐户

用户长时间未登录的情况下进行下列安全敏感操作会失败：删除帐户、设置主邮箱地址、更改密码，此时需要重新对用户进行身份认证。

```
await _auth.reauthenticatePhone(
  phone: '13800000000',
  password: '123456',
);
```
