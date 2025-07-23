// lib/controllers/home_controller.dart
import 'package:faith/comm/services/update_service.dart';
import 'package:faith/comm/views/update_checker.dart';
import 'package:faith/utils/update_util.dart';
import 'package:get/get.dart';

class HomeController extends GetxController {
  /// 标记“已弹过”
  final RxBool _alreadyShown = false.obs;

  @override
  void onReady() {
    super.onReady();
    _maybeShowUpdate();
  }

  /* ---------- 核心逻辑：首次进入主页才弹 ---------- */
  Future<void> _maybeShowUpdate() async {
    if (_alreadyShown.value) return;

    final remote = Get.find<UpdateService>().latest.value;
    if (remote == null) return;

    if (AppUpdateTool.isNewer(remote.tag)) {
      _alreadyShown.value = true;
      Get.bottomSheet(UpdateChecker(remote), isScrollControlled: true);
    }
  }

  /* ---------- 公开方法：手动触发（调试/按钮） ---------- */
  Future<void> forceCheckUpdate() async {
    final remote = await AppUpdateTool.checkUpdate();
    if (remote != null && AppUpdateTool.isNewer(remote.tag)) {
      Get.bottomSheet(UpdateChecker(remote), isScrollControlled: true);
    } else {
      Get.snackbar('已是最新', '当前已是最新版本');
    }
  }
}
