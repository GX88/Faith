import 'package:flutter/material.dart';

/// 按钮尺寸枚举
enum FaButtonSize {
  mini(32.0),
  small(40.0),
  medium(48.0),
  large(56.0);

  final double height;
  const FaButtonSize(this.height);
}

/// 按钮类型枚举
enum FaButtonType { primary, secondary, outline, text, danger }

/// Faith App 通用按钮组件
class FaButton extends StatelessWidget {
  const FaButton({
    super.key,
    required this.onPressed,
    required this.text,
    this.width,
    this.size = FaButtonSize.medium,
    this.type = FaButtonType.primary,
    this.icon,
    this.loading = false,
    this.disabled = false,
    this.block = false,
    this.borderRadius = 8.0,
    this.textStyle,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation,
    this.padding,
    this.loadingText = '请稍候...',
  });

  /// 点击回调
  final VoidCallback? onPressed;

  /// 按钮文本
  final String text;

  /// 按钮宽度
  final double? width;

  /// 按钮尺寸
  final FaButtonSize size;

  /// 按钮类型
  final FaButtonType type;

  /// 按钮图标
  final Widget? icon;

  /// 是否加载中
  final bool loading;

  /// 是否禁用
  final bool disabled;

  /// 是否块级按钮（占满宽度）
  final bool block;

  /// 圆角大小
  final double borderRadius;

  /// 文本样式
  final TextStyle? textStyle;

  /// 背景色
  final Color? backgroundColor;

  /// 前景色
  final Color? foregroundColor;

  /// 阴影高度
  final double? elevation;

  /// 内边距
  final EdgeInsetsGeometry? padding;

  /// 加载中文本
  final String loadingText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // 根据类型获取按钮样式
    ButtonStyle defaultStyle = _getButtonStyle(theme);

    // 合并自定义样式
    final ButtonStyle finalStyle = defaultStyle.copyWith(
      backgroundColor: backgroundColor != null
          ? WidgetStateProperty.all(backgroundColor)
          : null,
      foregroundColor: foregroundColor != null
          ? WidgetStateProperty.all(foregroundColor)
          : null,
      elevation: elevation != null ? WidgetStateProperty.all(elevation) : null,
      padding: padding != null ? WidgetStateProperty.all(padding) : null,
    );

    return SizedBox(
      width: block ? double.infinity : width,
      height: size.height,
      child: ElevatedButton(
        onPressed: (disabled || loading) ? null : onPressed,
        style: finalStyle,
        child: _buildButtonContent(),
      ),
    );
  }

  /// 构建按钮内容
  Widget _buildButtonContent() {
    if (loading) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                foregroundColor ?? Colors.white,
              ),
            ),
          ),
          if (loadingText.isNotEmpty) ...[
            const SizedBox(width: 8),
            Text(loadingText),
          ],
        ],
      );
    }

    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          icon!,
          const SizedBox(width: 8),
          Text(text, style: textStyle),
        ],
      );
    }

    return Text(text, style: textStyle);
  }

  /// 获取按钮样式
  ButtonStyle _getButtonStyle(ThemeData theme) {
    switch (type) {
      case FaButtonType.primary:
        return ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        );

      case FaButtonType.secondary:
        return ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.secondary,
          foregroundColor: theme.colorScheme.onSecondary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        );

      case FaButtonType.outline:
        return ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: theme.colorScheme.primary,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            side: BorderSide(color: theme.colorScheme.primary, width: 1),
          ),
        );

      case FaButtonType.text:
        return ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: theme.colorScheme.primary,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        );

      case FaButtonType.danger:
        return ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.error,
          foregroundColor: theme.colorScheme.onError,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        );
    }
  }
}
