import 'package:faith/utils/update_manager.dart';
import 'package:get/get.dart';

class HomeController extends GetxController {
  @override
  void onInit() {
    super.onInit();
    // 只在首次进入home页面时检查更新
    UpdateManager.checkUpdateOnHomePage();
  }

  /// 手动检查更新（强制显示更新弹窗，不受限制）
  void manualCheckUpdate() {
    UpdateManager.manualCheckUpdate();
  }

  /// 重置更新弹窗状态（用于开发测试）
  void resetUpdateDialogState() {
    UpdateManager.resetUpdateDialogState();
  }
}
