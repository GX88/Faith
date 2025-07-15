import 'package:faith/comm/ui/fa_button/index.dart';
import 'package:faith/router/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class UnknownPage extends StatelessWidget {
  const UnknownPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Spacer(flex: 2),
              // 使用RepaintBoundary优化重绘性能
              RepaintBoundary(
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.8,
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: SvgPicture.asset(
                      'lib/assets/unknown/404.svg',
                      fit: BoxFit.scaleDown,
                    ),
                  ),
                ),
              ),
              const Spacer(flex: 2),
              ErrorInfo(
                title: "迷失在太空中!",
                description: "您正在寻找的页面似乎缺失。请返回或访问主页。",
                btnText: "To主页",
                press: () => RouteHelper.pushAndRemoveUntil(RoutePath.home),
              ),
              FaButton(
                onPressed: () => RouteHelper.pop(),
                text: "返回",
                block: true,
                type: FaButtonType.danger,
              ),
              const SizedBox(height: 16), // 底部安全间距
            ],
          ),
        ),
      ),
    );
  }
}

class ErrorInfo extends StatelessWidget {
  const ErrorInfo({
    super.key,
    required this.title,
    required this.description,
    this.button,
    this.btnText,
    required this.press,
  });

  final String title;
  final String description;
  final Widget? button;
  final String? btnText;
  final VoidCallback press;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        alignment: Alignment.center,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              description,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 40),
            button ??
                FaButton(
                  onPressed: press,
                  text: btnText ?? "重试",
                  block: true,
                  type: FaButtonType.primary,
                ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
