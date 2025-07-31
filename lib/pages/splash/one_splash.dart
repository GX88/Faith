import 'dart:ui';

import 'package:faith/router/index.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'controller/skip.dart';

class OneSplash extends StatelessWidget {
  const OneSplash({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<SkipController>(
      init: SkipController(
        initialCountdown: 5,
        initialShowSkip: true,
        targetRoute: RoutePath.home,
      ),
      builder: (controller) => Scaffold(
        body: Stack(
          clipBehavior: Clip.none,
          children: [
            // 背景图
            Positioned(
              width: MediaQuery.of(context).size.width * 1.7,
              left: 100,
              bottom: 100,
              child: Image.asset(
                "lib/assets/splash/Spline.png",
                alignment: Alignment.centerRight,
              ),
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
                    SizedBox(
                      width: MediaQuery.of(context).size.width,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Text(
                            "Faith",
                            style: TextStyle(
                              fontSize: 72,
                              fontWeight: FontWeight.w700,
                              height: 1.1,
                              letterSpacing: -2,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: const Color.fromRGBO(0, 0, 0, 0.06),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              "有风的地方就是方向",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 2,
                              ),
                            ),
                          ),
                          const SizedBox(height: 36),
                          const Text(
                            "生活中的每一个瞬间\n都值得被优雅地对待\n让科技融入生活\n让创意改变世界",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              height: 1.6,
                              letterSpacing: 0.8,
                              color: Color.fromRGBO(0, 0, 0, 0.45),
                            ),
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
              top: 60,
              right: 24,
              child: Obx(
                () => controller.showSkip.value
                    ? GestureDetector(
                        onTap: controller.skipToMain,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(20),
                          ),
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
