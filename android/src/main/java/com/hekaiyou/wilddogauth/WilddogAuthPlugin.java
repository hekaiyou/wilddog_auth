package com.hekaiyou.wilddogauth;

import android.app.Activity;
import android.util.SparseArray;
import com.google.common.collect.ImmutableList;
import com.google.common.collect.ImmutableMap;
import com.wilddog.wilddogauth.WilddogAuth;
import com.wilddog.wilddogauth.model.WilddogUser;
import com.wilddog.wilddogauth.model.UserInfo;
import com.wilddog.wilddogauth.core.Task;
import com.wilddog.wilddogauth.core.credentialandprovider.AuthCredential;
import com.wilddog.wilddogauth.core.credentialandprovider.WilddogAuthProvider;
import com.wilddog.wilddogauth.core.listener.OnCompleteListener;
import com.wilddog.wilddogauth.core.result.AuthResult;
import com.wilddog.wilddogauth.core.result.GetTokenResult;

import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.PluginRegistry.Registrar;
import java.util.Map;

/** Flutter的野狗云身份认证插件 */
public class WilddogAuthPlugin implements MethodCallHandler {
  // 声明私有、不可变的Activity类实例
  private final Activity activity;
  // 声明私有、不可变的wilddogAuth类实例
  private final WilddogAuth wilddogAuth;
  // 声明私有、不可变的AuthStateListener对象稀疏数组
  private final SparseArray<WilddogAuth.AuthStateListener> authStateListeners = new SparseArray<>();
  // 声明私有、不可变的方法通道
  private final MethodChannel channel;

  // 声明私有的句柄，被用作索引到Activity观察者的稀疏数组中
  private int nextHandle = 0;

  // 声明私有、静态、不可变的错误的意外原因
  private static final String ERROR_REASON_EXCEPTION = "exception";

  /**
   * 插件注册，即注册Android方法通道
   * @param registrar 客户端传递的通道注册信息
   */
  public static void registerWith(Registrar registrar) {
    // 声明定义不可变的方法通道实例
    final MethodChannel channel = new MethodChannel(registrar.messenger(), "wilddog_auth");
    // 设置方法通道实例的方法调用处理程序
    channel.setMethodCallHandler(new WilddogAuthPlugin(registrar.activity(), channel));
  }

  /**
   * 方法通道的方法调用处理程序
   * @param channel 局部的方法通道实例
   * @param activity Activity类实例
   */
  private WilddogAuthPlugin(Activity activity, MethodChannel channel) {
    // 将Activity类实例赋予全局Activity类实例
    this.activity = activity;
    // 将局部方法通道赋予全局方法通道
    this.channel = channel;
    // 返回初始化后，可以用getInstance()方法获取当前WilddogAuth实例对象
    this.wilddogAuth = WilddogAuth.getInstance();
  }

  /**
   * 接受客户端参数并调用方法
   * @param call 客户端传递的调用参数
   * @param result 返回客户端的结果
   */
  @Override
  public void onMethodCall(MethodCall call, Result result) {
    // 指定字符串是否与调用方法字符串一样
    switch (call.method) {
      // 当前用户
      case "currentUser":
        // 调用处理当前用户的方法
        handleCurrentUser(call, result);
        break;
      // 匿名登录
      case "signInAnonymously":
        // 调用处理匿名登录的方法
        handleSignInAnonymously(call, result);
        break;
      // 使用电子邮箱和密码创建用户
      case "createUserWithEmailAndPassword":
        // 调用处理使用电子邮箱和密码创建用户的方法
        handleCreateUserWithEmailAndPassword(call, result);
        break;
      // 使用电子邮箱和密码登录
      case "signInWithEmailAndPassword":
        // 调用处理使用电子邮箱和密码登录的方法
        handleSignInWithEmailAndPassword(call, result);
        break;
      // 登出
      case "signOut":
        // 调用处理登出的方法
        handleSignOut(call, result);
        break;
      // 获取用户ID标识符
      case "getIdToken":
        // 调用处理获取用户ID标识符的方法
        handleGetToken(call, result);
        break;
      // 绑定电子邮箱和密码
      case "linkWithEmailAndPassword":
        // 调用处理绑定电子邮箱和密码的方法
        handleLinkWithEmailAndPassword(call, result);
        break;
     // 开始监听认证状态
      case "startListeningAuthState":
        // 调用处理开始监听认证状态的方法
        handleStartListeningAuthState(call, result);
        break;
      // 停止监听认证状态
      case "stopListeningAuthState":
        // 调用处理停止监听认证状态的方法
        handleStopListeningAuthState(call, result);
        break;
      // 未实现的方法
      default:
        // 返回未实现方法的提示
        result.notImplemented();
        break;
    }
  }

