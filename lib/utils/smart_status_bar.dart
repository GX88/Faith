import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

/// 智能状态栏工具类
/// 通过页面截图分析主要颜色，自动设置合适的状态栏样式
class SmartStatusBar {
  static GlobalKey? _currentPageKey;
  static Color? _lastAnalyzedColor;
  static Brightness? _lastIconBrightness;

  /// 注册页面的GlobalKey，用于截图分析
  ///
  /// [pageKey] 页面的GlobalKey
  static void registerPage(GlobalKey pageKey) {
    _currentPageKey = pageKey;
  }

  /// 分析当前页面并设置状态栏样式
  ///
  /// [delay] 延迟执行时间（毫秒），默认100ms
  static Future<void> analyzeAndSetStatusBar({int delay = 100}) async {
    if (delay > 0) {
      await Future.delayed(Duration(milliseconds: delay));
    }

    if (_currentPageKey?.currentContext == null) {
      // 如果没有注册页面或页面未构建完成，使用默认设置
      _setDefaultStatusBar();
      return;
    }

    try {
      // 获取页面截图
      final screenshot = await _capturePageScreenshot();
      if (screenshot == null) {
        _setDefaultStatusBar();
        return;
      }

      // 分析截图中的主要颜色
      final dominantColor = await _analyzeDominantColor(screenshot);

      // 根据主要颜色设置状态栏样式
      await _setStatusBarFromColor(dominantColor);

      // 缓存分析结果
      _lastAnalyzedColor = dominantColor;
      _lastIconBrightness = _getIconBrightness(dominantColor);
    } catch (e) {
      debugPrint('SmartStatusBar: 分析页面颜色失败: $e');
      _setDefaultStatusBar();
    }
  }

  /// 获取页面截图
  static Future<ui.Image?> _capturePageScreenshot() async {
    try {
      final context = _currentPageKey?.currentContext;
      if (context == null) return null;

      final renderObject = context.findRenderObject();
      if (renderObject is! RenderRepaintBoundary) {
        debugPrint('SmartStatusBar: 页面需要包装在RepaintBoundary中');
        return null;
      }

      // 获取状态栏区域的截图（顶部区域）
      final image = await renderObject.toImage(
        pixelRatio: View.of(context).devicePixelRatio,
      );

      return image;
    } catch (e) {
      debugPrint('SmartStatusBar: 截图失败: $e');
      return null;
    }
  }

  /// 分析图片中的主要颜色
  ///
  /// [image] 要分析的图片
  /// 返回主要颜色
  static Future<Color> _analyzeDominantColor(ui.Image image) async {
    try {
      // 将图片转换为字节数据
      final byteData = await image.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      );
      if (byteData == null) {
        return const Color(0xFFFFFFFF); // 默认白色
      }

      final pixels = byteData.buffer.asUint8List();

      // 只分析图片顶部区域（状态栏相关区域）
      final topHeight = (image.height * 0.2).round(); // 分析顶部20%的区域
      final sampleSize = 4; // RGBA每个像素4字节

      // 颜色统计
      final colorCounts = <int, int>{};

      // 采样分析（每隔几个像素采样一次以提高性能）
      for (int y = 0; y < topHeight; y += 2) {
        for (int x = 0; x < image.width; x += 2) {
          final pixelIndex = (y * image.width + x) * sampleSize;
          if (pixelIndex + 3 < pixels.length) {
            final r = pixels[pixelIndex];
            final g = pixels[pixelIndex + 1];
            final b = pixels[pixelIndex + 2];
            final a = pixels[pixelIndex + 3];

            // 忽略透明像素
            if (a < 128) continue;

            // 将RGB值组合成一个整数作为颜色键
            final colorKey = (r << 16) | (g << 8) | b;
            colorCounts[colorKey] = (colorCounts[colorKey] ?? 0) + 1;
          }
        }
      }

      if (colorCounts.isEmpty) {
        return const Color(0xFFFFFFFF); // 默认白色
      }

      // 找到出现次数最多的颜色
      int dominantColorKey = colorCounts.keys.first;
      int maxCount = colorCounts[dominantColorKey]!;

      for (final entry in colorCounts.entries) {
        if (entry.value > maxCount) {
          dominantColorKey = entry.key;
          maxCount = entry.value;
        }
      }

      // 将颜色键转换回Color对象
      final r = (dominantColorKey >> 16) & 0xFF;
      final g = (dominantColorKey >> 8) & 0xFF;
      final b = dominantColorKey & 0xFF;

      return Color.fromARGB(255, r, g, b);
    } catch (e) {
      debugPrint('SmartStatusBar: 颜色分析失败: $e');
      return const Color(0xFFFFFFFF); // 默认白色
    }
  }

  /// 根据颜色设置状态栏样式
  ///
  /// [color] 分析得到的主要颜色
  static Future<void> _setStatusBarFromColor(Color color) async {
    final iconBrightness = _getIconBrightness(color);

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent, // 保持透明，让页面颜色透过
        statusBarIconBrightness: iconBrightness,
      ),
    );

    debugPrint(
      'SmartStatusBar: 设置状态栏 - 主要颜色: ${color.toString()}, 图标亮度: $iconBrightness',
    );
  }

  /// 根据颜色计算图标亮度
  ///
  /// [color] 背景颜色
  /// 返回合适的图标亮度
  static Brightness _getIconBrightness(Color color) {
    // 计算颜色的相对亮度（使用W3C推荐的公式）
    final red = (color.r * 255.0).round();
    final green = (color.g * 255.0).round();
    final blue = (color.b * 255.0).round();
    final luminance = (0.299 * red + 0.587 * green + 0.114 * blue) / 255;

    // 如果背景较亮（亮度 > 0.5），使用深色图标
    // 如果背景较暗（亮度 <= 0.5），使用浅色图标
    return luminance > 0.5 ? Brightness.dark : Brightness.light;
  }

  /// 设置默认状态栏样式
  static void _setDefaultStatusBar() {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark, // 默认深色图标
      ),
    );
    debugPrint('SmartStatusBar: 使用默认状态栏设置');
  }

  /// 获取上次分析的颜色
  static Color? get lastAnalyzedColor => _lastAnalyzedColor;

  /// 获取上次设置的图标亮度
  static Brightness? get lastIconBrightness => _lastIconBrightness;

  /// 清除缓存
  static void clearCache() {
    _lastAnalyzedColor = null;
    _lastIconBrightness = null;
  }
}

/// 智能状态栏混入类
/// 为页面提供便捷的智能状态栏功能
mixin SmartStatusBarMixin<T extends StatefulWidget> on State<T> {
  final GlobalKey _pageKey = GlobalKey();

  /// 获取页面的GlobalKey
  GlobalKey get pageKey => _pageKey;

  @override
  void initState() {
    super.initState();
    // 注册页面
    SmartStatusBar.registerPage(_pageKey);
    // 页面初始化后分析状态栏
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SmartStatusBar.analyzeAndSetStatusBar();
    });
  }

  @override
  void didUpdateWidget(T oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 页面更新后重新分析状态栏
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SmartStatusBar.analyzeAndSetStatusBar(delay: 50);
    });
  }

  /// 手动触发状态栏分析
  void refreshStatusBar() {
    SmartStatusBar.analyzeAndSetStatusBar();
  }
}
