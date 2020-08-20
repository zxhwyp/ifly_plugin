import 'dart:async';

import 'package:flutter/services.dart';

class Iflyplugin {
  static const MethodChannel _channel =
      const MethodChannel('iflyplugin');

  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }
}
