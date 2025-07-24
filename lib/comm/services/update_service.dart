import 'package:faith/utils/update_util.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class UpdateService extends GetxService {
  final Rx<RemoteVersion?> latest = Rx(null);

  @override
  Future<UpdateService> init() async {
    latest.value = await AppUpdateTool.checkUpdate();
    debugPrint('UpdateService 拉取线上版本结果: \n');
    debugPrint(latest.value?.toString() ?? 'null');
    return this;
  }
}
