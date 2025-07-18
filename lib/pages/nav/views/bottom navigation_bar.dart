import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';

import '../../explore/views/index.dart';
import '../../home/views/index.dart';
import '../../settings/views/index.dart';
import '../../tools/views/index.dart';

/// 底部导航栏控制器
class BottomNavController extends GetxController {
  // 当前选中的索引
  final RxInt selectedIndex = 0.obs;

  // 页面列表
  final List<Widget> pages = const [
    HomePage(),
    ExplorePage(),
    ToolsPage(),
    SettingsPage(),
  ];

  void onTabTapped(int index) {
    selectedIndex.value = index;
  }
}

/// 底部导航栏页面
class BottomNavigationBarPage extends StatefulWidget {
  const BottomNavigationBarPage({super.key});

  @override
  State<BottomNavigationBarPage> createState() =>
      _BottomNavigationBarPageState();
}

class _BottomNavigationBarPageState extends State<BottomNavigationBarPage>
    with TickerProviderStateMixin {
  final BottomNavController controller = Get.put(BottomNavController());
  late final AnimationController lottieController;
  late final AnimationController toolLottieController;
  late final AnimationController settingLottieController;
  late final AnimationController exploreLottieController;

  @override
  void initState() {
    super.initState();
    // 初始化首页tab的Lottie动画控制器
    lottieController = AnimationController(vsync: this);
    // 初始化工具tab的Lottie动画控制器
    toolLottieController = AnimationController(vsync: this);
    // 初始化设置tab的Lottie动画控制器
    settingLottieController = AnimationController(vsync: this);
    // 初始化探索tab的Lottie动画控制器
    exploreLottieController = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    lottieController.dispose();
    toolLottieController.dispose();
    settingLottieController.dispose();
    exploreLottieController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    // 页面立即切换
    controller.onTabTapped(index);
    // 如果点击首页tab，播放一次动画
    if (index == 0) {
      lottieController
        ..reset()
        ..forward();
      // 切换到首页时，工具动画回到第一帧
      toolLottieController.reset();
    } else if (index == 1) {
      // 点击探索tab，播放一次动画
      exploreLottieController
        ..reset()
        ..forward();
      // 切换到探索时，其它动画回到第一帧
      lottieController.reset();
      toolLottieController.reset();
      settingLottieController.reset();
    } else if (index == 2) {
      // 点击工具tab，播放一次动画
      toolLottieController
        ..reset()
        ..forward();
      // 切换到工具时，首页动画回到第一帧
      lottieController.reset();
    } else if (index == 3) {
      // 点击设置tab，播放一次动画
      settingLottieController
        ..reset()
        ..forward();
      // 切换到设置时，首页和工具动画回到第一帧
      lottieController.reset();
      toolLottieController.reset();
    } else {
      // 其它tab，所有动画都回到第一帧
      lottieController.reset();
      toolLottieController.reset();
      settingLottieController.reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // 保证首页tab的Lottie动画在未选中时显示第一帧，选中时显示最后一帧（除非正在播放）
      if (controller.selectedIndex.value == 0) {
        if (!lottieController.isAnimating && lottieController.value != 1.0) {
          lottieController.value = 1.0;
        }
        if (toolLottieController.value != 0.0) {
          toolLottieController.value = 0.0;
        }
      } else if (controller.selectedIndex.value == 2) {
        if (!toolLottieController.isAnimating &&
            toolLottieController.value != 1.0) {
          toolLottieController.value = 1.0;
        }
        if (lottieController.value != 0.0) {
          lottieController.value = 0.0;
        }
      } else if (controller.selectedIndex.value == 3) {
        if (!settingLottieController.isAnimating &&
            settingLottieController.value != 1.0) {
          settingLottieController.value = 1.0;
        }
        if (lottieController.value != 0.0) {
          lottieController.value = 0.0;
        }
        if (toolLottieController.value != 0.0) {
          toolLottieController.value = 0.0;
        }
      } else if (controller.selectedIndex.value == 1) {
        if (!exploreLottieController.isAnimating &&
            exploreLottieController.value != 1.0) {
          exploreLottieController.value = 1.0;
        }
        if (lottieController.value != 0.0) {
          lottieController.value = 0.0;
        }
        if (toolLottieController.value != 0.0) {
          toolLottieController.value = 0.0;
        }
        if (settingLottieController.value != 0.0) {
          settingLottieController.value = 0.0;
        }
      } else {
        if (lottieController.value != 0.0) {
          lottieController.value = 0.0;
        }
        if (toolLottieController.value != 0.0) {
          toolLottieController.value = 0.0;
        }
        if (settingLottieController.value != 0.0) {
          settingLottieController.value = 0.0;
        }
      }
      return Scaffold(
        body: controller.pages[controller.selectedIndex.value],
        bottomNavigationBar: SizedBox(
          height: 60,
          child: Theme(
            data: Theme.of(context).copyWith(
              splashColor: Colors.transparent, // 去除水波纹
              highlightColor: Colors.transparent, // 去除高亮
              splashFactory: NoSplash.splashFactory, // 禁用所有点击动画
            ),
            child: BottomNavigationBar(
              currentIndex: controller.selectedIndex.value,
              onTap: _onTabTapped, // 使用自定义点击逻辑
              type: BottomNavigationBarType.fixed,
              selectedItemColor: Colors.black, // 选中为黑色
              unselectedItemColor: Colors.grey, // 未选中为灰色
              items: [
                BottomNavigationBarItem(
                  // 首页tab使用Lottie动画，点击时播放一次
                  icon: Padding(
                    padding: EdgeInsets.only(bottom: 4),
                    child: Lottie.asset(
                      'lib/assets/bottom_navigation/home.json',
                      width: 26,
                      height: 26,
                      controller: lottieController,
                      onLoaded: (composition) {
                        lottieController.duration = composition.duration;
                      },
                      repeat: false,
                    ),
                  ),
                  label: '首页',
                ),
                BottomNavigationBarItem(
                  // 探索tab使用Lottie动画，点击时播放一次
                  icon: Padding(
                    padding: EdgeInsets.only(bottom: 4),
                    child: Lottie.asset(
                      'lib/assets/bottom_navigation/explore.json',
                      width: 26,
                      height: 26,
                      controller: exploreLottieController,
                      onLoaded: (composition) {
                        exploreLottieController.duration = composition.duration;
                      },
                      repeat: false,
                    ),
                  ),
                  label: '探索',
                ),
                BottomNavigationBarItem(
                  // 工具tab使用Lottie动画，点击时播放一次
                  icon: Padding(
                    padding: EdgeInsets.only(bottom: 4),
                    child: Lottie.asset(
                      'lib/assets/bottom_navigation/tool.json',
                      width: 26,
                      height: 26,
                      controller: toolLottieController,
                      onLoaded: (composition) {
                        toolLottieController.duration = composition.duration;
                      },
                      repeat: false,
                    ),
                  ),
                  label: '工具',
                ),
                BottomNavigationBarItem(
                  // 设置tab使用Lottie动画，点击时播放一次
                  icon: Padding(
                    padding: EdgeInsets.only(bottom: 4),
                    child: Lottie.asset(
                      'lib/assets/bottom_navigation/setting.json',
                      width: 26,
                      height: 26,
                      controller: settingLottieController,
                      onLoaded: (composition) {
                        settingLottieController.duration = composition.duration;
                      },
                      repeat: false,
                    ),
                  ),
                  label: '设置',
                ),
              ],
              selectedFontSize: 10,
              unselectedFontSize: 10,
              showUnselectedLabels: true,
              elevation: 0,
              backgroundColor: Colors.white,
            ),
          ),
        ),
      );
    });
  }
}
