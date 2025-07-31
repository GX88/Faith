import 'package:faith/pages/auth/biometric_auth_page.dart';
import 'package:faith/pages/nav/views/bottom_navigation_bar.dart';
import 'package:faith/pages/splash/one_splash.dart';
import 'package:faith/pages/unknown/index.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// 路由名称管理
abstract class RoutePath {
  // 启动页
  static const String splash = '/splash';
  static const String oneSplash = '/one_splash';

  // 认证页面
  static const String biometricAuth = '/auth/biometric';

  // 主页面
  static const String home = '/home';

  // 示例：其他页面路由
  static const String profile = '/profile';
  // static const String settings = '/settings';
  // static const String detail = '/detail';
}

/// 自定义路由页面，统一配置路由页面的通用属性
class CustomGetPage extends GetPage {
  final bool? fullscreen;

  CustomGetPage({
    required super.name,
    required super.page,
    super.binding,
    this.fullscreen,
    super.transitionDuration,
    super.customTransition,
    bool? preventDuplicates,
    Transition super.transition = Transition.native,
  }) : super(
         preventDuplicates: preventDuplicates ?? false,
         curve: Curves.linear,
         showCupertinoParallax: false,
         popGesture: false,
         fullscreenDialog: fullscreen ?? false,
       );
}

/// 路由页面配置
class AppPages {
  static final List<GetPage> pages = [
    // 启动页
    CustomGetPage(
      name: RoutePath.oneSplash,
      page: () => const OneSplash(),
      transition: Transition.fade,
      preventDuplicates: true,
    ),

    // 主页
    CustomGetPage(
      name: RoutePath.home,
      page: () => BottomNavigationBarPage(),
      transition: Transition.fadeIn,
      preventDuplicates: true,
    ),

    // 生物识别认证页面
    CustomGetPage(
      name: RoutePath.biometricAuth,
      page: () {
        final arguments = Get.arguments as Map<String, dynamic>?;
        return BiometricAuthPage(
          canPop: arguments?['canPop'] ?? true,
          showBackButton: arguments?['showBackButton'] ?? true, // 默认显示返回按钮
          title: arguments?['title'] ?? '生物识别验证',
          description: arguments?['description'],
          nextRoute: arguments?['nextRoute'] ?? RoutePath.home,
          onAuthSuccess: arguments?['onAuthSuccess'],
        );
      },
      transition: Transition.fadeIn,
      preventDuplicates: true,
    ),
  ];

  /// 初始路由
  static const initial = RoutePath.oneSplash; // 修改初始路由为启动页

  /// 未知路由
  static final unknownRoute = CustomGetPage(
    name: '/not-found',
    page: () => const UnknownPage(),
    preventDuplicates: true,
  );
}

/// 路由工具类
class RouteHelper {
  /// 跳转到指定页面
  static void push(String routeName, {dynamic arguments}) {
    Get.toNamed(routeName, arguments: arguments);
  }

  /// 替换当前页面
  static void replace(String routeName, {dynamic arguments}) {
    Get.offNamed(routeName, arguments: arguments);
  }

  /// 清空所有页面并跳转到指定页面
  static void pushAndRemoveUntil(String routeName, {dynamic arguments}) {
    Get.offAllNamed(routeName, arguments: arguments);
  }

  /// 返回上一页
  static void pop([dynamic result]) {
    Get.back(result: result);
  }

  /// 返回到指定页面
  static void popUntil(String routeName) {
    Get.until((route) => route.settings.name == routeName);
  }
}
