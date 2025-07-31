import 'dart:developer';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:faith/config/config.default.dart';
import 'package:faith/store/remote_version.dart';
import 'package:faith/utils/permission_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:get/get.dart';
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

@pragma('vm:entry-point')
void downloadCallback(String id, int status, int progress) {
  log('下载回调(后台隔离): taskId=$id, status=$status, progress=$progress');

  // 查找主隔离的发送端口
  final SendPort? sendPort = IsolateNameServer.lookupPortByName(
    'downloader_send_port',
  );

  if (sendPort != null) {
    // 发送数据到主隔离
    sendPort.send([id, status, progress]);
  } else {
    log('下载回调: 找不到主隔离端口');
  }
}

/// 应用更新工具类
class AppUpdateTool extends GetxController {
  /* ---------- 单例注入 ---------- */
  static AppUpdateTool get to => Get.find(); // 任何地方使用 AppUpdateTool.to 获取实例

  /* ---------- 响应字段 ---------- */
  final RxBool hasUpdate = false.obs; // 是否有新版本
  final Rxn<RemoteVersion> remoteVersion = Rxn<RemoteVersion>(); // 更新版本信息
  final Rx<DownloadTaskStatus> status =
      DownloadTaskStatus.undefined.obs; // 下载状态
  final RxInt progress = 0.obs; // 下载进度
  final RxnString localPath = RxnString(); // 本地文件路径
  final RxnString errorMessage = RxnString(); // 错误信息

  String? _currentTaskId; // 当前下载任务 ID
  String? _updateDir; // 应用私有更新目录
  static String currentVersion() => Get.find<PackageInfo>().version; // 当前版本
  ReceivePort? _port; // 用于跨isolate通信

  /* ---------- 初始化 ---------- */
  Future<void> init() async {
    await FlutterDownloader.initialize(debug: true);

    // 初始化版本任务ID存储
    await VersionTaskIdStore.init();

    FlutterDownloader.registerCallback(downloadCallback); // 注册下载回调

    // 注册端口用于接收下载回调
    _port = ReceivePort();
    IsolateNameServer.registerPortWithName(
      _port!.sendPort,
      'downloader_send_port',
    );
    _port!.listen((dynamic data) async {
      String id = data[0];
      DownloadTaskStatus s = DownloadTaskStatus.fromInt(data[1]);
      int p = data[2];
      // 只处理当前任务
      if (id == _currentTaskId) {
        status.value = s;
        progress.value = p;

        // 如果下载完成，设置本地文件路径
        if (s == DownloadTaskStatus.complete) {
          try {
            final taskList = await FlutterDownloader.loadTasks();
            final task = taskList?.firstWhere(
              (task) => task.taskId == id,
              orElse: () => throw StateError('未找到任务'),
            );
            if (task != null) {
              localPath.value = '${task.savedDir}/${task.filename}';
              log('下载完成，文件路径: $localPath.value');
            }
          } catch (e) {
            log('获取下载完成文件路径时出错: $e');
          }
        }
      }
    });

    // 获取应用私有更新目录
    _updateDir = '${(await getExternalStorageDirectory())!.path}/updates';

    // 初始化创建更新目录
    if (!await Directory(_updateDir!).exists()) {
      await Directory(_updateDir!).create(recursive: true);
    }
  }

