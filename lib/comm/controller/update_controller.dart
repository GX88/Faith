import 'dart:isolate';
import 'dart:ui';

import 'package:faith/utils/update_util.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:get/get.dart';

class UpdateController extends GetxController {
  final RemoteVersion remote;
  UpdateController(this.remote);

  final taskId = ''.obs;
  final progress = 0.obs;
  final status = DownloadTaskStatus.undefined.obs;
  final errorMsg = ''.obs;

  static const _portName = 'downloader_send_port';
  static ReceivePort? _port;

  @override
  void onInit() {
    super.onInit();
    _bindPort();
    FlutterDownloader.registerCallback(downloadCallback);
  }

  @override
  void onClose() {
    IsolateNameServer.removePortNameMapping(_portName);
    _port?.close();
    super.onClose();
  }

  void _bindPort() {
    if (IsolateNameServer.lookupPortByName(_portName) != null) return;
    _port = ReceivePort();
    IsolateNameServer.registerPortWithName(_port!.sendPort, _portName);
    _port!.listen((dynamic data) async {
      String id = data[0];
      int st = data[1];
      int prg = data[2];
      if (id == taskId.value) {
        status.value = DownloadTaskStatus.fromInt(st);
        progress.value = prg;
        // 下载完成后自动进入验证流程
        if (status.value == DownloadTaskStatus.complete) {
          await _verifyAfterDownload();
        }
      }
    });
  }

  /// 下载完成后自动校验 SHA
  Future<void> _verifyAfterDownload() async {
    final path = await AppUpdateTool.filePathOf(taskId.value);
    if (path == null) {
      errorMsg.value = '找不到文件';
      return;
    }
    final ok = await AppUpdateTool.verifyAndCleanIfInvalid(path, remote.shaUrl);
    if (!ok) {
      errorMsg.value = '文件校验失败，已删除';
      // 可选：自动重试或提示用户重新下载
    } else {
      errorMsg.value = '文件校验通过，可安装';
      // 这里可以自动弹出安装提示，或让用户手动点击“立即安装”
    }
  }

  /* ---------- 按钮：立即更新 ---------- */
  Future<void> onUpdate() async {
    final id = await AppUpdateTool.download(remote);
    if (id != null) {
      taskId.value = id;
      errorMsg.value = '';
    }
  }

  /* ---------- 按钮：立即安装 ---------- */
  Future<void> onInstall() async {
    try {
      final path = await AppUpdateTool.filePathOf(taskId.value);
      if (path == null) {
        errorMsg.value = '找不到文件';
        return;
      }
      final ok = await AppUpdateTool.verifyAndCleanIfInvalid(
        path,
        remote.shaUrl,
      );
      if (!ok) {
        errorMsg.value = '文件校验失败，已删除';
        return;
      }
      await AppUpdateTool.install(path);
      // TODO: 安装后暂不自动删除APK，后续可在合适时机清理
      Get.back(result: true); // 关闭弹窗
    } catch (e) {
      errorMsg.value = e.toString();
    }
  }

  /* ---------- 按钮：取消 / 关闭 ---------- */
  void onCloseBtn() => Get.back();
}

@pragma('vm:entry-point')
void downloadCallback(String id, int status, int progress) {
  final SendPort? send = IsolateNameServer.lookupPortByName(
    UpdateController._portName,
  );
  send?.send([id, status, progress]);
}
