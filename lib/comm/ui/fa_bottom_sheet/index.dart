import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// 底部弹层位置枚举
enum FaBottomSheetPosition { bottom, top, center }

/// 底部弹层配置
class FaBottomSheetConfig {
  /// 是否允许点击背景关闭
  static bool allowDismissible = true;

  /// 是否允许拖动
  static bool allowDrag = true;

  /// 背景遮罩透明度
  static double backdropOpacity = 0.5;

  /// 动画时长
  static Duration animationDuration = const Duration(milliseconds: 300);

  /// 更新配置
  static void updateConfig({
    bool? allowDismissible,
    bool? allowDrag,
    double? backdropOpacity,
    Duration? animationDuration,
  }) {
    if (allowDismissible != null)
      FaBottomSheetConfig.allowDismissible = allowDismissible;
    if (allowDrag != null) FaBottomSheetConfig.allowDrag = allowDrag;
    if (backdropOpacity != null)
      FaBottomSheetConfig.backdropOpacity = backdropOpacity;
    if (animationDuration != null)
      FaBottomSheetConfig.animationDuration = animationDuration;
  }
}

class FaBottomSheet extends StatelessWidget {
  const FaBottomSheet({
    super.key,
    required this.child,
    this.height,
    this.backgroundColor,
    this.borderRadius = 16,
    this.padding = const EdgeInsets.all(24),
    this.showDragHandle = true,
    this.dragHandleColor,
    this.onDismiss,
    this.isDismissible,
    this.enableDrag,
    this.position = FaBottomSheetPosition.bottom,
    this.showBackdrop = true,
    this.backdropColor,
    this.backdropOpacity,
    this.useSafeArea = true,
    this.elevation = 8.0,
    this.animationDuration,
    this.dragHandleSize = const Size(32, 4),
    this.dragHandlePadding = const EdgeInsets.only(top: 12, bottom: 8),
    this.constraints,
  });

  /// 内容组件
  final Widget child;

  /// 高度，不设置则自适应内容高度
  final double? height;

  /// 背景色
  final Color? backgroundColor;

  /// 顶部圆角
  final double borderRadius;

  /// 内容区域内边距
  final EdgeInsets padding;

  /// 是否显示顶部拖动条
  final bool showDragHandle;

  /// 拖动条颜色
  final Color? dragHandleColor;

  /// 关闭回调
  final VoidCallback? onDismiss;

  /// 是否允许点击背景关闭
  final bool? isDismissible;

  /// 是否允许拖拽关闭
  final bool? enableDrag;

  /// 弹层位置
  final FaBottomSheetPosition position;

  /// 是否显示背景遮罩
  final bool showBackdrop;

  /// 背景遮罩颜色
  final Color? backdropColor;

  /// 背景遮罩透明度
  final double? backdropOpacity;

  /// 是否使用安全区域
  final bool useSafeArea;

  /// 阴影高度
  final double elevation;

  /// 动画时长
  final Duration? animationDuration;

  /// 拖动条尺寸
  final Size dragHandleSize;

  /// 拖动条内边距
  final EdgeInsets dragHandlePadding;

  /// 内容区域约束
  final BoxConstraints? constraints;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defaultBackgroundColor = theme.scaffoldBackgroundColor;
    final defaultDragHandleColor = theme.dividerColor;

    Widget content = Container(
      height: height,
      constraints: constraints,
      decoration: BoxDecoration(
        color: backgroundColor ?? defaultBackgroundColor,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(borderRadius),
          bottom: position == FaBottomSheetPosition.top
              ? Radius.circular(borderRadius)
              : Radius.zero,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: elevation,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDragHandle)
            Padding(
              padding: dragHandlePadding,
              child: Container(
                width: dragHandleSize.width,
                height: dragHandleSize.height,
                decoration: BoxDecoration(
                  color: dragHandleColor ?? defaultDragHandleColor,
                  borderRadius: BorderRadius.circular(
                    dragHandleSize.height / 2,
                  ),
                ),
              ),
            ),
          Padding(padding: padding, child: child),
        ],
      ),
    );

    // 添加安全区域
    if (useSafeArea) {
      content = SafeArea(
        bottom: position == FaBottomSheetPosition.bottom,
        top: position == FaBottomSheetPosition.top,
        child: content,
      );
    }

    // 根据位置调整对齐方式
    content = Align(
      alignment: position == FaBottomSheetPosition.bottom
          ? Alignment.bottomCenter
          : position == FaBottomSheetPosition.top
          ? Alignment.topCenter
          : Alignment.center,
      child: content,
    );

    return Material(color: Colors.transparent, child: content);
  }

  /// 显示底部弹出层
  static Future<T?> show<T>({
    required Widget child,
    double? height,
    Color? backgroundColor,
    double borderRadius = 16,
    EdgeInsets padding = const EdgeInsets.all(24),
    bool showDragHandle = true,
    Color? dragHandleColor,
    VoidCallback? onDismiss,
    bool? isDismissible,
    bool? enableDrag,
    Color? barrierColor,
    FaBottomSheetPosition position = FaBottomSheetPosition.bottom,
    bool showBackdrop = true,
    Color? backdropColor,
    double? backdropOpacity,
    bool useSafeArea = true,
    double elevation = 8.0,
    Duration? animationDuration,
    Size dragHandleSize = const Size(32, 4),
    EdgeInsets dragHandlePadding = const EdgeInsets.only(top: 12, bottom: 8),
    BoxConstraints? constraints,
  }) {
    // 使用全局配置或传入的参数
    final actualIsDismissible =
        isDismissible ?? FaBottomSheetConfig.allowDismissible;
    final actualEnableDrag = enableDrag ?? FaBottomSheetConfig.allowDrag;
    final actualBackdropOpacity =
        backdropOpacity ?? FaBottomSheetConfig.backdropOpacity;
    final actualAnimationDuration =
        animationDuration ?? FaBottomSheetConfig.animationDuration;

    // 创建一个关闭处理函数
    void handleDismiss() {
      if (Get.isBottomSheetOpen ?? false) {
        Get.back(closeOverlays: true);
        onDismiss?.call();
      }
    }

    return Get.bottomSheet(
      GestureDetector(
        onTap: () {
          if (actualIsDismissible) {
            handleDismiss();
          }
        },
        behavior: HitTestBehavior.translucent,
        child: GestureDetector(
          onTap: () {}, // 阻止事件冒泡
          child: FaBottomSheet(
            height: height,
            backgroundColor: backgroundColor,
            borderRadius: borderRadius,
            padding: padding,
            showDragHandle: showDragHandle,
            dragHandleColor: dragHandleColor,
            onDismiss: handleDismiss,
            isDismissible: actualIsDismissible,
            enableDrag: actualEnableDrag,
            position: position,
            showBackdrop: showBackdrop,
            backdropColor: backdropColor,
            backdropOpacity: actualBackdropOpacity,
            useSafeArea: useSafeArea,
            elevation: elevation,
            animationDuration: actualAnimationDuration,
            dragHandleSize: dragHandleSize,
            dragHandlePadding: dragHandlePadding,
            constraints: constraints,
            child: child,
          ),
        ),
      ),
      isDismissible: false, // 我们自己处理点击背景关闭
      enableDrag: actualEnableDrag,
      backgroundColor: Colors.transparent,
      barrierColor: showBackdrop
          ? (backdropColor ?? Colors.black).withOpacity(actualBackdropOpacity)
          : Colors.transparent,
      isScrollControlled: true,
      enterBottomSheetDuration: actualAnimationDuration,
      exitBottomSheetDuration: actualAnimationDuration,
    );
  }
}
