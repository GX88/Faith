import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:faith/config/config.default.dart';
import 'package:faith/utils/permission_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:get/get.dart';
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

/// 下载结果状态
enum UpdateDownloadState {
  fileReady, // 已有有效文件
  downloading, // 新建或已有下载任务
  failed, // 下载失败
}

class UpdateDownloadResult {
  final UpdateDownloadState state;
  final String? taskId;
  final String? filePath;
  final String? error;

  UpdateDownloadResult({
    required this.state,
    this.taskId,
    this.filePath,
    this.error,
  });
}

// ================= 数据模型 =================
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

  @override
  String toString() {
    return 'RemoteVersion(tag: $tag, apkUrl: $apkUrl, shaUrl: $shaUrl, body: $body)';
  }
}

/// 应用更新工具类
class AppUpdateTool {
  /* ---------- 清理updates文件夹 ---------- */
  static Future<bool> cleanUpdatesFolder() async {
    try {
      final baseDir = (await getExternalStorageDirectory())!.path;
      final updatesDir = Directory('$baseDir/updates');

      if (await updatesDir.exists()) {
        // 删除文件夹及其内容
        await updatesDir.delete(recursive: true);
        debugPrint('Updates文件夹已清理');
        return true;
      } else {
        debugPrint('Updates文件夹不存在');
        return false;
      }
    } catch (e) {
      debugPrint('清理Updates文件夹失败: $e');
      return false;
    }
  }

