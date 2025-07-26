import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:faith/config/config.default.dart';
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:get/get.dart';
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

/// ================= 数据模型 =================
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

/// ================= 对外工具类 =================
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
    final owner = Config.instance.githubRepoOwner;
    final repo = Config.instance.githubRepoName;

    final dio = Dio();
    try {
      final res = await dio.get(
        'https://api.github.com/repos/$owner/$repo/releases/latest',
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
    debugPrint('remoteTag: $remoteTag');
    debugPrint('currentVersion: ${_currentVersion()}');
    debugPrint(
      'compareVersion: ${_compareVersion(remoteTag.replaceFirst('v', ''), _currentVersion())}',
    );

    return _compareVersion(remoteTag.replaceFirst('v', ''), _currentVersion()) >
        0;
  }

  /* ---------- 3. 下载（断点续传） ---------- */
  static Future<String?> download(RemoteVersion rv) async {
    try {
      final ok = await _requestPermissions();
      if (!ok) throw Exception('权限不足');

      // 使用外部私有目录下的updates子文件夹
      final baseDir = (await getExternalStorageDirectory())!.path;
      final updatesDir = Directory('$baseDir/updates');
      if (!await updatesDir.exists()) {
        await updatesDir.create(recursive: true);
      }
      final dir = updatesDir.path;

      final fileName = 'faith-${rv.tag}.apk';
      final filePath = '$dir/$fileName';
      
      // 检查本地文件是否存在且有效
      final localFile = File(filePath);
      if (await localFile.exists()) {
        // 验证SHA1
        final isValid = await verifySha(filePath, rv.shaUrl);
        if (isValid) {
          // 文件有效，返回特殊taskId
          return 'EXISTING_FILE_${rv.tag}';
        } else {
          // 文件无效，删除
          await localFile.delete();
        }
      }

      // 检查是否有现有任务
      final tasks = await FlutterDownloader.loadTasks();
      DownloadTask? existedTask;
      try {
        existedTask = tasks?.firstWhere(
          (t) => t.url == rv.apkUrl && t.savedDir == dir,
        );
      } catch (_) {
        existedTask = null;
      }

      // 处理现有任务
      if (existedTask != null) {
        debugPrint('找到现有任务: ${existedTask.taskId}, 状态: ${existedTask.status}');
        
        // 如果任务已完成，检查文件是否存在且有效
        if (existedTask.status == DownloadTaskStatus.complete) {
          final taskFilePath = '${existedTask.savedDir}/${existedTask.filename}';
          final taskFile = File(taskFilePath);
          
          if (await taskFile.exists()) {
            final isValid = await verifySha(taskFilePath, rv.shaUrl);
            if (isValid) {
              // 文件有效，返回taskId
              return existedTask.taskId;
            } else {
              // 文件无效，删除任务和文件
              await FlutterDownloader.remove(taskId: existedTask.taskId, shouldDeleteContent: true);
            }
          } else {
            // 文件不存在，删除任务
            await FlutterDownloader.remove(taskId: existedTask.taskId, shouldDeleteContent: true);
          }
        } 
        // 如果任务暂停或失败，恢复下载
        else if (existedTask.status == DownloadTaskStatus.paused || 
                 existedTask.status == DownloadTaskStatus.failed) {
          await FlutterDownloader.resume(taskId: existedTask.taskId);
          return existedTask.taskId;
        }
        // 如果任务正在运行或排队中，返回taskId
        else if (existedTask.status == DownloadTaskStatus.running || 
                 existedTask.status == DownloadTaskStatus.enqueued) {
          return existedTask.taskId;
        }
        // 其他状态，删除任务重新下载
        else {
          await FlutterDownloader.remove(taskId: existedTask.taskId, shouldDeleteContent: true);
        }
      }

      // 创建新任务
      final newTaskId = await FlutterDownloader.enqueue(
        url: rv.apkUrl,
        savedDir: dir,
        fileName: fileName,
        showNotification: true,
        openFileFromNotification: false,
      );
      debugPrint('创建新任务: $newTaskId');
      return newTaskId;
    } catch (e) {
      debugPrint('下载失败: $e');
      return null;
    }
  }

  /* ---------- 4. 校验 SHA-1 ---------- */
  static Future<bool> verifySha(String apkPath, String shaUrl) async {
    final expected = (await Dio().get(shaUrl)).data.trim();
    final bytes = await File(apkPath).readAsBytes();
    final actual = sha1.convert(bytes).toString();
    return expected == actual;
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
    final ok = await _requestPermissions();
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

  /* ---------- 私有工具 ---------- */
  static String _currentVersion() => Get.find<PackageInfo>().version;

  static int _compareVersion(String a, String b) {
    final al = a.split('.').map(int.parse).toList();
    final bl = b.split('.').map(int.parse).toList();
    for (var i = 0; i < al.length; i++) {
      if (al[i] > bl[i]) return 1;
      if (al[i] < bl[i]) return -1;
    }
    return 0;
  }

  static Future<bool> _requestPermissions() async {
    final storage = await Permission.storage.request();
    final install = await Permission.requestInstallPackages.request();
    return storage.isGranted && install.isGranted;
  }
}
