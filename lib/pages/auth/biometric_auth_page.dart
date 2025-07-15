import 'package:faith/router/index.dart';
import 'package:faith/utils/biometric_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BiometricAuthPage extends StatefulWidget {
  const BiometricAuthPage({
    super.key,
    this.canPop = true, // 是否允许返回，默认允许
    this.showBackButton = true, // 是否显示返回按钮，默认显示
    this.onAuthSuccess, // 认证成功的回调
    this.nextRoute = RoutePath.home, // 下一个路由，默认是首页
    this.title = '生物识别验证', // 标题文字
    this.description, // 描述文字
  });

  final bool canPop; // 控制是否可以返回
  final bool showBackButton; // 控制是否显示返回按钮
  final Function()? onAuthSuccess; // 认证成功后的回调
  final String nextRoute; // 认证成功后跳转的路由
  final String title; // 标题文字
  final String? description; // 描述文字

  @override
  State<BiometricAuthPage> createState() => _BiometricAuthPageState();
}

class _BiometricAuthPageState extends State<BiometricAuthPage> {
  bool _isUnlocked = false;
  bool _hasAttemptedPop = false; // 添加状态标记是否尝试过返回

  @override
  void initState() {
    super.initState();
    // 设置状态栏样式
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
  }

  // 处理返回尝试
  void _handlePopAttempt() {
    if (!widget.canPop && !_hasAttemptedPop) {
      setState(() => _hasAttemptedPop = true);
      // 2秒后重置状态
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() => _hasAttemptedPop = false);
        }
      });
    }
  }

  Future<void> _authenticate(BuildContext context) async {
    final biometricAuth = BiometricAuth();
    final result = await biometricAuth.authenticate(
      localizedReason: '请验证指纹以继续',
    );

    if (context.mounted) {
      if (result.success) {
        setState(() => _isUnlocked = true);
        // 增加等待时间到 1 秒，让用户能够看清图标变化
        await Future.delayed(const Duration(seconds: 1));
        if (context.mounted) {
          // 如果有自定义回调，则执行回调
          if (widget.onAuthSuccess != null) {
            widget.onAuthSuccess!();
          } else if (widget.nextRoute.isNotEmpty) {
            // 只有在nextRoute不为空时才执行路由跳转
            RouteHelper.pushAndRemoveUntil(widget.nextRoute);
          }
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message, style: const TextStyle(fontSize: 13)),
            backgroundColor: Colors.black87,
            behavior: SnackBarBehavior.floating,
            width: 280,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: widget.canPop,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (!didPop) {
          setState(() => _hasAttemptedPop = true);
          // 2秒后重置状态
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              setState(() => _hasAttemptedPop = false);
            }
          });
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: false, // 禁用自动添加返回按钮
          leading: widget.showBackButton && widget.canPop
              ? IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black),
                  onPressed: () => Navigator.of(context).pop(),
                )
              : const SizedBox(), // 使用空白占位
          systemOverlayStyle: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
          ),
        ),
        extendBodyBehindAppBar: true, // 允许内容延伸到AppBar下面
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 60),
                  // 锁图标
                  Center(
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color.fromRGBO(0, 0, 0, 0.08),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Icon(
                        _isUnlocked ? Icons.lock_open : Icons.lock,
                        size: 30,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  // 文字区域
                  Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.description ??
                        (widget.canPop ? '点击下方图标进行指纹验证' : '请完成指纹验证以继续'),
                    style: TextStyle(
                      fontSize: 14,
                      color: _hasAttemptedPop
                          ? const Color.fromRGBO(255, 0, 0, 0.7)
                          : const Color.fromRGBO(0, 0, 0, 0.6),
                      height: 1.4,
                      letterSpacing: 0.3,
                    ),
                  ),
                  Expanded(flex: 4, child: Container()),
                  // 指纹图标
                  Center(
                    child: GestureDetector(
                      onTap: () => _authenticate(context),
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.fingerprint,
                          size: 56,
                          color: Color.fromRGBO(0, 0, 0, 0.4),
                        ),
                      ),
                    ),
                  ),
                  Expanded(flex: 2, child: Container()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
 