  /* ---------- 1. 检查更新 ---------- */
  static Future<RemoteVersion?> checkUpdate() async {
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
      return RemoteVersion(
        tag: tag,
        apkUrl: apkAsset,
        shaUrl: shaAsset,
        body: body,
      );
    } catch (_) {
      return null;
    }
  }

  /* ---------- 2. 版本号比较 ---------- */
  static bool isNewer(String remoteTag) {
    final local = currentVersion();
    final remote = remoteTag.replaceFirst('v', '');
    debugPrint('remoteTag: $remote, currentVersion: $local');
    return compareVersion(remote, local) > 0;
  }

  /* ---------- 3. 下载（断点续传） ---------- */
  static Future<UpdateDownloadResult> download(RemoteVersion rv) async {
    try {
      final ok = await PermissionHelper.requestAllForUpdate();
      if (!ok) {
        return UpdateDownloadResult(
          state: UpdateDownloadState.failed,
          error: '权限不足',
        );
      }

      final baseDir = (await getExternalStorageDirectory())!.path;
      final updatesDir = Directory('$baseDir/updates');
      if (!await updatesDir.exists()) {
        await updatesDir.create(recursive: true);
      }
      final fileName = 'faith-${rv.tag}.apk';
      final filePath = '${updatesDir.path}/$fileName';

      // 检查本地文件
      final localFile = File(filePath);
      if (await localFile.exists()) {
        final isValid = await verifySha(filePath, rv.shaUrl);
        if (isValid) {
          return UpdateDownloadResult(
            state: UpdateDownloadState.fileReady,
            filePath: filePath,
          );
        } else {
          await localFile.delete();
        }
      }

      // 检查现有任务，并同步校验本地文件
      final tasks = await FlutterDownloader.loadTasks();
      DownloadTask? existedTask;
      try {
        existedTask = tasks?.firstWhere(
          (t) => t.url == rv.apkUrl && t.savedDir == updatesDir.path,
        );
      } catch (_) {
        existedTask = null;
      }

      if (existedTask != null) {
        final taskFilePath = '${existedTask.savedDir}/${existedTask.filename}';
        final taskFile = File(taskFilePath);
        final fileExists = await taskFile.exists();
        final fileValid =
            fileExists && await verifySha(taskFilePath, rv.shaUrl);

        // 只要本地文件不存在或无效，彻底移除任务和文件
        if (!fileValid) {
          await FlutterDownloader.remove(
            taskId: existedTask.taskId,
            shouldDeleteContent: true,
          );
          if (fileExists) await taskFile.delete();
        } else {
          switch (existedTask.status) {
            case DownloadTaskStatus.complete:
              return UpdateDownloadResult(
                state: UpdateDownloadState.fileReady,
                filePath: taskFilePath,
                taskId: existedTask.taskId,
              );
            case DownloadTaskStatus.paused:
              final newTaskId = await FlutterDownloader.resume(
                taskId: existedTask.taskId,
              );
              return UpdateDownloadResult(
                state: UpdateDownloadState.downloading,
                taskId: newTaskId ?? existedTask.taskId,
              );
            case DownloadTaskStatus.failed:
              await FlutterDownloader.remove(
                taskId: existedTask.taskId,
                shouldDeleteContent: true,
              );
              break;
            case DownloadTaskStatus.running:
            case DownloadTaskStatus.enqueued:
              return UpdateDownloadResult(
                state: UpdateDownloadState.downloading,
                taskId: existedTask.taskId,
              );
            default:
              await FlutterDownloader.remove(
                taskId: existedTask.taskId,
                shouldDeleteContent: true,
              );
          }
        }
      }

      // 新建任务
      final newTaskId = await FlutterDownloader.enqueue(
        url: rv.apkUrl,
        savedDir: updatesDir.path,
        fileName: fileName,
        showNotification: true,
        openFileFromNotification: false,
      );
      debugPrint('创建新任务: $newTaskId');
      return UpdateDownloadResult(
        state: UpdateDownloadState.downloading,
        taskId: newTaskId,
      );
    } catch (e) {
      debugPrint('下载失败: $e');
      return UpdateDownloadResult(
        state: UpdateDownloadState.failed,
        error: e.toString(),
      );
    }
  }

  /* ---------- 4. 校验 SHA-1 ---------- */
  static Future<bool> verifySha(String apkPath, String shaUrl) async {
    try {
      final expected = (await Dio().get(shaUrl)).data.trim();
      final bytes = await File(apkPath).readAsBytes();
      final actual = sha1.convert(bytes).toString();
      return expected == actual;
    } catch (e) {
      debugPrint('SHA校验异常: $e');
      return false;
    }
  }

  /* ---------- 5. 校验并清理 ---------- */
  static Future<bool> verifyAndCleanIfInvalid(
    String apkPath,
    String shaUrl,
  ) async {
    final ok = await verifySha(apkPath, shaUrl);
    if (!ok) await File(apkPath).delete();
    return ok;
  }

  /* ---------- 6. 安装 APK ---------- */
  static Future<void> install(String apkPath) async {
    final ok = await PermissionHelper.requestAllForUpdate();
    if (!ok) throw Exception('权限不足');
    final result = await OpenFilex.open(apkPath);
    if (result.type != ResultType.done) {
      throw Exception('安装失败：${result.message}');
    }
  }

  /* ---------- 7. 安装后清理 ---------- */
  static Future<void> cleanAfterInstall(
    String apkPath, {
    bool keep = false,
  }) async {
    if (!keep) {
      final f = File(apkPath);
      if (await f.exists()) await f.delete();
    }
  }

  /* ---------- 8. 根据 taskId 取本地路径 ---------- */
  static Future<String?> filePathOf(String taskId) async {
    final tasks = await FlutterDownloader.loadTasks();
    DownloadTask? task;
    try {
      task = tasks?.firstWhere((t) => t.taskId == taskId);
    } catch (_) {
      task = null;
    }
    return task == null ? null : '${task.savedDir}/${task.filename}';
  }

  /// 获取当前应用版本
  static String currentVersion() => Get.find<PackageInfo>().version;

  /// 比较版本号
  static int compareVersion(String a, String b) {
    final al = a.split('.').map(int.parse).toList();
    final bl = b.split('.').map(int.parse).toList();
    final maxLen = al.length > bl.length ? al.length : bl.length;
    while (al.length < maxLen) al.add(0);
    while (bl.length < maxLen) bl.add(0);
    for (var i = 0; i < maxLen; i++) {
      if (al[i] > bl[i]) return 1;
      if (al[i] < bl[i]) return -1;
    }
    return 0;
  }
}
