import 'package:flutter/material.dart';

/// 进度即背景的按钮
class ProgressButton extends StatelessWidget {
  final double progress; // 0.0~1.0
  final String text;
  final VoidCallback? onPressed;
  final bool enabled;
  final Color backgroundColor;
  final Color progressColor;
  final Color foregroundColor;
  final double borderRadius;
  final Widget? icon;
  final double height;

  const ProgressButton({
    super.key,
    required this.progress,
    required this.text,
    required this.onPressed,
    this.enabled = true,
    this.backgroundColor = Colors.transparent,
    this.progressColor = const Color(0xFF1976D2),
    this.foregroundColor = Colors.black,
    this.borderRadius = 12,
    this.icon,
    this.height = 48,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // 进度背景
        Container(
          height: height,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: progressColor, width: 1.5),
          ),
        ),
        // 进度色填充
        Positioned.fill(
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress.clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                color: progressColor.withOpacity(0.18 + 0.72 * progress),
                borderRadius: BorderRadius.circular(borderRadius),
              ),
            ),
          ),
        ),
        // 按钮内容
        SizedBox(
          height: height,
          child: TextButton(
            onPressed: enabled ? onPressed : null,
            style: TextButton.styleFrom(
              foregroundColor: foregroundColor,
              backgroundColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(borderRadius),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[icon!, const SizedBox(width: 6)],
                Text(text),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
