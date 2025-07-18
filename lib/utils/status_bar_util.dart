import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 设置状态栏样式
/// [bgColor] 传入背景色自动判断明暗
/// [force] 传入Brightness强制指定（如Brightness.light/ dark）
void setStatusBarStyle({Color? bgColor, Brightness? force}) {
  Brightness iconBrightness;
  Brightness barBrightness;
  if (force != null) {
    iconBrightness = force;
    barBrightness = force == Brightness.dark
        ? Brightness.light
        : Brightness.dark;
  } else if (bgColor != null) {
    final isLight = bgColor.computeLuminance() > 0.5;
    iconBrightness = isLight ? Brightness.dark : Brightness.light;
    barBrightness = isLight ? Brightness.light : Brightness.dark;
  } else {
    // 默认
    iconBrightness = Brightness.dark;
    barBrightness = Brightness.light;
  }
  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: iconBrightness,
      statusBarBrightness: barBrightness,
    ),
  );
}
