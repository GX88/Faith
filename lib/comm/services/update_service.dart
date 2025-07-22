import 'dart:io';

import 'package:faith/config/config.default.dart';
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:get/get.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import '../../utils/update_util.dart';

class DownloadService extends GetxService {
  static DownloadService get to => Get.find();

  final DownloadUtils _downloadUtils = DownloadUtils();

  // 新增：安装模式（auto/手动manual）
  String installMode = 'manual';
  // 新增：保存APK路径
  String? _apkPath;

  // 下载状态
  final RxMap<String, double> _downloadProgress = <String, double>{}.obs;
  final RxMap<String, DownloadTaskStatus> _downloadStatus =
      <String, DownloadTaskStatus>{}.obs;

  // 添加版本信息相关变量
  final RxBool _hasNewVersion = false.obs;
  final RxString _newVersionInfo = ''.obs;
  final RxString _downloadUrl = ''.obs;

  // 添加下载任务ID记录
  String? _currentTaskId;

  // 公共 getter
  bool get hasNewVersion => _hasNewVersion.value;
  String get newVersionInfo => _newVersionInfo.value;
  RxMap<String, double> get downloadProgress => _downloadProgress;
  RxMap<String, DownloadTaskStatus> get downloadStatus => _downloadStatus;

  // 添加隐藏更新提示的方法
  void hideUpdateTip() {
    // 只有在没有下载任务时才隐藏更新提示
    if (_downloadProgress.isEmpty) {
      _hasNewVersion.value = false;
      // 确保关闭所有弹窗
      if (Get.isBottomSheetOpen ?? false) {
        Get.back(closeOverlays: true);
      }
    }
  }

  @override
  void onInit() {
    super.onInit();
    _initDownloader();
    _initCheckUpdate();
  }

  Future<void> _initDownloader() async {
    await _downloadUtils.initialize();
    _downloadUtils.registerCallback(_onDownloadProgress);

    // 加载已存在的下载任务
    final tasks = await _downloadUtils.loadTasks();
    if (tasks != null && tasks.isNotEmpty) {
      // 找到最后一个下载任务
      final lastTask = tasks.last;

      // 如果最后的任务是失败状态，清除它并显示更新提示
      if (lastTask.status == DownloadTaskStatus.failed) {
        await _downloadUtils.removeDownload(
          lastTask.taskId,
          shouldDeleteContent: true,
        );
      }
      // 如果是暂停或运行状态，记录并显示进度
      else if (lastTask.status == DownloadTaskStatus.paused ||
          lastTask.status == DownloadTaskStatus.running) {
        _currentTaskId = lastTask.taskId;
        _downloadProgress[lastTask.taskId] = lastTask.progress / 100;
        _downloadStatus[lastTask.taskId] = lastTask.status;
      }
      // 如果是完成状态，清除记录
      else if (lastTask.status == DownloadTaskStatus.complete) {
        await _downloadUtils.removeDownload(lastTask.taskId);
      }
    }
  }

  Future<void> _initCheckUpdate() async {
    try {
      await checkUpdate();
    } catch (e) {
      print('初始化检查更新失败: $e');
    }
  }

  void _onDownloadProgress(String id, DownloadTaskStatus status, int progress) {
    _downloadProgress[id] = progress / 100;
    _downloadStatus[id] = status;
    // 下载完成或失败时的处理
    if (status == DownloadTaskStatus.complete) {
      _onDownloadComplete(id);
    } else if (status == DownloadTaskStatus.failed) {
      _onDownloadFailed(id);
    }
  }

  void _onDownloadComplete(String taskId) async {
    // 直接指定为正式包路径
    _apkPath =
        '/storage/emulated/0/Download/${Config.instance.updateApkFileName}';
    Get.snackbar(
      '下载完成',
      '文件已成功下载',
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.green,
      colorText: Colors.white,
    );
    if (installMode == 'auto') {
      installApk();
    }
  }

  void _onDownloadFailed(String taskId) {
    Get.snackbar(
      '下载失败',
      '文件下载失败，请重试',
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.red,
      colorText: Colors.white,
    );
  }

  // 新增：手动调用安装
  void installApk() {
    if (_apkPath != null) {
      OpenFilex.open(_apkPath!);
      _clearDownloadRecord(); // 安装后再清理
    } else {
      Get.snackbar(
        '安装失败',
        '未找到安装包路径',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // 清理下载记录
  void _clearDownloadRecord() {
    if (_currentTaskId != null) {
      _downloadProgress.remove(_currentTaskId);
      _downloadStatus.remove(_currentTaskId);
      _currentTaskId = null;
    }
  }

  /// 检查更新
  Future<bool> checkUpdate() async {
    try {
      // 正式环境下应通过接口获取版本信息，这里仅作示例
      await Future.delayed(const Duration(milliseconds: 500));
      _hasNewVersion.value = true; // TODO: 正式环境应根据接口返回判断
      _newVersionInfo.value =
          '发现新版本 1.0.1\n1. 优化体验\n2. 修复问题'; // TODO: 正式环境应根据接口返回
      _downloadUrl.value = Config.instance.updateApkUrl;
      return _hasNewVersion.value;
    } catch (e) {
      print('检查更新失败: $e');
      return false;
    }
  }

  /// 开始下载更新
  Future<String?> startUpdateDownload() async {
    if (!_hasNewVersion.value || _downloadUrl.value.isEmpty) {
      return null;
    }
    if (_currentTaskId != null) {
      await _downloadUtils.removeDownload(
        _currentTaskId!,
        shouldDeleteContent: true,
      );
      _clearDownloadRecord();
    }
    String? taskId;
    String downloadDir = '/storage/emulated/0/Download';
    if (!Platform.isAndroid) {
      final dir = await getExternalStorageDirectory();
      if (dir != null) downloadDir = dir.path;
    }
    taskId = await _downloadUtils.startDownload(
      url: _downloadUrl.value,
      fileName: Config.instance.updateApkFileName,
      savedDir: downloadDir,
      showNotification: true,
      openFileFromNotification: true,
    );
    if (taskId != null) {
      _currentTaskId = taskId;
      _downloadProgress[taskId] = 0.0;
      _downloadStatus[taskId] = DownloadTaskStatus.enqueued;
    }
    return taskId;
  }

  /// 暂停下载
  Future<bool> pauseDownload(String taskId) async {
    return await _downloadUtils.pauseDownload(taskId);
  }

  /// 恢复下载
  Future<String?> resumeDownload(String taskId) async {
    return await _downloadUtils.resumeDownload(taskId);
  }

  /// 取消下载
  Future<bool> cancelDownload(String taskId) async {
    final result = await _downloadUtils.cancelDownload(taskId);
    if (result) {
      await _downloadUtils.removeDownload(taskId, shouldDeleteContent: true);
      _clearDownloadRecord();
      // 重新显示更新提示
      _hasNewVersion.value = true;
    }
    return result;
  }

  // 判断是否需要更新
  bool needUpdate() {
    return _hasNewVersion.value;
  }

  /// 重试下载
  Future<String?> retryDownload(String taskId) async {
    // 先清除旧任务
    if (_currentTaskId != null) {
      await _downloadUtils.removeDownload(
        _currentTaskId!,
        shouldDeleteContent: true,
      );
      _clearDownloadRecord();
    }
    // 开始新的下载
    return startUpdateDownload();
  }

  @override
  void onClose() {
    _downloadUtils.dispose();
    super.onClose();
  }
}
