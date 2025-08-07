import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../utils/smart_status_bar.dart';
import '../../nav/views/bottom_navigation_bar.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SmartStatusBarMixin {
  /// 构建功能卡片 - shadcn风格的简洁设计
  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDisabled = false,
  }) {
    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 图标
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isDisabled
                    ? const Color(0xFFF3F4F6)
                    : const Color(0xFF111827),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: isDisabled ? const Color(0xFF9CA3AF) : Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(height: 16),
            // 标题
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDisabled
                    ? const Color(0xFF9CA3AF)
                    : const Color(0xFF111827),
                height: 1.2,
              ),
            ),
            const SizedBox(height: 4),
            // 副标题
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: isDisabled
                    ? const Color(0xFFD1D5DB)
                    : const Color(0xFF6B7280),
                fontWeight: FontWeight.w400,
                height: 1.3,
              ),
            ),
            const Spacer(),
            // 箭头图标
            if (!isDisabled)
              Align(
                alignment: Alignment.centerRight,
                child: Icon(
                  Icons.arrow_forward,
                  size: 20,
                  color: const Color(0xFF6B7280),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: pageKey,
      child: Scaffold(
        backgroundColor: const Color(0xFFFAFAFA), // 浅灰色背景
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 顶部菜单按钮
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.menu,
                        color: Color(0xFF111827),
                        size: 24,
                      ),
                      onPressed: () {
                        // 使用全局Scaffold的Key来打开侧边栏
                        globalScaffoldKey.currentState?.openDrawer();
                      },
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: const BorderSide(
                            color: Color(0xFFE5E7EB),
                            width: 1,
                          ),
                        ),
                        padding: const EdgeInsets.all(12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                // 欢迎标题
                const Text(
                  'Faith',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '您的安全工具箱',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 48),
                // 功能卡片网格
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.9,
                    children: [
                      _buildFeatureCard(
                        icon: Icons.security,
                        title: '双因子认证',
                        subtitle: '管理您的2FA账户',
                        onTap: () => Get.toNamed('/2fa'),
                      ),
                      _buildFeatureCard(
                        icon: Icons.construction,
                        title: '更多功能',
                        subtitle: '敬请期待',
                        onTap: () {},
                        isDisabled: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
