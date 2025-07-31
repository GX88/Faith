import 'package:animations/animations.dart';
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
  int _lastIndex = 0;

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
    setState(() {
      _lastIndex = controller.selectedIndex.value;
    });
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
        extendBody: true, // 允许内容延伸到bottomNavigationBar区域
        body: Stack(
          children: [
            // 页面内容
            Positioned.fill(
              child: PageTransitionSwitcher(
                duration: Duration(milliseconds: 350),
                transitionBuilder: (child, animation, secondaryAnimation) {
                  final isForward = controller.selectedIndex.value > _lastIndex;
                  final enterOffset = isForward
                      ? Offset(1.0, 0.0)
                      : Offset(-1.0, 0.0);
                  final exitOffset = isForward
                      ? Offset(-1.0, 0.0)
                      : Offset(1.0, 0.0);
                  return SlideTransition(
                    position: animation.drive(
                      Tween<Offset>(
                        begin: enterOffset,
                        end: Offset.zero,
                      ).chain(CurveTween(curve: Curves.easeOutCubic)),
                    ),
                    child: SlideTransition(
                      position: secondaryAnimation.drive(
                        Tween<Offset>(
                          begin: Offset.zero,
                          end: exitOffset,
                        ).chain(CurveTween(curve: Curves.easeOutCubic)),
                      ),
                      child: child,
                    ),
                  );
                },
                child: KeyedSubtree(
                  key: ValueKey(controller.selectedIndex.value),
                  child: controller.pages[controller.selectedIndex.value],
                ),
              ),
            ),
            // 悬浮底部导航栏
            Positioned(
              left: 16,
              right: 16,
              bottom: 20,
              child: SafeArea(
                top: false,
                child: Container(
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Theme(
                    data: Theme.of(context).copyWith(
                      splashColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      splashFactory: NoSplash.splashFactory,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: BottomNavigationBar(
                        currentIndex: controller.selectedIndex.value,
                        onTap: _onTabTapped,
                        type: BottomNavigationBarType.fixed,
                        selectedItemColor: Colors.black,
                        unselectedItemColor: Colors.grey,
                        elevation: 0,
                        backgroundColor: Colors.transparent,
                        items: [
                          BottomNavigationBarItem(
                            icon: Padding(
                              padding: EdgeInsets.only(bottom: 4),
                              child: Lottie.asset(
                                'lib/assets/bottom_navigation/home.json',
                                width: 26,
                                height: 26,
                                controller: lottieController,
                                onLoaded: (composition) {
                                  lottieController.duration =
                                      composition.duration;
                                },
                                repeat: false,
                              ),
                            ),
                            label: '首页',
                          ),
                          BottomNavigationBarItem(
                            icon: Padding(
                              padding: EdgeInsets.only(bottom: 4),
                              child: Lottie.asset(
                                'lib/assets/bottom_navigation/explore.json',
                                width: 26,
                                height: 26,
                                controller: exploreLottieController,
                                onLoaded: (composition) {
                                  exploreLottieController.duration =
                                      composition.duration;
                                },
                                repeat: false,
                              ),
                            ),
                            label: '探索',
                          ),
                          BottomNavigationBarItem(
                            icon: Padding(
                              padding: EdgeInsets.only(bottom: 4),
                              child: Lottie.asset(
                                'lib/assets/bottom_navigation/tool.json',
                                width: 26,
                                height: 26,
                                controller: toolLottieController,
                                onLoaded: (composition) {
                                  toolLottieController.duration =
                                      composition.duration;
                                },
                                repeat: false,
                              ),
                            ),
                            label: '工具',
                          ),
                          BottomNavigationBarItem(
                            icon: Padding(
                              padding: EdgeInsets.only(bottom: 4),
                              child: Lottie.asset(
                                'lib/assets/bottom_navigation/setting.json',
                                width: 26,
                                height: 26,
                                controller: settingLottieController,
                                onLoaded: (composition) {
                                  settingLottieController.duration =
                                      composition.duration;
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
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}
