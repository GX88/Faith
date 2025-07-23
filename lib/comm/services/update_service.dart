import 'package:faith/utils/update_util.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class UpdateService extends GetxService {
  final Rx<RemoteVersion?> latest = Rx(null);

  @override
  Future<UpdateService> init() async {
    latest.value = await AppUpdateTool.checkUpdate();
    debugPrint('latest: ${latest.value}');
    return this;
  }
}