  /// 下载（断点续传）：
  /// 返回 true 表示下载成功，false 表示下载失败
  Future<UpdateDownloadResult> download(RemoteVersion rv) async {
    final permissionOk = await PermissionHelper.requestAllForUpdate();

    // 检查权限
    if (!permissionOk) {
      return UpdateDownloadResult(status: false, errMessage: '权限不足');
    }

    // 判断更新目录是否存在，如果不存在则创建
    if (!await Directory(_updateDir!).exists()) {
      await Directory(_updateDir!).create(recursive: true);
      // 且清除所有旧的下载任务
      await clearAllTasks();
    }

    // 根据版本号查询已存在的下载任务
    final existingTaskInfo = await getTaskByVersion(rv.tag);
    if (existingTaskInfo != null) {
      log(
        '找到已存在的下载任务: ${existingTaskInfo.taskId}, 状态: ${existingTaskInfo.status}',
      );
      // 如果任务已完成，直接返回成功
      if (existingTaskInfo.status == DownloadTaskStatus.complete) {
        // 构建完整的文件路径
        final filePath =
            '${existingTaskInfo.savedDir}/${existingTaskInfo.filename}';
        final file = File(filePath);

        // 检查文件是否存在
        if (await file.exists() && await verifySha(filePath, rv.shaUrl)) {
          // 设置本地路径和状态
          localPath.value = filePath;
          status.value = DownloadTaskStatus.complete;
          _currentTaskId = existingTaskInfo.taskId;
          return UpdateDownloadResult(status: true, localPath: filePath);
        } else {
          // 文件不存在，清空下载任务记录
          await FlutterDownloader.remove(
            taskId: existingTaskInfo.taskId,
            shouldDeleteContent: true,
          );
          // 清除版本号与taskId的关联
          await VersionTaskIdStore.removeTaskId(rv.tag);
        }
      }

      // 如果任务正在进行中，更新当前任务ID
      if (existingTaskInfo.status == DownloadTaskStatus.running ||
          existingTaskInfo.status == DownloadTaskStatus.enqueued ||
          existingTaskInfo.status == DownloadTaskStatus.paused) {
        _currentTaskId = existingTaskInfo.taskId;
        status.value = existingTaskInfo.status;
        progress.value = existingTaskInfo.progress;
        return UpdateDownloadResult(status: true);
      }
    }

    debugPrint(FlutterDownloader.loadTasks().toString());

    try {
      debugPrint('开始下载: ${rv.apkUrl}');

      // 创建新的下载任务
      final taskId = await FlutterDownloader.enqueue(
        url: rv.apkUrl,
        savedDir: _updateDir!,
        fileName: 'faith-preview-${rv.tag.replaceFirst('v', '')}.apk',
        showNotification: true,
        openFileFromNotification: false,
      );

      if (taskId != null) {
        // 保存版本号与taskId的关联
        await VersionTaskIdStore.saveTaskId(rv.tag, taskId);
        _currentTaskId = taskId;
        debugPrint('下载任务已创建: taskId=$taskId, version=${rv.tag}');
        return UpdateDownloadResult(status: true);
      } else {
        return UpdateDownloadResult(status: false, errMessage: '创建下载任务失败');
      }
    } catch (err) {
      return UpdateDownloadResult(status: false, errMessage: err.toString());
    }
  }

  /// 清理下载目录:
  /// 返回 true 表示清理成功，false 表示清理失败
  Future<bool> cleanDownloadDir() async {
    try {
      if (await Directory(_updateDir!).exists()) {
        await Directory(_updateDir!).delete(recursive: true);
        return true;
      } else {
        return false;
      }
    } catch (_) {
      return false;
    }
  }

