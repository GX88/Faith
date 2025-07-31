// 使用hive存储应用状态信息
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// 用于持久化存储应用状态信息
class AppStateStore {
  static const String boxName = 'app_state_box';
  static const String _updateDialogShownKey = 'update_dialog_shown';
  static Box? _box;

  /// 初始化 Hive（需在 app 启动时调用一次）
  static Future<void> init() async {
    if (!Hive.isBoxOpen(boxName)) {
      _box = await Hive.openBox(boxName);
    } else {
      _box = Hive.box(boxName);
    }
  }

  /// 检查是否已经显示过更新弹窗
  static bool hasShownUpdateDialog() {
    return _box?.get(_updateDialogShownKey, defaultValue: false) ?? false;
  }

  /// 标记已经显示过更新弹窗
  static Future<void> markUpdateDialogShown() async {
    await _box?.put(_updateDialogShownKey, true);
  }

  /// 重置更新弹窗显示状态（用于测试或特殊情况）
  static Future<void> resetUpdateDialogShown() async {
    await _box?.put(_updateDialogShownKey, false);
  }

  /// 清除所有应用状态
  static Future<void> clear() async {
    await _box?.clear();
  }
}
