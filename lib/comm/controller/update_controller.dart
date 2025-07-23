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

  /* ---------- 入口 ---------- */
  @override
  void onInit() {
    super.onInit();
    _listenProgress(); // 实时监听进度
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
      await AppUpdateTool.cleanAfterInstall(path);
      Get.back(result: true); // 关闭弹窗
    } catch (e) {
      errorMsg.value = e.toString();
    }
  }

  /* ---------- 按钮：取消 / 关闭 ---------- */
  @override
  void onClose() => Get.back();

  /* ---------- 进度流 ---------- */
  void _listenProgress() {
    ever(taskId, (id) {
      if (id.isEmpty) return;
      FlutterDownloader.registerCallback((tid, st, prg) {
        if (tid == id) {
          status.value = DownloadTaskStatus.fromInt(st);
          progress.value = prg;
        }
      });
    });
  }
}
