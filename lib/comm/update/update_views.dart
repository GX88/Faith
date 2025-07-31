import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:get/get.dart';

import '../../utils/update_utils.dart';
import '../ui/fa_button/index.dart';

class UpdateChecker extends StatelessWidget {
  final RemoteVersion remote;
  const UpdateChecker(this.remote, {super.key});

  void _onUpdate() async {
    await AppUpdateTool.to.download(remote);
  }

  void _onInstall() async {
    final path = AppUpdateTool.to.localPath.value;
    if (path != null) {
      await AppUpdateTool.to.install(path);
    }
  }

  void _onClose(BuildContext context) {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Obx(() {
      final errorMsg = AppUpdateTool.to.errorMessage.value ?? '';
      final status = AppUpdateTool.to.status.value;
      final progress = AppUpdateTool.to.progress.value;
      final localPath = AppUpdateTool.to.localPath.value;
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
                  '发现新版本 ${remote.tag}',
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
          if (remote.body != null && remote.body!.isNotEmpty)
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
                      remote.body!,
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
          // 按钮区
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 12),
            child: () {
              if (status == DownloadTaskStatus.undefined ||
                  status == DownloadTaskStatus.failed) {
                return FaButton(
                  onPressed: _onUpdate,
                  text: status == DownloadTaskStatus.failed ? '重试' : '立即更新',
                  block: true,
                  size: FaButtonSize.large,
                  borderRadius: 12,
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                );
              } else if (status == DownloadTaskStatus.running ||
                  status == DownloadTaskStatus.enqueued ||
                  status == DownloadTaskStatus.paused) {
                return Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      stops: [progress / 100.0, progress / 100.0],
                      colors: [theme.colorScheme.primary, Colors.grey[300]!],
                    ),
                  ),
                  child: FaButton(
                    onPressed: status == DownloadTaskStatus.paused
                        ? _onUpdate
                        : null,
                    text: status == DownloadTaskStatus.paused
                        ? '继续下载'
                        : '下载中...($progress%)',
                    block: true,
                    size: FaButtonSize.large,
                    borderRadius: 12,
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                  ),
                );
              } else if (status == DownloadTaskStatus.complete &&
                  localPath != null) {
                return FaButton(
                  onPressed: _onInstall,
                  text: '立即安装',
                  block: true,
                  size: FaButtonSize.large,
                  borderRadius: 12,
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                );
              } else {
                return FaButton(
                  onPressed: _onUpdate,
                  text: '立即更新',
                  block: true,
                  size: FaButtonSize.large,
                  borderRadius: 12,
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                );
              }
            }(),
          ),
          // “以后再说”按钮保持灰色、block、间距
          Center(
            child: GestureDetector(
              onTap: () => _onClose(context),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
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
        ],
      );
    });
  }
}
