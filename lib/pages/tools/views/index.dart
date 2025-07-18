import 'package:faith/utils/status_bar_util.dart';
import 'package:flutter/material.dart';

class ToolsPage extends StatelessWidget {
  const ToolsPage({super.key});

  @override
  Widget build(BuildContext context) {
    setStatusBarStyle(force: Brightness.light); // 强制白色内容
    return Scaffold(
      backgroundColor: const Color(0xFFFFF9C4), // 淡黄色，主色调更明显
      extendBodyBehindAppBar: true,
      extendBody: true,
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
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 100),
              child: Center(
                child: Text(
                  '工具',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
