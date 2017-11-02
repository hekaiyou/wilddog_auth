import 'dart:async';

import 'package:flutter/services.dart';

class WilddogAuth {
  static const MethodChannel _channel =
      const MethodChannel('wilddog_auth');

  static Future<String> get platformVersion =>
      _channel.invokeMethod('getPlatformVersion');
}
