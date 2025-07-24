import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:developer' as developer;

/// 底部弹层位置枚举
enum FaBottomSheetPosition { bottom, top, center }

/// 底部弹层配置类 - 使用不可变对象替代静态变量
class FaBottomSheetConfig {
  final bool allowDismissible;
  final bool allowDrag;
  final double backdropOpacity;
  final Duration animationDuration;
  final Color? barrierColor;
  final bool isScrollControlled;

  const FaBottomSheetConfig({
    this.allowDismissible = true,
    this.allowDrag = true,
    this.backdropOpacity = 0.5,
    this.animationDuration = const Duration(milliseconds: 300),
    this.barrierColor,
    this.isScrollControlled = true,
  });

  /// 复制配置并修改指定属性
  FaBottomSheetConfig copyWith({
    bool? allowDismissible,
    bool? allowDrag,
    double? backdropOpacity,
    Duration? animationDuration,
    Color? barrierColor,
    bool? isScrollControlled,
  }) {
    return FaBottomSheetConfig(
      allowDismissible: allowDismissible ?? this.allowDismissible,
      allowDrag: allowDrag ?? this.allowDrag,
      backdropOpacity: backdropOpacity ?? this.backdropOpacity,
      animationDuration: animationDuration ?? this.animationDuration,
      barrierColor: barrierColor ?? this.barrierColor,
      isScrollControlled: isScrollControlled ?? this.isScrollControlled,
    );
  }

  /// 默认配置
  static const FaBottomSheetConfig defaultConfig = FaBottomSheetConfig();

  /// 不可关闭配置
  static const FaBottomSheetConfig nonDismissible = FaBottomSheetConfig(
    allowDismissible: false,
    allowDrag: false,
  );

  /// 半透明配置
  static const FaBottomSheetConfig translucent = FaBottomSheetConfig(
    backdropOpacity: 0.3,
  );
}

/// 底部弹窗控制器
class FaBottomSheetController {
  final VoidCallback close;
  
  FaBottomSheetController({required this.close});
}

class FaBottomSheet extends StatelessWidget {
  const FaBottomSheet({
    super.key,
    required this.child,
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
    this.controller,
    this.header,
    this.footer,
    this.enableScroll = false,
    this.maxHeightRatio = 0.8,
    this.minHeightRatio = 0.2,
  });

  /// 内容组件
  final Widget child;

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

  /// 控制器
  final FaBottomSheetController? controller;

  /// 头部组件
  final Widget? header;

  /// 底部组件
  final Widget? footer;

  /// 是否启用滚动
  final bool enableScroll;

  /// 最大高度比例
  final double maxHeightRatio;

  /// 最小高度比例
  final double minHeightRatio;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defaultBackgroundColor = theme.scaffoldBackgroundColor;
    final defaultDragHandleColor = theme.dividerColor;

    Widget content = LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;
        final screenHeight = MediaQuery.of(context).size.height;
        final minHeight = screenHeight * minHeightRatio;
        final maxHeight = screenHeight * maxHeightRatio;
        
