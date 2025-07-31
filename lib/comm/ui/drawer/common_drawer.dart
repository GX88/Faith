import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../pages/home/controller/home_controller.dart';
import '../../../pages/nav/views/bottom_navigation_bar.dart';
import '../../../utils/update_utils.dart';

/// 全局侧边栏抽屉组件
class GlobalDrawer extends StatelessWidget {
  const GlobalDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.79, // 侧边栏宽度设置为屏幕宽度的75%
      child: Drawer(
        backgroundColor: const Color.fromARGB(255, 248, 250, 252),
        child: Stack(
          children: [
            // 简洁的渐变背景
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.3),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            // 主要内容 - 使用SafeArea包裹整个内容
            SafeArea(
              child: Column(
                children: [
                  // 头部区域 - 使用灵活高度
                  Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(color: Colors.transparent),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 用户头像
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color.fromRGBO(0, 0, 0, 0.08),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.person,
                              size: 28,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Faith App',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            '版本 1.0.3',
                            style: TextStyle(
                              color: Color.fromRGBO(0, 0, 0, 0.6),
                              fontSize: 13,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // 菜单项 - 使用Expanded确保不溢出
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: ListView(
                        padding: EdgeInsets.zero,
                        children: [
                          const SizedBox(height: 8),
                          // 导航菜单组
                          _buildMenuSection('导航', [
                            _buildDrawerItem(
                              context,
                              icon: Icons.home_outlined,
                              title: '首页',
                              onTap: () {
                                Navigator.pop(context);
                                final controller =
                                    Get.find<BottomNavController>();
                                controller.onTabTapped(0);
                              },
                            ),
                            _buildDrawerItem(
                              context,
                              icon: Icons.explore_outlined,
                              title: '探索',
                              onTap: () {
                                Navigator.pop(context);
                                final controller =
                                    Get.find<BottomNavController>();
                                controller.onTabTapped(1);
                              },
                            ),
                            _buildDrawerItem(
                              context,
                              icon: Icons.build_outlined,
                              title: '工具',
                              onTap: () {
                                Navigator.pop(context);
                                final controller =
                                    Get.find<BottomNavController>();
                                controller.onTabTapped(2);
                              },
                            ),
                            _buildDrawerItem(
                              context,
                              icon: Icons.settings_outlined,
                              title: '设置',
                              onTap: () {
                                Navigator.pop(context);
                                final controller =
                                    Get.find<BottomNavController>();
                                controller.onTabTapped(3);
                              },
                            ),
                          ]),
                          const SizedBox(height: 16),
                          // 功能菜单组
                          _buildMenuSection('功能', [
                            _buildDrawerItem(
                              context,
                              icon: Icons.update_outlined,
                              title: '检查更新',
                              onTap: () {
                                Navigator.pop(context);
                                try {
                                  final homeController =
                                      Get.find<HomeController>();
                                  homeController.manualCheckUpdate();
                                } catch (e) {
                                  // 如果HomeController不存在，直接调用更新方法
                                  AppUpdateTool.to.checkUpdate();
                                }
                              },
                            ),
                            _buildDrawerItem(
                              context,
                              icon: Icons.cleaning_services_outlined,
                              title: '清理缓存',
                              onTap: () async {
                                Navigator.pop(context);
                                final result = await AppUpdateTool.to
                                    .cleanDownloadDir();
                                if (result) {
                                  Get.snackbar('清理成功', 'Updates文件夹已删除');
                                } else {
                                  Get.snackbar('清理提示', 'Updates文件夹不存在或清理失败');
                                }
                              },
                            ),
                            _buildDrawerItem(
                              context,
                              icon: Icons.refresh_outlined,
                              title: '重置更新状态',
                              onTap: () {
                                Navigator.pop(context);
                                try {
                                  final homeController =
                                      Get.find<HomeController>();
                                  homeController.resetUpdateDialogState();
                                } catch (e) {
                                  Get.snackbar('提示', '重置更新状态失败');
                                }
                              },
                            ),
                          ]),
                        ],
                      ),
                    ),
                  ),
                  // 底部信息 - 减少padding避免溢出
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                    child: const Text(
                      '© 2024 Faith App',
                      style: TextStyle(
                        color: Color.fromRGBO(0, 0, 0, 0.4),
                        fontSize: 11,
                        letterSpacing: 0.3,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建菜单分组
  Widget _buildMenuSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: const TextStyle(
              color: Color.fromRGBO(0, 0, 0, 0.5),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
        // 平面设计，移除卡片样式
        Column(
          children: items.map((item) => 
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: item,
            )
          ).toList(),
        ),
      ],
    );
  }

  /// 构建侧边栏菜单项
  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
          child: Row(
            children: [
              // 简洁图标，无背景
              Icon(
                icon,
                size: 20,
                color: const Color.fromRGBO(0, 0, 0, 0.6),
              ),
              const SizedBox(width: 16),
              // 标题
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: Color.fromRGBO(0, 0, 0, 0.8),
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
