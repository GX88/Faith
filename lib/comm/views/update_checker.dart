import 'package:faith/utils/update_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:get/get.dart';

import '../controller/update_controller.dart';
import '../ui/fa_bottom_sheet/index.dart';
import '../ui/fa_button/index.dart';

class UpdateChecker extends GetView<UpdateController> {
  final RemoteVersion remote;
  const UpdateChecker(this.remote, {super.key});

  /// 静态方法，弹出底部弹窗显示更新内容
  static Future<void> show(RemoteVersion remote) {
    return FaBottomSheet.show(
      child: UpdateChecker(remote),
      backgroundColor: Colors.white,
      borderRadius: 20,
      elevation: 12,
      padding: const EdgeInsets.all(24),
      isDismissible: true, // 明确允许点击遮罩关闭
    );
  }

  @override
  Widget build(BuildContext context) {
    // 创建控制器并注入
    Get.put(UpdateController(remote));

    return Obx(() {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            '发现新版本 ${controller.remote.tag}',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
          if (controller.remote.body != null &&
              controller.remote.body!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 12),
              child: Text(
                controller.remote.body!,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  height: 1.5,
                ),
                textAlign: TextAlign.left,
              ),
            ),
          const SizedBox(height: 12),
          if (controller.errorMsg.value.isNotEmpty)
            Text(
              controller.errorMsg.value,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
          const SizedBox(height: 12),
          if (controller.taskId.value.isEmpty)
            FaButton(onPressed: controller.onUpdate, text: '立即更新')
          else if (controller.status.value == DownloadTaskStatus.running)
            LinearProgressIndicator(value: controller.progress.value / 100)
          else if (controller.status.value == DownloadTaskStatus.complete)
            FaButton(onPressed: controller.onInstall, text: '立即安装')
          else
            FaButton(
              onPressed: controller.onUpdate,
              text: '重试',
              type: FaButtonType.outline,
            ),
          const SizedBox(height: 8),
          FaButton(
            onPressed: controller.onClose,
            text: '以后再说',
            type: FaButtonType.text,
          ),
        ],
      );
    });
  }
}
