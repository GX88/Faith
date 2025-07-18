import 'package:faith/utils/status_bar_util.dart';
import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    setStatusBarStyle(bgColor: const Color(0xFFE3F2FD)); // 自动根据背景色
    return Scaffold(
      backgroundColor: const Color(0xFFE3F2FD), // 淡蓝色，主色调更明显
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
            bottom: false, // 禁用SafeArea的底部保护，让内容延伸到悬浮导航栏区域
            child: Padding(
              padding: const EdgeInsets.only(bottom: 100), // 添加底部内边距避免被悬浮导航栏遮挡
              child: Center(
                child: Text(
                  '首页',
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
