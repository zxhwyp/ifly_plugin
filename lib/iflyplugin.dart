import 'dart:async';

import 'package:flutter/services.dart';

class Iflyplugin {
  static const MethodChannel channel = const MethodChannel('iflyplugin');

  static Future<void> recognizer(String file) async {
    return await channel.invokeMethod('recognizer', file);
  }

  static Future<void> result(
      Future<dynamic> Function(MethodCall) handler) async {
    return channel.setMethodCallHandler(handler);
  }
}
