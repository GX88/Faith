import 'dart:io';

import 'package:faith/comm/services/update_service.dart';
import 'package:faith/config/config.default.dart';
import 'package:faith/router/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

Future<void> main() async {
  await _initializeApp();

  /// 自定义报错界面
  ErrorWidget.builder = (FlutterErrorDetails flutterErrorDetails) {
    debugPrint(flutterErrorDetails.toString());

    return const Material(
      child: Center(
        child: Text("发生了没有处理的错误\n请通知开发者", textAlign: TextAlign.center),
      ),
    );
  };

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]).then((_) async {
    runApp(const MainAppPage());

    /**
     *  SystemUiMode.edgeToEdge: 显示状态栏
     *  SystemUiMode.immersiveSticky: 不显示状态栏
     */
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    /// 设置状态栏样式 Android
    if (GetPlatform.isAndroid) {
      const SystemUiOverlayStyle systemUiOverlayStyle = SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarBrightness: Brightness.dark,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
      );
      SystemChrome.setSystemUIOverlayStyle(systemUiOverlayStyle);
    }

    /// 设置状态栏样式 iOS
    if (GetPlatform.isIOS) {
      const SystemUiOverlayStyle dark = SystemUiOverlayStyle(
        systemNavigationBarColor: Color(0xFF000000),
        systemNavigationBarIconBrightness: Brightness.light,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      );
      SystemChrome.setSystemUIOverlayStyle(dark);
    }
  });
}

Future<void> _initializeApp() async {
  // 确保Flutter绑定初始化
  WidgetsFlutterBinding.ensureInitialized();
  // 注入 PackageInfo
  final packageInfo = await PackageInfo.fromPlatform();
  Get.put<PackageInfo>(packageInfo);
  // 初始化下载器
  await FlutterDownloader.initialize();
  // 只put服务，不await检查更新
  Get.put(UpdateService());

  // 初始化配置
  // 这里不需要显式调用 Config.instance，因为第一次访问时会自动初始化
  // 但我们可以提前访问一次，确保配置在应用启动时就已经准备好
  debugPrint('当前环境: ${Config.isProd ? '生产环境' : '开发环境'}');
  debugPrint('API地址: ${Config.instance.apiBaseUrl}');
}

class MainAppPage extends StatelessWidget {
  const MainAppPage({super.key});

  @override
  Widget build(BuildContext context) {
    // 强制设置高帧率
    if (Platform.isAndroid) {
      try {
        late List modes;
        FlutterDisplayMode.supported.then((value) {
          modes = value;
          DisplayMode f = DisplayMode.auto;
          DisplayMode preferred = modes.toList().firstWhere((el) => el == f);
          FlutterDisplayMode.setPreferredMode(preferred);
        });
      } catch (_) {}
    }

    return ScreenUtilInit(
      designSize: const Size(414, 812), // 设计稿尺寸
      minTextAdapt: true, // 最小字体适配
      splitScreenMode: true, // 横屏适配
      child: RefreshConfiguration(
        headerBuilder: () => const MaterialClassicHeader(
          color: Colors.blue,
          backgroundColor: Colors.transparent,
        ),
        child: GetMaterialApp(
          debugShowCheckedModeBanner: false, // 隐藏调试标志
          title: Config.instance.appName,
          initialRoute: AppPages.initial,
          getPages: AppPages.pages,
          unknownRoute: AppPages.unknownRoute,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF000000), // 使用黑色作为主色调
              primary: const Color(0xFF000000),
              secondary: const Color(0xFF666666),
              error: const Color(0xFFDC3545),
            ),
            useMaterial3: true, // 使用 Material 3
          ),
          builder: (context, child) {
            return Stack(
              children: [
                child!,
                if (context.isDarkMode)
                  IgnorePointer(child: Container(color: Colors.black12)),
              ],
            );
          },
        ),
      ),
    );
  }
}