  /**
   * 处理绑定电子邮箱和密码
   * @param call 客户端传递的调用参数
   * @param result 返回客户端的结果
   */
  private void handleLinkWithEmailAndPassword(MethodCall call, Result result) {
    // 声明定义参数变量，并获取客户端传递的调用参数
    @SuppressWarnings("unchecked")
    Map<String, String> arguments = (Map<String, String>) call.arguments;
    // 声明定义邮箱变量，并获取调用参数中的邮箱
    String email = arguments.get("email");
    // 声明定义密码变量，并获取调用参数中的密码
    String password = arguments.get("password");
    // getEmailCredential方法返回一个带有邮箱和密码的用户凭证
    // 当调用signInWithCredential(AuthCredential)或者linkWithCredential(AuthCredential)时候使用
    AuthCredential credential = WilddogAuthProvider.getEmailCredential(email, password);
    // linkWithCredential方法将当前用户与给定的登录认证方式绑定，之后支持绑定的所有登录认证方式
    wilddogAuth.getCurrentUser().linkWithCredential(credential)
            .addOnCompleteListener(activity, new SignInCompleteListener(result));
  }

  /**
   * 处理当前用户
   * @param call 客户端传递的调用参数
   * @param result 返回客户端的结果
   */
  private void handleCurrentUser(MethodCall call, final Result result) {
    // 当身份验证状态有一个变化的时候调用
    //
    // 使用addAuthStateListener(AuthStateListener)和
    // removeAuthStateListener(AuthStateListener)来注册或者注销监听
    final WilddogAuth.AuthStateListener listener = new WilddogAuth.AuthStateListener() {
      @Override
      public void onAuthStateChanged(WilddogAuth wilddogAuth) {
        // 使用removeAuthStateListener(listener)注销认证状态的监听
        wilddogAuth.removeAuthStateListener(this);
        // getCurrentUser()方法在如果有用户认证登录时返回登录用户
        // 如果没有登录，则返回为空值
        WilddogUser user = wilddogAuth.getCurrentUser();
        // 声明不可变集合实例，并获取ImmutableMap类型的用户词典
        ImmutableMap<String, Object> userMap = mapFromUser(user);
        // 返回结果给Flutter客户端
        result.success(userMap);
      }
    };

    // addAuthStateListener(listener)注册一个认证状态的监听
    // 一个WilddogAuth对象可以设置多个监听对象，也可以为不同的WilddogAuth添加监听对象
    wilddogAuth.addAuthStateListener(listener);
  }

  /**
   * 处理匿名登录
   * @param call 客户端传递的调用参数
   * @param result 返回客户端的结果
   */
  private void handleSignInAnonymously(MethodCall call, final Result result) {
    // signInAnonymously()使用匿名方法登录，不需要凭据，可以绑定其他认证方式
    // 这个操作将在Wilddog创建一个匿名的用户账号，其中通过getCurrentUser()获取用户信息包含uid
    wilddogAuth.signInAnonymously()
            .addOnCompleteListener(activity, new SignInCompleteListener(result));
  }

  /**
   * 处理使用电子邮箱和密码创建用户
   * @param call 客户端传递的调用参数
   * @param result 返回客户端的结果
   */
  private void handleCreateUserWithEmailAndPassword(MethodCall call, final Result result) {
    // 声明定义参数变量，并获取客户端传递的调用参数
    @SuppressWarnings("unchecked")
    Map<String, String> arguments = (Map<String, String>) call.arguments;
    // 声明定义邮箱变量，并获取调用参数中的邮箱
    String email = arguments.get("email");
    // 声明定义密码变量，并获取调用参数中的密码
    String password = arguments.get("password");

    // 用给定的邮箱和密码创建一个用户账号，如果成功，这个用户也将登录成功
    // 然后可以通过getCurrentUser()访问用户信息和进行用户操作
    wilddogAuth.createUserWithEmailAndPassword(email, password)
            .addOnCompleteListener(activity, new SignInCompleteListener(result));
  }

  /**
   * 处理使用电子邮箱和密码登录
   * @param call 客户端传递的调用参数
   * @param result 返回客户端的结果
   */
  private void handleSignInWithEmailAndPassword(MethodCall call, final Result result) {
    // 声明定义参数变量，并获取客户端传递的调用参数
    @SuppressWarnings("unchecked")
    Map<String, String> arguments = (Map<String, String>) call.arguments;
    // 声明定义邮箱变量，并获取调用参数中的邮箱
    String email = arguments.get("email");
    // 声明定义密码变量，并获取调用参数中的密码
    String password = arguments.get("password");

    // 通过邮箱和密码进行登录认证，可以通过getCurrentUser获取当前登录认证用户信息
    wilddogAuth.signInWithEmailAndPassword(email, password)
            .addOnCompleteListener(activity, new SignInCompleteListener(result));
  }

