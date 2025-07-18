import 'package:faith/utils/status_bar_util.dart';
import 'package:flutter/material.dart';

class ExplorePage extends StatelessWidget {
  const ExplorePage({super.key});

  @override
  Widget build(BuildContext context) {
    setStatusBarStyle(force: Brightness.dark); // 强制白色内容
    return Scaffold(
      backgroundColor: const Color(0xFFE8F5E9), // 淡绿色，主色调更明显
      extendBodyBehindAppBar: true,
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
            child: Center(
              child: Text(
                '探索',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