        return Container(
          width: screenWidth,
          constraints: (this.constraints ?? const BoxConstraints()).copyWith(
            minHeight: minHeight,
            maxHeight: maxHeight,
          ),
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
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: elevation,
                offset: position == FaBottomSheetPosition.bottom
                    ? const Offset(0, -2)
                    : const Offset(0, 2),
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
              if (header != null) header!,
              Expanded(
                flex: enableScroll ? 1 : 0,
                child: enableScroll
                    ? SingleChildScrollView(
                        child: Padding(padding: padding, child: child),
                      )
                    : Padding(padding: padding, child: child),
              ),
              if (footer != null) footer!,
            ],
          ),
        );
      },
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

    // 使用Stack包装，确保点击事件可以传递到遮罩层
    return Material(color: Colors.transparent, child: content);
  }

  /// 显示底部弹出层
  static Future<T?> show<T>({
    required Widget child,
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
    FaBottomSheetConfig? config,
    FaBottomSheetController? controller,
    Widget? header,
    Widget? footer,
    bool enableScroll = false,
    double maxHeightRatio = 0.8,
    double minHeightRatio = 0.2,
    BuildContext? context,
  }) {
    // 使用配置对象或默认配置
    final effectiveConfig = config ?? FaBottomSheetConfig.defaultConfig;
    final actualIsDismissible = isDismissible ?? effectiveConfig.allowDismissible;
    final actualEnableDrag = enableDrag ?? effectiveConfig.allowDrag;
    final actualBackdropOpacity = backdropOpacity ?? effectiveConfig.backdropOpacity;
    final actualAnimationDuration = animationDuration ?? effectiveConfig.animationDuration;

    // 创建控制器
    final sheetController = FaBottomSheetController(
      close: () {
        final ctx = context ?? Get.context;
        if (ctx != null && Navigator.of(ctx).canPop()) {
          Navigator.of(ctx).pop();
        } else {
          Get.back(closeOverlays: true);
        }
        onDismiss?.call();
      },
    );

    // 调试日志
    developer.log('FaBottomSheet.show - isDismissible: $actualIsDismissible', name: 'FaBottomSheet');
    developer.log('FaBottomSheet.show - enableDrag: $actualEnableDrag', name: 'FaBottomSheet');
    developer.log('FaBottomSheet.show - barrierColor: ${showBackdrop ? (barrierColor ?? backdropColor ?? Colors.black).withValues(alpha: actualBackdropOpacity) : Colors.transparent}', name: 'FaBottomSheet');

    // 使用原生showModalBottomSheet确保遮罩关闭功能
    return showModalBottomSheet<T>(
      context: context ?? Get.context!,
      builder: (context) => FaBottomSheet(
        backgroundColor: backgroundColor,
        borderRadius: borderRadius,
        padding: padding,
        showDragHandle: showDragHandle,
        dragHandleColor: dragHandleColor,
        onDismiss: sheetController.close,
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
        controller: sheetController,
        header: header,
        footer: footer,
        enableScroll: enableScroll,
        maxHeightRatio: maxHeightRatio,
        minHeightRatio: minHeightRatio,
        child: child,
      ),
      isDismissible: actualIsDismissible,
      enableDrag: actualEnableDrag,
      backgroundColor: Colors.transparent,
      barrierColor: showBackdrop
          ? (barrierColor ?? backdropColor ?? Colors.black)
              .withValues(alpha: actualBackdropOpacity)
          : Colors.transparent,
      isScrollControlled: effectiveConfig.isScrollControlled,
      transitionAnimationController: null,
    );
  }

  /// 快速显示简单底部弹窗
  static Future<T?> showSimple<T>({
    required String title,
    required String message,
    List<Widget>? actions,
    Color? backgroundColor,
    FaBottomSheetConfig? config,
    BuildContext? context,
  }) {
    return show<T>(
      context: context,
      config: config,
      backgroundColor: backgroundColor,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Get.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: Get.textTheme.bodyMedium,
          ),
          if (actions != null) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: actions,
            ),
          ],
        ],
      ),
    );
  }

  /// 显示列表选择器
  static Future<T?> showList<T>({
    required List<T> items,
    required String Function(T) itemBuilder,
    ValueChanged<T>? onSelected,
    String? title,
    Color? backgroundColor,
    FaBottomSheetConfig? config,
    BuildContext? context,
  }) {
    return show<T>(
      context: context,
      config: config,
      backgroundColor: backgroundColor,
      enableScroll: true,
      maxHeightRatio: 0.6,
      header: title != null
          ? Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Text(
                title,
                style: Get.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: items.map((item) {
          return ListTile(
            title: Text(itemBuilder(item)),
            onTap: () {
              Get.back(result: item);
              onSelected?.call(item);
            },
          );
        }).toList(),
      ),
    );
  }

  /// 显示加载状态
  static Future<T?> showLoading<T>({
    String message = '加载中...',
    Color? backgroundColor,
    bool dismissible = false,
    BuildContext? context,
  }) {
    return show<T>(
      context: context,
      config: const FaBottomSheetConfig(
        allowDismissible: false,
        allowDrag: false,
      ).copyWith(
        allowDismissible: dismissible,
      ),
      backgroundColor: backgroundColor,
      showDragHandle: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(message),
        ],
      ),
    );
}
}
