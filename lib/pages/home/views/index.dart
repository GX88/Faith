import 'package:faith/comm/services/update_service.dart';
import 'package:faith/comm/ui/fa_bottom_sheet/index.dart';
import 'package:faith/comm/views/update_checker.dart';
import 'package:faith/utils/status_bar_util.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final DownloadService _downloadService = DownloadService.to;

  @override
  void initState() {
    super.initState();
    // 配置底部弹层行为
    FaBottomSheetConfig.updateConfig(
      allowDismissible: true,
      allowDrag: true,
      backdropOpacity: 0.5,
      animationDuration: const Duration(milliseconds: 300),
    );
    // 在页面加载后检查更新状态
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkUpdateStatus();
    });
  }

  // 检查更新状态并显示底部弹层
  void _checkUpdateStatus() async {
    if (_downloadService.needUpdate()) {
      await FaBottomSheet.show(
        showDragHandle: true,
        backgroundColor: const Color.fromARGB(255, 228, 228, 228),
        onDismiss: () {
          if (_downloadService.downloadProgress.isEmpty) {
            _downloadService.hideUpdateTip();
          }
        },
        child: const UpdateChecker(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    setStatusBarStyle(bgColor: const Color(0xFFE3F2FD)); // 自动根据背景色
    return Scaffold(
      backgroundColor: const Color(0xFFE3F2FD), // 淡蓝色，主色调更明显
      extendBodyBehindAppBar: true,
      extendBody: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.system_update),
            onPressed: () async {
              await _downloadService.checkUpdate();
              _checkUpdateStatus();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // 背景装饰
          Positioned(
            top: -70,
            right: -50,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                color: const Color.fromRGBO(0, 0, 0, 0.02),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -60,
            left: -60,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                color: const Color.fromRGBO(0, 0, 0, 0.02),
                shape: BoxShape.circle,
              ),
            ),
          ),
          // 主要内容
          const Center(
            child: Text(
              '首页',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
