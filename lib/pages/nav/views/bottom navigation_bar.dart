import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

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
class BottomNavigationBarPage extends StatelessWidget {
  BottomNavigationBarPage({super.key});

  final BottomNavController controller = Get.put(BottomNavController());

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Scaffold(
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
              onTap: controller.onTabTapped,
              type: BottomNavigationBarType.fixed,
              items: [
                BottomNavigationBarItem(
                  icon: Padding(
                    padding: EdgeInsets.only(bottom: 4),
                    child: SvgPicture.asset(
                      'lib/assets/bottom_navigation/home.svg',
                      width: 24,
                      height: 24,
                    ),
                  ),
                  label: '首页',
                ),
                BottomNavigationBarItem(
                  icon: Padding(
                    padding: EdgeInsets.only(bottom: 4),
                    child: SvgPicture.asset(
                      'lib/assets/bottom_navigation/explore.svg',
                      width: 24,
                      height: 24,
                    ),
                  ),
                  label: '探索',
                ),
                BottomNavigationBarItem(
                  icon: Padding(
                    padding: EdgeInsets.only(bottom: 4),
                    child: SvgPicture.asset(
                      'lib/assets/bottom_navigation/tool.svg',
                      width: 24,
                      height: 24,
                    ),
                  ),
                  label: '工具',
                ),
                BottomNavigationBarItem(
                  icon: Padding(
                    padding: EdgeInsets.only(bottom: 4),
                    child: SvgPicture.asset(
                      'lib/assets/bottom_navigation/setting.svg',
                      width: 24,
                      height: 24,
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
      ),
    );
  }
}
