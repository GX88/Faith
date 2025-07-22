import 'package:faith/comm/services/update_service.dart';
import 'package:faith/comm/ui/fa_button/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:get/get.dart';

class UpdateChecker extends GetView<DownloadService> {
  const UpdateChecker({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final hasNewVersion = controller.hasNewVersion;
      final newVersionInfo = controller.newVersionInfo;
      final downloadProgress = controller.downloadProgress;
      final downloadStatus = controller.downloadStatus;

      // 如果没有更新且没有下载任务，关闭弹层
      if (!hasNewVersion && downloadProgress.isEmpty) {
        Future.microtask(() {
          if (Get.isBottomSheetOpen ?? false) {
            Get.back(closeOverlays: true);
          }
        });
        return const SizedBox.shrink();
      }

      // 如果正在下载，不允许关闭
      if (downloadProgress.isNotEmpty) {
        final taskId = downloadProgress.keys.first;
        final status = downloadStatus[taskId] ?? DownloadTaskStatus.undefined;

        // 如果下载失败，显示重试界面
        if (status == DownloadTaskStatus.failed) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                '下载失败',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: FaButton(
                      text: '暂不更新',
                      type: FaButtonType.outline,
                      onPressed: () {
                        controller.cancelDownload(taskId);
                        Get.back(closeOverlays: true);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FaButton(
                      text: '重试',
                      onPressed: () => controller.retryDownload(taskId),
                    ),
                  ),
                ],
              ),
            ],
          );
        }
      }

      // 显示更新信息
      return IntrinsicHeight(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color.fromRGBO(0, 0, 0, 0.08),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.system_update,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                const Text(
                  '发现新版本',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.3,
              ),
              child: SingleChildScrollView(
                child: Text(
                  newVersionInfo,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color.fromRGBO(0, 0, 0, 0.6),
                    height: 1.5,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
            if (downloadProgress.isNotEmpty) ...[
              const SizedBox(height: 24),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.white,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: downloadProgress.values.first,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).primaryColor,
                    ),
                    minHeight: 8,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${(downloadProgress.values.first * 100).toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
            const SizedBox(height: 24),
            Row(
              children: [
                if (downloadProgress.isNotEmpty)
                  Expanded(
                    child: Builder(
                      builder: (context) {
                        final taskId = downloadProgress.keys.first;
                        final status =
                            downloadStatus[taskId] ??
                            DownloadTaskStatus.undefined;
                        if (status == DownloadTaskStatus.complete) {
                          // 下载完成，显示“稍后安装”和“立即安装”
                          return Row(
                            children: [
                              Expanded(
                                child: FaButton(
                                  text: '稍后安装',
                                  type: FaButtonType.outline,
                                  onPressed: () =>
                                      Get.back(closeOverlays: true),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: FaButton(
                                  text: '立即安装',
                                  onPressed: () => controller.installApk(),
                                ),
                              ),
                            ],
                          );
                        } else {
                          // 下载中，显示后台下载按钮
                          return FaButton(
                            text: '后台下载',
                            type: FaButtonType.outline,
                            onPressed: () => Get.back(closeOverlays: true),
                          );
                        }
                      },
                    ),
                  )
                else ...[
                  Expanded(
                    child: FaButton(
                      text: '暂不更新',
                      type: FaButtonType.outline,
                      onPressed: () {
                        controller.hideUpdateTip();
                        Get.back(closeOverlays: true);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FaButton(
                      text: '立即更新',
                      onPressed: () => controller.startUpdateDownload(),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      );
    });
  }
}
