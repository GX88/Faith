import 'dart:async';
import 'dart:isolate';
import 'dart:ui';

// ...

import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:get/get.dart';

// ...

import '../../utils/update_util.dart';
import '../ui/fa_bottom_sheet/index.dart';
import '../ui/fa_button/index.dart';
import 'progress_button.dart';

// ...

// 用于隔离通信的端口名称
const String _isolateName = 'downloader_isolate';

// 顶级公有回调函数，供 FlutterDownloader native 调用
@pragma('vm:entry-point')
void downloadCallback(String id, int status, int progress) {
  debugPrint('下载回调(后台隔离): taskId=$id, status=$status, progress=$progress');

  // 查找主隔离的发送端口
  final SendPort? sendPort = IsolateNameServer.lookupPortByName(_isolateName);

  if (sendPort != null) {
    // 发送数据到主隔离
    sendPort.send([id, status, progress]);
    debugPrint('下载回调: 已发送到主隔离');
  } else {
    debugPrint('下载回调: 找不到主隔离端口');
  }
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
  UpdateDownloadState? downloadState;
  String? taskId;
  Set<String> activeTaskIds = {};
  String? filePath;
  DownloadTaskStatus status = DownloadTaskStatus.undefined;
  int progress = 0;
  String errorMsg = '';
  // ...
  ReceivePort? _port;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _port = ReceivePort();
    IsolateNameServer.registerPortWithName(_port!.sendPort, _isolateName);
    _port!.listen((dynamic data) async {
      String id = data[0];
      int statusValue = data[1];
      int progressValue = data[2];
      if (!mounted) return;
      // 支持多 taskId（resume 后新旧 id 都监听）
      if (activeTaskIds.isNotEmpty && !activeTaskIds.contains(id)) return;
      final newStatus = DownloadTaskStatus.values[statusValue];
      setState(() {
        status = newStatus;
        progress = progressValue;
        // 只要有回调，确保 taskId 与 activeTaskIds同步
        if (taskId != id) {
          taskId = id;
        }
        activeTaskIds.add(id);
      });
      // 进度100且状态为complete时，自动切换为fileReady，刷新按钮为“立即安装”
      if (progressValue == 100 && newStatus == DownloadTaskStatus.complete) {
        final path =
            filePath ??
            (taskId != null ? await AppUpdateTool.filePathOf(taskId!) : null);
        setState(() {
          downloadState = UpdateDownloadState.fileReady;
          filePath = path;
          status = DownloadTaskStatus.complete;
          progress = 100;
          activeTaskIds.clear();
        });
      }
    });
    // ...
  }

  @override
  void dispose() {
    // ...
    _port?.close();
    IsolateNameServer.removePortNameMapping(_isolateName);
    super.dispose();
  }

  Future<void> onUpdate() async {
    if (_loading) return;
    _loading = true;
    setState(() {
      errorMsg = '';
      downloadState = null;
      // 不重置 taskId/progress/status，避免暂停后进度丢失
    });
    final result = await AppUpdateTool.download(widget.remote);
    setState(() {
      downloadState = result.state;
      taskId = result.taskId;
      filePath = result.filePath;
      errorMsg = result.error ?? '';
      if (result.state == UpdateDownloadState.downloading &&
          result.taskId != null) {
        // resume/新任务都加入监听
        activeTaskIds.add(result.taskId!);
        // 只有新任务才重置进度
        if (taskId != null && taskId != result.taskId) {
          status = DownloadTaskStatus.enqueued;
          progress = 0;
        }
      } else if (result.state == UpdateDownloadState.fileReady) {
        status = DownloadTaskStatus.complete;
        progress = 100;
        activeTaskIds.clear();
      } else if (result.state == UpdateDownloadState.failed) {
        status = DownloadTaskStatus.failed;
        taskId = null;
        filePath = null;
        activeTaskIds.clear();
      }
    });
    _loading = false;
  }

  Future<void> onInstall() async {
    if (_loading) return;
    _loading = true;
    try {
      final path =
          filePath ??
          (taskId != null ? await AppUpdateTool.filePathOf(taskId!) : null);
      if (path == null) {
        setState(() {
          errorMsg = '找不到文件';
          downloadState = UpdateDownloadState.failed;
          taskId = null;
          filePath = null;
        });
        _loading = false;
        return;
      }
      final ok = await AppUpdateTool.verifyAndCleanIfInvalid(
        path,
        widget.remote.shaUrl,
      );
      if (!ok) {
        setState(() {
          errorMsg = '文件校验失败，已删除';
          downloadState = UpdateDownloadState.failed;
          taskId = null;
          filePath = null;
        });
        _loading = false;
        return;
      }
      await AppUpdateTool.install(path);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      setState(() {
        errorMsg = e.toString();
        downloadState = UpdateDownloadState.failed;
        taskId = null;
        filePath = null;
      });
    }
    _loading = false;
  }

  void onClose() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // 添加调试信息
    debugPrint('构建UI: taskId=$taskId, status=$status, progress=$progress');

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
        Builder(
          builder: (context) {
            if (downloadState == null ||
                downloadState == UpdateDownloadState.failed) {
              // 未开始或失败
              return Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 12),
                child: FaButton(
                  onPressed: onUpdate,
                  text: downloadState == UpdateDownloadState.failed
                      ? '重试'
                      : '立即更新',
                  icon: downloadState == UpdateDownloadState.failed
                      ? Icon(
                          Icons.refresh_rounded,
                          color: theme.colorScheme.primary,
                          size: 22,
                        )
                      : null,
                  block: true,
                  size: FaButtonSize.large,
                  borderRadius: 12,
                  backgroundColor: downloadState == UpdateDownloadState.failed
                      ? null
                      : theme.colorScheme.primary,
                  foregroundColor: downloadState == UpdateDownloadState.failed
                      ? null
                      : Colors.white,
                  type: downloadState == UpdateDownloadState.failed
                      ? FaButtonType.outline
                      : FaButtonType.primary,
                ),
              );
            } else if (downloadState == UpdateDownloadState.downloading) {
              // 下载中，按钮进度即背景色
              return Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: ProgressButton(
                        progress: (progress / 100).clamp(0.0, 1.0),
                        text: status == DownloadTaskStatus.paused
                            ? '继续下载 ($progress%)'
                            : status == DownloadTaskStatus.enqueued
                            ? '准备下载...'
                            : '下载中 ($progress%)',
                        onPressed: status == DownloadTaskStatus.paused
                            ? () async {
                                if (taskId != null) {
                                  final newTaskId =
                                      await FlutterDownloader.resume(
                                        taskId: taskId!,
                                      );
                                  if (newTaskId != null) {
                                    setState(() {
                                      // 新旧 id 都监听
                                      activeTaskIds.add(newTaskId);
                                      activeTaskIds.add(taskId!);
                                      taskId = newTaskId;
                                    });
                                  } else {
                                    // 某些平台 resume 返回 null，继续监听原 id
                                    setState(() {
                                      activeTaskIds.add(taskId!);
                                    });
                                  }
                                }
                              }
                            : status == DownloadTaskStatus.running ||
                                  status == DownloadTaskStatus.enqueued
                            ? () async {
                                if (taskId != null) {
                                  await FlutterDownloader.pause(
                                    taskId: taskId!,
                                  );
                                }
                              }
                            : null,
                        enabled:
                            status == DownloadTaskStatus.paused ||
                            status == DownloadTaskStatus.running ||
                            status == DownloadTaskStatus.enqueued,
                        icon: status == DownloadTaskStatus.paused
                            ? Icon(
                                Icons.play_arrow_rounded,
                                color: Theme.of(context).colorScheme.primary,
                                size: 22,
                              )
                            : Icon(
                                Icons.pause_rounded,
                                color: Theme.of(context).colorScheme.primary,
                                size: 22,
                              ),
                        backgroundColor: Colors.transparent,
                        progressColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(context).colorScheme.primary,
                        borderRadius: 12,
                        height: 48,
                      ),
                    ),
                  ],
                ),
              );
            } else if (downloadState == UpdateDownloadState.fileReady) {
              // 下载完成
              return Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 12),
                child: FaButton(
                  onPressed: onInstall,
                  text: '立即安装',
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
              );
            } else {
              // 兜底
              return SizedBox(
                width: double.infinity,
                child: FaButton(
                  onPressed: onUpdate,
                  text: '立即更新',
                  size: FaButtonSize.large,
                  borderRadius: 12,
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
              );
            }
          },
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
