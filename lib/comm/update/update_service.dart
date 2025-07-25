import 'package:faith/utils/update_util.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class UpdateService extends GetxService {
  final Rx<RemoteVersion?> latest = Rx(null);

  // 增加：防止多次初始化
  Future<UpdateService>? _initFuture;

  /// 自定义异步初始化方法，防止多次初始化
  Future<UpdateService> init() {
    // 如果已经在初始化或已初始化，直接返回同一个 Future
    if (_initFuture != null) return _initFuture!;
    _initFuture = _doInit();
    return _initFuture!;
  }

  // 真正的初始化逻辑
  Future<UpdateService> _doInit() async {
    latest.value = await AppUpdateTool.checkUpdate();
    debugPrint('UpdateService 拉取线上版本结果: \n');
    debugPrint(latest.value?.toString() ?? 'null');
    return this;
  }
}