  /**
   * 处理登出
   * @param call 客户端传递的调用参数
   * @param result 返回客户端的结果
   */
  private void handleSignOut(MethodCall call, final Result result) {
    // 登出当前用户，清除登录数据
    wilddogAuth.signOut();
    // 返回结果给Flutter客户端
    result.success(null);
  }

  /**
   * 处理获取用户ID标识符
   * @param call 客户端传递的调用参数
   * @param result 返回客户端的结果
   */
  private void handleGetToken(MethodCall call, final Result result) {
    // 声明定义参数变量，并获取客户端传递的调用参数
    @SuppressWarnings("unchecked")
    Map<String, Boolean> arguments = (Map<String, Boolean>) call.arguments;
    // 声明定义刷新变量，并获取调用参数中的刷新
    boolean refresh = arguments.get("refresh");
    // getCurrentUser()在如果有用户认证登录返回登录用户，如果没有登录，则返回为空
    // 可以通过getCurrentUser() != null 来判断当前是否有用户登录
    //
    // getToken()在身份认证成功后返回的Wilddog Id token字符串，
    // 用于验证之后操作的身份完整性和安全性
    wilddogAuth.getCurrentUser().getToken(refresh).addOnCompleteListener(
      // 完整的监听器
      new OnCompleteListener<GetTokenResult>() {
        // 完成监听方法
        public void onComplete(Task<GetTokenResult> task) {
          // 操作结果是否不为成功的
          if (task.isSuccessful()) {
            // 声明定义Wilddog Id令牌变量
            String idToken = task.getResult().getToken();
            // 返回Wilddog Id令牌给Flutter客户端
            result.success(idToken);
          } else {
            // 返回错误信息给客户端
            result.error(ERROR_REASON_EXCEPTION, task.getException().getMessage(), null);
          }
        }
      }
    );
  }

  /**
   * 处理开始监听认证状态
   * @param call 客户端传递的调用参数
   * @param result 返回客户端的结果
   */
  private void handleStartListeningAuthState(MethodCall call, final Result result) {
    // 声明定义句柄变量，并调用全局句柄自增
    final int handle = nextHandle++;
    // WilddogAuth.AuthStateListener会在身份验证状态有一个变化的时候调用
    WilddogAuth.AuthStateListener listener = new WilddogAuth.AuthStateListener() {
      // onAuthStateChanged会在状态发生变化的时候，这个方法在UI线程中调用：
      // 注册监听时、用户登录时、用户登出时、当前用户改变时、当前用户的token改变时
      @Override
      public void onAuthStateChanged(WilddogAuth firebaseAuth) {
        // getCurrentUser方法在有用户认证登录返回登录用户，如果没有登录，则返回为空
        WilddogUser user = firebaseAuth.getCurrentUser();
        // 获取ImmutableMap类型的用户词典
        ImmutableMap<String, Object> userMap = mapFromUser(user);
        // 获取ImmutableMap类型的自定义用户词典，包含句柄变量
        ImmutableMap.Builder<String, Object> builder =
                ImmutableMap.<String, Object>builder().put("id", handle);
        // 用户词典是否不等于空值
        if (userMap != null) {
          // 在自定义用户词典中添加用户词典
          builder.put("user", userMap);
        }
        // 用指定的参数调用指定的Flutter方法，期望获得异步结果
        channel.invokeMethod("onAuthStateChanged", builder.build());
      }
    };
    // 在返回初始化之后，可以用getInstance方法获取当前WilddogAuth实例对象
    //
    // addAuthStateListener方法注册一个认证状态的监听
    // 一个WilddogAuth对象可以设置多个监听对象，也可以为不同的WilddogAuth添加监听对象
    WilddogAuth.getInstance().addAuthStateListener(listener);
    // 在AuthStateListener对象稀疏数组中添加句柄对应监听器
    authStateListeners.append(handle, listener);
    // 返回句柄变量
    result.success(handle);
  }

  /**
   * 处理停止监听认证状态
   * @param call 客户端传递的调用参数
   * @param result 返回客户端的结果
   */
  private void handleStopListeningAuthState(MethodCall call, final Result result) {
    // 声明定义参数变量，并获取客户端传递的调用参数
    Map<String, Integer> arguments = call.arguments();
    // 声明定义句柄变量，并获取调用参数中的句柄
    Integer id = arguments.get("id");
    // 获取AuthStateListener对象稀疏数组的指定句柄对应监听器
    WilddogAuth.AuthStateListener listener = authStateListeners.get(id);
    // 监听器是否不等于空值
    if (listener != null) {
      // removeAuthStateListener方法注销认证状态的监听
      WilddogAuth.getInstance().removeAuthStateListener(listener);
      // 在AuthStateListener对象稀疏数组中移除句柄对应监听器
      authStateListeners.removeAt(id);
      // 返回结果给Flutter客户端
      result.success(null);
    } else {
      // 返回错误信息
      result.error(ERROR_REASON_EXCEPTION,
              String.format("Listener with identifier '%d' not found.", id),
              null);
    }
  }

