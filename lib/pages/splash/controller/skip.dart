import 'dart:async';

import 'package:faith/comm/services/update_service.dart';
import 'package:faith/config/config.default.dart';
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

  /// 跳转目标路由
  final String targetRoute;

  /// 跳转参数
  final Map<String, dynamic>? targetArguments;

  Future<void>? _updateFuture;
  bool _updateFinished = false;

  SkipController({
    this.initialCountdown = 5,
    this.beforeSkip,
    this.afterSkip,
    this.initialShowSkip = true,
    this.targetRoute = RoutePath.home,
    this.targetArguments,
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

  @override
  void onReady() {
    super.onReady();
    _checkUpdateWithTimeout();
  }

  void _checkUpdateWithTimeout() {
    final duration = Duration(seconds: initialCountdown);
    _updateFuture = Get.find<UpdateService>().init().then((_) {
      _updateFinished = true;
    });
    // 倒计时结束时，若还未完成则取消（实际Dio无法强制cancel，但可忽略结果）
    Future.delayed(duration, () {
      if (!_updateFinished) {
        // 这里可以设置一个标志位，后续请求结果忽略
        _updateFinished = true;
      }
    });
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
  void skipToMain() async {
    _timer?.cancel();

    // 执行跳转前回调
    beforeSkip?.call();

    // 判断是否开启登录认证
    if (Config.instance.loginAuthentication == true) {
      // 跳转到生物识别页面
      RouteHelper.replace(
        RoutePath.biometricAuth,
        arguments: {
          'canPop': false,
          'showBackButton': false,
          'nextRoute': targetRoute,
          'title': '登录验证',
          'description': '请完成登录验证后才可以继续使用',
        },
      );
    } else {
      // 未开启认证，直接跳转
      RouteHelper.replace(targetRoute, arguments: targetArguments);
    }

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
