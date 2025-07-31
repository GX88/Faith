import 'package:permission_handler/permission_handler.dart';

/// 权限管理助手
class PermissionHelper {
  /* ---------- 存储相关 ---------- */
  /// 请求「读写存储」权限（Android 6-13）
  static Future<PermissionStatus> requestStorage() async =>
      await Permission.storage.request();

  /// 检查「读写存储」是否已授予
  static bool isStorageGranted(PermissionStatus status) => status.isGranted;

  /* ---------- 安装相关 ---------- */
  /// 请求「安装未知来源应用」权限（Android 8-13）
  static Future<PermissionStatus> requestInstallPackages() async =>
      await Permission.requestInstallPackages.request();

  /// 检查「安装未知来源应用」是否已授予
  static bool isInstallGranted(PermissionStatus status) => status.isGranted;

  /* ---------- 一次性全部扩展权限：应用更新 ---------- */
  /// 同时请求存储 + 安装（更新场景专用）
  static Future<bool> requestAllForUpdate() async {
    final storage = await requestStorage();
    final install = await requestInstallPackages();
    return storage.isGranted && install.isGranted;
  }
}
