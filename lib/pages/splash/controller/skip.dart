import 'dart:async';

import 'package:faith/router/index.dart';
import 'package:get/get.dart';

/// 启动页跳过控制器
class SkipController extends GetxController {
  /// 倒计时秒数
  late final RxInt countdown;

  /// 定时器
  Timer? _timer;

  /// 是否显示跳过按钮
  late final RxBool showSkip;

  /// 初始倒计时时间（秒）
  final int initialCountdown;

  /// 跳转前的回调函数
  final Function()? beforeSkip;

  /// 跳转后的回调函数
  final Function()? afterSkip;

  /// 是否显示跳过按钮
  final bool initialShowSkip;

  SkipController({
    this.initialCountdown = 5,
    this.beforeSkip,
    this.afterSkip,
    this.initialShowSkip = true,
  }) {
    countdown = initialCountdown.obs;
    showSkip = initialShowSkip.obs;
  }

  @override
  void onInit() {
    super.onInit();
    startCountdown();
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }

  /// 开始倒计时
  void startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (countdown.value > 0) {
        countdown.value--;
      } else {
        skipToMain();
      }
    });
  }

  /// 跳转到目标页面
  void skipToMain() {
    _timer?.cancel();

    // 执行跳转前回调
    beforeSkip?.call();

    // 跳转到生物识别页面，允许返回但不显示返回按钮
    RouteHelper.replace(
      RoutePath.biometricAuth,
      arguments: {
        'canPop': true,
        'showBackButton': false,
        'title': '身份验证',
        'description': '请完成指纹验证以继续使用',
      },
    );

    // 执行跳转后回调
    afterSkip?.call();
  }

  /// 暂停倒计时
  void pauseCountdown() {
    _timer?.cancel();
  }

  /// 恢复倒计时
  void resumeCountdown() {
    if (_timer == null || !_timer!.isActive) {
      startCountdown();
    }
  }

  /// 设置是否显示跳过按钮
  void setSkipVisible(bool visible) {
    showSkip.value = visible;
  }

  /// 重置倒计时
  void resetCountdown([int? seconds]) {
    countdown.value = seconds ?? initialCountdown;
    _timer?.cancel();
    startCountdown();
  }
}
