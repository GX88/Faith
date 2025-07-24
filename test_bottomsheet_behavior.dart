import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:faith/comm/ui/fa_bottom_sheet/index.dart';

void main() {
  runApp(GetMaterialApp(
    home: Scaffold(
      appBar: AppBar(title: Text('BottomSheet Test')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                // 测试1: 使用Get.bottomSheet原生方法
                Get.bottomSheet(
                  Container(
                    height: 200,
                    color: Colors.white,
                    child: Center(child: Text('原生Get.bottomSheet - 应该可以点击遮罩关闭')),
                  ),
                  isDismissible: true,
                  barrierColor: Colors.black54,
                );
              },
              child: Text('测试原生Get.bottomSheet'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // 测试2: 使用FaBottomSheet
                FaBottomSheet.show(
                  child: Container(
                    height: 200,
                    color: Colors.white,
                    child: Center(child: Text('FaBottomSheet - 测试点击遮罩关闭')),
                  ),
                  backgroundColor: Colors.white,
                  isDismissible: true,
                  barrierColor: Colors.black54,
                );
              },
              child: Text('测试FaBottomSheet'),
            ),
          ],
        ),
      ),
    ),
  ));
}