// 使用hive动态存储版本更新的信息
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// 用于持久化存储版本号与下载任务ID的关联关系
class VersionTaskIdStore {
  static const String boxName = 'version_taskid_box';
  static Box? _box;

  /// 初始化 Hive（需在 app 启动时调用一次）
  static Future<void> init() async {
    if (!Hive.isBoxOpen(boxName)) {
      _box = await Hive.openBox(boxName);
    } else {
      _box = Hive.box(boxName);
    }
  }

  /// 保存版本号与taskId的关联
  static Future<void> saveTaskId(String version, String taskId) async {
    await _box?.put(version, taskId);
  }

  /// 获取指定版本号的taskId
  static String? getTaskId(String version) {
    return _box?.get(version) as String?;
  }

  /// 删除指定版本号的taskId
  static Future<void> removeTaskId(String version) async {
    await _box?.delete(version);
  }

  /// 清空所有关联
  static Future<void> clear() async {
    await _box?.clear();
  }
}
