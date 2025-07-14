import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'controller/skip.dart';

class OneSplash extends StatelessWidget {
  const OneSplash({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<SkipController>(
      init: SkipController(initialCountdown: 5, initialShowSkip: true),
      builder: (controller) => Scaffold(
        body: Stack(
          children: [
            // 背景图
            Positioned(
              width: MediaQuery.of(context).size.width * 1.7,
              left: 100,
              bottom: 100,
              child: Image.asset("lib/assets/splash/Spline.png"),
            ),
            // 模糊效果
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: const SizedBox(),
              ),
            ),
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                child: const SizedBox(),
              ),
            ),
            // 内容
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  children: [
                    const Spacer(),
                    const SizedBox(
                      width: 360,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "欢迎使用 Faith App",
                            style: TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              height: 1.2,
                            ),
                          ),
                          SizedBox(height: 16),
                          Text(
                            "Don't skip design. Learn design and code, by building real apps with Flutter and Swift. Complete courses about the best tools.",
                          ),
                        ],
                      ),
                    ),
                    const Spacer(flex: 2),
                  ],
                ),
              ),
            ),
            // 跳过按钮
            Positioned(
              top: 40,
              right: 32,
              child: Obx(
                () => controller.showSkip.value
                    ? Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: GestureDetector(
                          onTap: controller.skipToMain,
                          child: Text(
                            '跳过 ${controller.countdown.value}s',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      )
                    : const SizedBox(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