  /**
   * 完整的登录监听器
   */
  private class SignInCompleteListener implements OnCompleteListener<AuthResult> {
    // 声明私有、不可变的方法调用结果回调
    private final Result result;

    /**
     * 默认的构造方法
     * @param result 方法调用结果回调
     */
    SignInCompleteListener(Result result) {
      // 将方法调用结果回调赋予局部方法调用结果回调
      this.result = result;
    }

    /**
     * 覆盖完成监听方法
     * @param task 包含操作结果的任务对象
     */
    @Override
    public void onComplete(Task<AuthResult> task) {
      // 操作结果是否不为成功的
      if (!task.isSuccessful()) {
        // 得到意外信息
        Exception e = task.getException();
        // 返回错误信息给客户端
        result.error(ERROR_REASON_EXCEPTION, e.getMessage(), null);
      } else {
        // 得到Wilddog用户实例
        WilddogUser user = task.getResult().getWilddogUser();
        // 声明不可变集合实例，并获取ImmutableMap类型的用户词典
        ImmutableMap<String, Object> userMap = mapFromUser(user);
        // 返回结果给Flutter客户端
        result.success(userMap);
      }
    }
  }

  /**
   * 生成不可变集合的构造器实例
   * @param userInfo UserInfo实例，获取一个用户的标准用户配置信息
   * @return ImmutableMap类型的构造器实例
   */
  private ImmutableMap.Builder<String, Object> userInfoToMap(UserInfo userInfo) {
    // 声明定义ImmutableMap类型的构造器实例
    // 不可变集合，顾名思义就是说集合是不可被修改的
    // 集合的数据项是在创建的时候提供，并且在整个生命周期中都不可改变
    ImmutableMap.Builder<String, Object> builder = ImmutableMap.<String, Object>builder()
            .put("providerId", userInfo.getProviderId())
            .put("uid", userInfo.getUid());
    // 用户昵称是否不为空值
    if (userInfo.getDisplayName() != null) {
      // 如果UserInfo实例可用，返回用户昵称
      builder.put("displayName", userInfo.getDisplayName());
    }
    // 用户用户形象照片是否不为空值
    if (userInfo.getPhotoUrl() != null) {
      // 如果UserInfo实例可用，返回用户形象照片
      builder.put("photoUrl", userInfo.getPhotoUrl().toString());
    }
    // 用户帐户的电子邮件地址是否不为空值
    if (userInfo.getEmail() != null) {
      // 如果UserInfo实例可用，返回对应于指定提供者的用户帐户的电子邮件地址，包含可选
      builder.put("email", userInfo.getEmail());
    }
    // 返回ImmutableMap类型的构造器实例
    return builder;
  }

  /**
   * 获取ImmutableMap类型的用户词典
   * @param user WilddogUser实例对象
   * @return ImmutableMap类型的用户词典
   */
  private ImmutableMap<String, Object> mapFromUser(WilddogUser user) {
    // WilddogUser实例是否不为空值
    if (user != null) {
      // 声明定义ImmutableList类型的提供方数据变量
      // ImmutableMap可以让java代码创建一个对象常量映射，来保存一些常量映射的键值对
      ImmutableList.Builder<ImmutableMap<String, Object>> providerDataBuilder =
              ImmutableList.<ImmutableMap<String, Object>>builder();
      // 增强型循环，即遍历数组中的元素
      // getProviderData()方法获取在WilddogAuth中用户绑定的所有认证类型的用户信息列表
      for (UserInfo userInfo : user.getProviderData()) {
        // 在提供方数据中添加一个包含用户配置信息的不可变集合
        providerDataBuilder.add(userInfoToMap(userInfo).build());
      }
      // 声明定义ImmutableMap类型的用户词典
      // 当前用户是否是匿名登录
      // 当前用户是否已验证电子邮件
      // 当前用户的提供方数据
      ImmutableMap<String, Object> userMap = userInfoToMap(user)
              .put("isAnonymous", user.isAnonymous())
              .put("isEmailVerified", user.isEmailVerified())
              .put("providerData", providerDataBuilder.build())
              .build();
      // 返回ImmutableMap类型的用户词典
      return userMap;
    } else {
      // 返回空值
      return null;
    }
  }
}