  /// 清除所有下载任务:
  /// 返回 true 表示清除成功，false 表示清除失败
  Future<bool> clearAllTasks() async {
    try {
      final taskList = await FlutterDownloader.loadTasks();
      if (taskList != null) {
        for (final task in taskList) {
          await FlutterDownloader.remove(
            taskId: task.taskId,
            shouldDeleteContent: true, // 同时删除本地文件
          );
        }
      }
      // 清除版本任务ID存储
      await VersionTaskIdStore.clear();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// 根据版本号查询对应的下载任务信息:
  /// 返回任务信息，如果没有找到则返回null
  Future<TaskInfo?> getTaskByVersion(String version) async {
    try {
      // 从持久化存储中获取该版本对应的taskId
      final taskId = VersionTaskIdStore.getTaskId(version);
      if (taskId == null) {
        log('版本 $version 没有对应的下载任务ID');
        return null;
      }

      // 获取所有下载任务
      final taskList = await FlutterDownloader.loadTasks();
      if (taskList == null || taskList.isEmpty) {
        log('没有找到任何下载任务');
        return null;
      }

      // 查找对应的任务
      final task = taskList.firstWhere(
        (task) => task.taskId == taskId,
        orElse: () => throw StateError('未找到任务'),
      );

      log(
        '找到版本 $version 的下载任务: taskId=$taskId, status=${task.status}, progress=${task.progress}',
      );

      return TaskInfo(
        taskId: task.taskId,
        status: task.status,
        progress: task.progress,
        url: task.url,
        filename: task.filename ?? '',
        savedDir: task.savedDir,
        timeCreated: task.timeCreated,
      );
    } catch (e) {
      debugPrint('查询版本 $version 的下载任务时出错: $e');
      return null;
    }
  }

  /// 检查更新:
  /// 返回 true 表示有新版本，false 表示没有新版本
  Future<void> checkUpdate() async {
    final dio = Dio();

    try {
      final res = await dio.get(
        Config.instance.appUpdateUrl,
        options: Options(responseType: ResponseType.json),
      );
      final tag = res.data['tag_name'] as String;
      final cleanVersion = tag.replaceFirst('v', '');
      final apkAsset =
          res.data['assets'].firstWhere(
                (e) => e['name'] == 'faith-preview-$cleanVersion.apk',
              )['browser_download_url']
              as String;
      final shaAsset =
          res.data['assets'].firstWhere(
                (e) => e['name'] == 'faith-preview-$cleanVersion.apk.sha1',
              )['browser_download_url']
              as String;
      final body = res.data['body'] as String?;

      remoteVersion.value = RemoteVersion(
        tag: tag,
        apkUrl: apkAsset,
        shaUrl: shaAsset,
        body: body,
      );

      if (_isNewer(tag)) {
        hasUpdate.value = true;
        debugPrint('有新版本: $tag');
      }
    } catch (_) {
      hasUpdate.value = false; // 如果请求失败，确保设置为没有更新
      remoteVersion.value = null; // 清除远程版本信息
    }
  }

  /// 判断是否为新版本:
  /// 返回 true 表示远程版本大于本地版本，false 表示远程版本小于或等于本地版本
  static bool _isNewer(String remoteTag) {
    final local = currentVersion();
    final remote = remoteTag.replaceFirst('v', '');
    final al = remote.split('.').map(int.parse).toList();
    final bl = local.split('.').map(int.parse).toList();
    final maxLen = al.length > bl.length ? al.length : bl.length;

    while (al.length < maxLen) {
      al.add(0);
    }
    while (bl.length < maxLen) {
      bl.add(0);
    }

    for (var i = 0; i < maxLen; i++) {
      if (al[i] > bl[i]) return true;
      if (al[i] < bl[i]) return false;
    }
    return false;
  }

  /// 校验sha1:
  /// 返回 true 表示校验成功，false 表示校验失败
  static Future<bool> verifySha(String apkPath, String shaUrl) async {
    try {
      final expected = (await Dio().get(shaUrl)).data.trim();
      final bytes = await File(apkPath).readAsBytes();
      final actual = sha1.convert(bytes).toString();
      return expected == actual;
    } catch (e) {
      return false;
    }
  }

  /// 安装:
  /// 返回 true 表示安装成功，false 表示安装失败
  Future<void> install(String apkPath) async {
    final ok = await PermissionHelper.requestAllForUpdate();
    if (!ok) throw Exception('权限不足');
    final result = await OpenFilex.open(apkPath);
    if (result.type != ResultType.done) {
      // 将状态变成重试，清除下载任务
      await clearAllTasks();
      status.value = DownloadTaskStatus.failed;
      log('安装失败：${result.message}');
    }
  }

  @override
  void onClose() {
    // 移除端口注册，防止内存泄漏
    IsolateNameServer.removePortNameMapping('downloader_send_port');
    _port?.close();
    super.onClose();
  }
}

// 数据模型
class RemoteVersion {
  final String tag;
  final String apkUrl;
  final String shaUrl;
  final String? body; // 新增

  const RemoteVersion({
    required this.tag,
    required this.apkUrl,
    required this.shaUrl,
    this.body,
  });
}

class UpdateDownloadResult {
  final bool status;
  final String? errMessage;
  final String? localPath;

  UpdateDownloadResult({required this.status, this.errMessage, this.localPath});
}

/// 下载任务信息模型
class TaskInfo {
  final String taskId;
  final DownloadTaskStatus status;
  final int progress;
  final String url;
  final String filename;
  final String savedDir;
  final int timeCreated;

  const TaskInfo({
    required this.taskId,
    required this.status,
    required this.progress,
    required this.url,
    required this.filename,
    required this.savedDir,
    required this.timeCreated,
  });

  @override
  String toString() {
    return 'TaskInfo{taskId: $taskId, status: $status, progress: $progress, url: $url, filename: $filename, savedDir: $savedDir, timeCreated: $timeCreated}';
  }
}
