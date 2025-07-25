import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';

import '../../utils/update_util.dart';
import '../ui/fa_bottom_sheet/index.dart';
import '../ui/fa_button/index.dart';

// 下载进度事件类和全局 stream
class DownloadProgressEvent {
  final String taskId;
  final int status;
  final int progress;
  DownloadProgressEvent(this.taskId, this.status, this.progress);
}

final StreamController<DownloadProgressEvent> downloadProgressStream =
    StreamController.broadcast();

// 顶级公有回调函数，供 FlutterDownloader native 调用
@pragma('vm:entry-point')
void downloadCallback(String id, int status, int progress) {
  downloadProgressStream.add(DownloadProgressEvent(id, status, progress));
}

class UpdateChecker extends StatefulWidget {
  final RemoteVersion remote;
  const UpdateChecker(this.remote, {super.key});

  /// 静态方法，弹出底部弹窗显示更新内容
  static Future<void> show(RemoteVersion remote) {
    return CustomBottomSheetHelper.showCustomBottomSheet(
      context: Get.context!,
      child: UpdateChecker(remote),
      barrierDismissible: true,
      animationDuration: const Duration(milliseconds: 600),
    );
  }

  @override
  State<UpdateChecker> createState() => _UpdateCheckerState();
}

class _UpdateCheckerState extends State<UpdateChecker> {
  String taskId = '';
  int progress = 0;
  DownloadTaskStatus status = DownloadTaskStatus.undefined;
  String errorMsg = '';
  StreamSubscription? _progressSub;

  @override
  void initState() {
    super.initState();
    // 监听下载进度
    FlutterDownloader.registerCallback(downloadCallback);
    _progressSub = downloadProgressStream.stream.listen((event) {
      if (event.taskId == taskId && mounted) {
        setState(() {
          status = DownloadTaskStatus.values[event.status];
          progress = event.progress;
        });
      }
    });
  }

  @override
  void dispose() {
    _progressSub?.cancel();
    super.dispose();
  }

  Future<void> onUpdate() async {
    try {
      final id = await AppUpdateTool.download(widget.remote);
      if (id != null) {
        setState(() {
          taskId = id;
          errorMsg = '';
        });
      } else {
        setState(() {
          errorMsg = '下载任务创建失败，可能是权限或网络问题';
        });
      }
    } catch (e) {
      setState(() {
        errorMsg = '下载异常: $e';
      });
    }
  }

  Future<void> onInstall() async {
    try {
      String? path;

      if (taskId == 'EXISTING_FILE') {
        // 文件已存在，直接构建路径
        final baseDir = (await getExternalStorageDirectory())!.path;
        final updatesDir = Directory('$baseDir/updates');
        path = '${updatesDir.path}/faith-${widget.remote.tag}.apk';
      } else {
        // 从下载任务获取路径
        path = await AppUpdateTool.filePathOf(taskId);
      }

      if (path == null) {
        setState(() {
          errorMsg = '找不到文件';
        });
        return;
      }

      final ok = await AppUpdateTool.verifyAndCleanIfInvalid(
        path,
        widget.remote.shaUrl,
      );
      if (!ok) {
        setState(() {
          errorMsg = '文件校验失败，已删除';
        });
        return;
      }
      await AppUpdateTool.install(path);
      // TODO: 安装后暂不自动删除APK，后续可在合适时机清理
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      setState(() {
        errorMsg = e.toString();
      });
    }
  }

  void onClose() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 顶部图标与标题一行，现代化设计
        Padding(
          padding: const EdgeInsets.only(bottom: 18),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.rocket_launch_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Text(
                '发现新版本 ${widget.remote.tag}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        // 内容区卡片
        if (widget.remote.body != null && widget.remote.body!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 14, bottom: 18),
            child: Container(
              constraints: const BoxConstraints(
                maxHeight: 220, // 限定最大高度，超出可滚动
                minWidth: double.infinity,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16), // 只左右内边距
              decoration: BoxDecoration(
                color: Colors.grey[100], // 恢复背景色，提升层级感
                borderRadius: BorderRadius.circular(12),
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.only(top: 8), // 文字向上有边距
                  child: Text(
                    widget.remote.body!,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.black87,
                      height: 1.7,
                    ),
                    textAlign: TextAlign.left,
                  ),
                ),
              ),
            ),
          ),
        if (errorMsg.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              errorMsg,
              style: const TextStyle(color: Colors.red, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ),
        // 下载进度与按钮
        if (taskId.isEmpty)
          // 主按钮
          SizedBox(
            width: double.infinity,
            child: FaButton(
              onPressed: onUpdate,
              text: '立即更新',
              size: FaButtonSize.large,
              borderRadius: 12,
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.white,
            ),
          )
        else if (status == DownloadTaskStatus.enqueued ||
            status == DownloadTaskStatus.running)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              children: [
                LinearProgressIndicator(value: progress / 100),
                const SizedBox(height: 6),
                Text(
                  status == DownloadTaskStatus.enqueued
                      ? '准备下载...'
                      : '$progress%',
                  style: const TextStyle(fontSize: 13, color: Colors.black54),
                ),
              ],
            ),
          )
        else if (status == DownloadTaskStatus.complete ||
            taskId == 'EXISTING_FILE')
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 12),
            child: FaButton(
              onPressed: onInstall,
              text: taskId == 'EXISTING_FILE' ? '文件已存在，立即安装' : '立即安装',
              icon: Icon(
                Icons.install_mobile_rounded,
                color: Colors.white,
                size: 22,
              ),
              block: true,
              size: FaButtonSize.large,
              borderRadius: 12,
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.white,
            ),
          )
        else if (status == DownloadTaskStatus.failed ||
            status == DownloadTaskStatus.undefined)
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 12),
            child: FaButton(
              onPressed: onUpdate,
              text: '重试',
              icon: Icon(
                Icons.refresh_rounded,
                color: theme.colorScheme.primary,
                size: 22,
              ),
              block: true,
              size: FaButtonSize.large,
              borderRadius: 12,
              type: FaButtonType.outline,
            ),
          )
        else if (status == DownloadTaskStatus.failed)
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 12),
            child: FaButton(
              onPressed: onUpdate,
              text: '重试',
              icon: Icon(
                Icons.refresh_rounded,
                color: theme.colorScheme.primary,
                size: 22,
              ),
              block: true,
              size: FaButtonSize.large,
              borderRadius: 12,
              type: FaButtonType.outline,
            ),
          )
        else
          SizedBox(
            width: double.infinity,
            child: FaButton(
              onPressed: onUpdate,
              text: '立即更新',
              size: FaButtonSize.large,
              borderRadius: 12,
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.white,
            ),
          ),
        // “以后再说”按钮保持灰色、block、间距
        Center(
          child: GestureDetector(
            onTap: onClose,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Container(
                child: Text(
                  '以后再说',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 15,
                    decoration: TextDecoration.none,
                    decorationColor: Colors.transparent,
                    decorationThickness: 0,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
