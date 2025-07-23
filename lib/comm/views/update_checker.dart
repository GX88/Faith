import 'package:faith/utils/update_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:get/get.dart';

import '../controller/update_controller.dart';

class UpdateChecker extends GetView<UpdateController> {
  final RemoteVersion remote;
  const UpdateChecker(this.remote, {super.key});

  @override
  Widget build(BuildContext context) {
    // 创建控制器并注入
    Get.put(UpdateController(remote));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Obx(() {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '发现新版本 ${controller.remote.tag}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (controller.errorMsg.value.isNotEmpty)
              Text(
                controller.errorMsg.value,
                style: const TextStyle(color: Colors.red),
              ),
            const SizedBox(height: 12),
            if (controller.taskId.value.isEmpty)
              ElevatedButton(
                onPressed: controller.onUpdate,
                child: const Text('立即更新'),
              )
            else if (controller.status.value == DownloadTaskStatus.running)
              LinearProgressIndicator(value: controller.progress.value / 100)
            else if (controller.status.value == DownloadTaskStatus.complete)
              ElevatedButton(
                onPressed: controller.onInstall,
                child: const Text('立即安装'),
              )
            else
              ElevatedButton(
                onPressed: controller.onUpdate,
                child: const Text('重试'),
              ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: controller.onClose,
              child: const Text('以后再说'),
            ),
          ],
        );
      }),
    );
  }
}
