import 'package:faith/comm/ui/fa_bottom_sheet/index.dart';
import 'package:faith/comm/update/update_views.dart';
import 'package:faith/store/app_state.dart';
import 'package:faith/utils/update_utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// 全局更新管理器
/// 负责在home页面检查更新并显示更新弹窗
class UpdateManager {
  static bool _initialized = false;
  static bool _hasCheckedOnHomePage = false;

  /// 初始化更新管理器
  /// 只在应用启动时调用一次，但不立即检查更新
  static Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    // 只初始化，不立即检查更新
  }

  /// 在home页面检查更新
  /// 只在首次进入home页面时检查
  static void checkUpdateOnHomePage() {
    if (_hasCheckedOnHomePage) return;
    _hasCheckedOnHomePage = true;

    // 检查当前更新状态
    _checkCurrentUpdateStatus();

    // 设置监听器（只设置一次）
    _setupUpdateListener();
  }

  /// 设置更新状态监听器
  static void _setupUpdateListener() {
    // 监听更新状态变化
    ever(AppUpdateTool.to.hasUpdate, (bool hasUpdate) {
      if (hasUpdate && !AppStateStore.hasShownUpdateDialog()) {
        _showUpdateView();
      }
    });
  }

  /// 检查当前更新状态（处理网络快的情况）
  static void _checkCurrentUpdateStatus() {
    if (AppUpdateTool.to.hasUpdate.value &&
        !AppStateStore.hasShownUpdateDialog()) {
      _showUpdateView();
    }
  }

  /// 显示更新视图
  static void _showUpdateView() {
    final remote = AppUpdateTool.to.remoteVersion.value;
    if (remote == null) return;

    // 标记已经显示过更新弹窗
    AppStateStore.markUpdateDialogShown();

    // 确保在下一帧显示弹窗
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Get.context != null) {
        CustomBottomSheetHelper.showCustomBottomSheet(
          context: Get.context!,
          child: UpdateChecker(remote),
          barrierDismissible: false,
          animationDuration: const Duration(milliseconds: 400),
        );
      }
    });
  }

  /// 手动检查更新（强制显示更新弹窗，不受限制）
  static void manualCheckUpdate() {
    AppUpdateTool.to.checkUpdate().then((_) {
      final remote = AppUpdateTool.to.remoteVersion.value;
      if (remote != null && AppUpdateTool.to.hasUpdate.value) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (Get.context != null) {
            CustomBottomSheetHelper.showCustomBottomSheet(
              context: Get.context!,
              child: UpdateChecker(remote),
              barrierDismissible: false,
              animationDuration: const Duration(milliseconds: 400),
            );
          }
        });
      }
    });
  }

  /// 重置更新弹窗状态（用于开发测试）
  static void resetUpdateDialogState() {
    AppStateStore.resetUpdateDialogShown();
    _hasCheckedOnHomePage = false;
  }
}
