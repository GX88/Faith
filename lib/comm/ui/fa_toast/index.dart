import 'dart:async';

import 'package:flutter/material.dart';

/// Toast主题类型
enum FaToastType { success, error, warning, info, custom }

/// Toast显示位置
enum FaToastPosition {
  top,
  center,
  bottom,
  topLeft,
  topRight,
  bottomLeft,
  bottomRight,
  centerLeft,
  centerRight,
}

class FaToast {
  static OverlayEntry? _currentEntry;
  static Timer? _timer;
  static VoidCallback? _onDismiss;

  static const Map<FaToastType, Color> _defaultBgColors = {
    FaToastType.success: Color(0xFF4CAF50),
    FaToastType.error: Color(0xFFF44336),
    FaToastType.warning: Color(0xFFFF9800),
    FaToastType.info: Color(0xFF2196F3),
    FaToastType.custom: Color(0xFF333333),
  };

  static const Map<FaToastType, IconData> _defaultIcons = {
    FaToastType.success: Icons.check_circle,
    FaToastType.error: Icons.error,
    FaToastType.warning: Icons.warning,
    FaToastType.info: Icons.info,
    FaToastType.custom: Icons.notifications,
  };

  static void show(
    BuildContext context, {
    String? message,
    Widget? child,
    FaToastType type = FaToastType.info,
    Color? color,
    Color textColor = Colors.black87,
    double fontSize = 15,
    FontWeight fontWeight = FontWeight.w500,
    double borderRadius = 16,
    EdgeInsetsGeometry margin = const EdgeInsets.symmetric(
      horizontal: 24,
      vertical: 16,
    ),
    EdgeInsetsGeometry padding = const EdgeInsets.symmetric(
      vertical: 16,
      horizontal: 18,
    ),
    Duration duration = const Duration(seconds: 3),
    double elevation = 18,
    Color? shadowColor,
    double? shadowBlur,
    Offset? shadowOffset,
    Widget? icon,
    TextAlign textAlign = TextAlign.left,
    VoidCallback? onShow,
    VoidCallback? onDismiss,
    FaToastPosition position = FaToastPosition.top,
    bool showClose = false,
    bool dismissOnTap = false,
    double? maxWidth,
    double? minWidth,
    Color? cardColor,
    Color? iconBgColor,
    double blurSigma = 18,
    Gradient? glassGradient,
    Color? borderColor,
    double borderWidth = 1.2,
    double glassOpacity = 0.18,
  }) {
    _timer?.cancel();
    _currentEntry?.remove();
    _onDismiss = onDismiss;

    final overlay = Overlay.of(context);

    Color themeColor = color ?? _defaultBgColors[type]!;
    Color iconBg = iconBgColor ?? themeColor.withValues(alpha: 0.15);
    Widget? resolvedIcon = icon;
    if (resolvedIcon == null && type != FaToastType.custom) {
      resolvedIcon = Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
        child: Icon(_defaultIcons[type], color: themeColor, size: 20),
      );
    } else if (resolvedIcon != null) {
      resolvedIcon = Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
        child: Center(child: resolvedIcon),
      );
    }

    Widget content =
        child ??
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (resolvedIcon != null) ...[
              resolvedIcon,
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text(
                message ?? '',
                style: TextStyle(
                  color: textColor,
                  fontWeight: fontWeight,
                  fontSize: fontSize,
                  letterSpacing: 0.2,
                ),
                textAlign: textAlign,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (showClose)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: GestureDetector(
                  onTap: () => dismiss(),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.black54,
                      size: 18,
                    ),
                  ),
                ),
              ),
          ],
        );

    Alignment alignment;
    switch (position) {
      case FaToastPosition.top:
        alignment = Alignment.topCenter;
        break;
      case FaToastPosition.center:
        alignment = Alignment.center;
        break;
      case FaToastPosition.bottom:
        alignment = Alignment.bottomCenter;
        break;
      case FaToastPosition.topLeft:
        alignment = Alignment.topLeft;
        break;
      case FaToastPosition.topRight:
        alignment = Alignment.topRight;
        break;
      case FaToastPosition.bottomLeft:
        alignment = Alignment.bottomLeft;
        break;
      case FaToastPosition.bottomRight:
        alignment = Alignment.bottomRight;
        break;
      case FaToastPosition.centerLeft:
        alignment = Alignment.centerLeft;
        break;
      case FaToastPosition.centerRight:
        alignment = Alignment.centerRight;
        break;
    }

    Widget toastCard = AnimatedOpacity(
      opacity: 1.0,
      duration: const Duration(milliseconds: 220),
      child: Container(
        margin: margin,
        padding: padding,
        constraints: BoxConstraints(
          maxWidth: maxWidth ?? 360,
          minWidth: minWidth ?? 0,
        ),
        decoration: BoxDecoration(
          gradient:
              glassGradient ??
              LinearGradient(
                colors: [
                  Colors.white.withValues(alpha: glassOpacity + 0.07),
                  Colors.white.withValues(alpha: glassOpacity),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
          border: Border.all(
            color: borderColor ?? Colors.white.withValues(alpha: 0.22),
            width: borderWidth,
          ),
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: content,
      ),
    );

    _currentEntry = OverlayEntry(
      builder: (context) => SafeArea(
        child: Container(
          alignment: alignment,
          child: Material(
            color: Colors.transparent,
            child: GestureDetector(
              onTap: dismissOnTap ? () => dismiss() : null,
              child: toastCard,
            ),
          ),
        ),
      ),
    );

    overlay.insert(_currentEntry!);
    if (onShow != null) onShow();
    _timer = Timer(duration, () {
      dismiss();
    });
  }

  static void dismiss() {
    _timer?.cancel();
    _currentEntry?.remove();
    _currentEntry = null;
    _timer = null;
    if (_onDismiss != null) {
      _onDismiss!();
      _onDismiss = null;
    }
  }
}
