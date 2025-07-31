import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class LogUtil {
  static Future<void> uploadLog({
    required String tag,
    required String message,
    Map<String, dynamic>? extra,
  }) async {
    final url = 'http://192.168.3.136:3000/data';
    final data = {
      'tag': tag,
      'message': message,
      'extra': extra,
      'time': DateTime.now().toIso8601String(),
    };
    try {
      await Dio().post(
        url,
        data: jsonEncode(data),
        options: Options(headers: {'Content-Type': 'application/json'}),
      );
    } catch (e) {
      debugPrint('日志上传失败: $e');
    }
  }
}
