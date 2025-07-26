import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';

import '../../utils/update_util.dart';
import '../ui/fa_bottom_sheet/index.dart';
import '../ui/fa_button/index.dart';

import 'dart:isolate';
import 'dart:ui';

// 下载进度事件类和全局 stream
class DownloadProgressEvent {
  final String taskId;
  final int status;
  final int progress;
  DownloadProgressEvent(this.taskId, this.status, this.progress);
}

final StreamController<DownloadProgressEvent> downloadProgressStream =
    StreamController.broadcast();

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
  String taskId = '';
  int progress = 0;
  DownloadTaskStatus status = DownloadTaskStatus.undefined;
  String errorMsg = '';
  StreamSubscription? _progressSub;

  // 接收端口，用于接收后台隔离的消息
  ReceivePort? _port;
  
  @override
  void initState() {
    super.initState();
    
    // 创建接收端口并注册到隔离名称服务
    _port = ReceivePort();
    IsolateNameServer.registerPortWithName(_port!.sendPort, _isolateName);
    
    // 监听接收端口，接收后台隔离发送的下载进度事件
    _port!.listen((dynamic data) {
      // 解析数据
      String id = data[0];
      int statusValue = data[1];
      int progressValue = data[2];
      
      debugPrint('主隔离收到下载进度: taskId=$id, status=$statusValue, progress=$progressValue');
      debugPrint('当前taskId: $taskId, 是否匹配: ${id == taskId}');
      
      if (id == taskId && mounted) {
        final newStatus = DownloadTaskStatus.values[statusValue];
        debugPrint('更新状态: $status -> $newStatus, 进度: $progress -> $progressValue');
        
        setState(() {
          status = newStatus;
          progress = progressValue;
        });
      }
    });
    
    // 保留原有的stream监听，以兼容旧代码
    _progressSub = downloadProgressStream.stream.listen((event) {
      debugPrint('收到stream事件: taskId=${event.taskId}, status=${event.status}, progress=${event.progress}');
    });
  }

  @override
  void dispose() {
    // 取消流订阅
    _progressSub?.cancel();
    
    // 关闭接收端口
    _port?.close();
    
    // 从隔离名称服务中移除端口映射
    IsolateNameServer.removePortNameMapping(_isolateName);
    
    super.dispose();
  }

  Future<void> onUpdate() async {
    try {
      debugPrint('开始下载更新...');
      final id = await AppUpdateTool.download(widget.remote);
      debugPrint('下载任务创建结果: $id');
      
      if (id != null) {
        setState(() {
          taskId = id;
          errorMsg = '';
          
          // 如果是已存在的文件，状态设为完成
          if (id == 'EXISTING_FILE' || id.startsWith('EXISTING_FILE_')) {
            status = DownloadTaskStatus.complete;
          } 
          // 如果是新任务，初始状态设为排队中
          else {
            status = DownloadTaskStatus.enqueued;
            progress = 0;
          }
        });
        
        debugPrint('下载任务状态已更新: taskId=$taskId, status=$status');
      } else {
        setState(() {
          errorMsg = '下载任务创建失败，可能是权限或网络问题';
        });
      }
    } catch (e) {
      debugPrint('下载异常: $e');
      setState(() {
        errorMsg = '下载异常: $e';
      });
    }
  }

  Future<void> onInstall() async {
    try {
      String? path;

      if (taskId == 'EXISTING_FILE' || taskId.startsWith('EXISTING_FILE_')) {
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
        Builder(builder: (context) {
          // 添加调试信息
          debugPrint('构建下载按钮: taskId=$taskId, status=$status, progress=$progress');
          
          // 根据不同状态显示不同UI
          if (taskId.isEmpty) {
            // 主按钮 - 未开始下载
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
          } else if (status == DownloadTaskStatus.enqueued || status == DownloadTaskStatus.running) {
            // 下载中 - 显示进度条
            return Padding(
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
            );
          } else if (status == DownloadTaskStatus.complete || 
                     taskId == 'EXISTING_FILE' || 
                     taskId.startsWith('EXISTING_FILE_')) {
            // 下载完成 - 显示安装按钮
            return Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 12),
              child: FaButton(
                onPressed: onInstall,
                text: taskId == 'EXISTING_FILE' || taskId.startsWith('EXISTING_FILE_')
                    ? '文件已存在，立即安装'
                    : '立即安装',
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
          } else if (status == DownloadTaskStatus.failed || status == DownloadTaskStatus.undefined) {
            // 下载失败 - 显示重试按钮
            return Padding(
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
            );
          } else {
            // 其他状态 - 显示更新按钮
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
        }),
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
