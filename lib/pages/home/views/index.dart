import 'package:faith/comm/update/update_service.dart';
import 'package:faith/utils/status_bar_util.dart';
import 'package:faith/utils/update_util.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../controller/home_controller.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final HomeController _controller;
  String? _localVersion;
  String? _remoteVersion;
  RemoteVersion? _remoteDetail;

  @override
  void initState() {
    super.initState();
    _controller = Get.put(HomeController());
    _initVersions();
  }

  Future<void> _initVersions() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _localVersion = info.version;
      final remote = Get.find<UpdateService>().latest.value;
      _remoteVersion = remote?.tag;
      _remoteDetail = remote;
    });
  }

  @override
  void dispose() {
    Get.delete<HomeController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    setStatusBarStyle(bgColor: const Color(0xFFE3F2FD)); // 自动根据背景色
    return Scaffold(
      backgroundColor: const Color(0xFFE3F2FD), // 淡蓝色，主色调更明显
      extendBodyBehindAppBar: true,
      extendBody: true,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
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
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  '首页',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => _controller.forceCheckUpdate(),
                  child: const Text('手动检查更新'),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () async {
                    final result = await AppUpdateTool.cleanUpdatesFolder();
                    if (result) {
                      Get.snackbar('清理成功', 'Updates文件夹已删除');
                    } else {
                      Get.snackbar('清理提示', 'Updates文件夹不存在或清理失败');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('清理更新缓存'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
