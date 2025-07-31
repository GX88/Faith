import 'dart:io';

import 'package:faith/config/config.default.dart';
import 'package:faith/router/index.dart';
import 'package:faith/store/index.dart';
import 'package:faith/utils/update_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
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

    // 移除全局状态栏设置，让各个页面自己控制状态栏样式
  });
}

Future<void> _initializeApp() async {
  WidgetsFlutterBinding.ensureInitialized(); // 确保Flutter绑定初始化
  final packageInfo = await PackageInfo.fromPlatform(); // 获取 PackageInfo
  await initAllStores();

  // 初始化AppUpdateTool
  Get.put<AppUpdateTool>(AppUpdateTool());
  await AppUpdateTool.to.init();

  Get.put<PackageInfo>(packageInfo); // 注入 PackageInfo
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
            appBarTheme: const AppBarTheme(
              systemOverlayStyle: SystemUiOverlayStyle(
                statusBarColor: Color(0xFFE3F2FD), // 首页默认状态栏颜色
                statusBarIconBrightness: Brightness.dark, // 深色图标
              ),
            ),
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
