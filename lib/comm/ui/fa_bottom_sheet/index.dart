import 'package:flutter/material.dart';

/// 自定义可拖动底部弹窗组件
class CustomDraggableBottomSheet extends StatefulWidget {
  final Widget child;
  final VoidCallback onClose;

  const CustomDraggableBottomSheet({
    required this.child,
    required this.onClose,
    super.key,
  });

  @override
  State<CustomDraggableBottomSheet> createState() =>
      _CustomDraggableBottomSheetState();
}

class _CustomDraggableBottomSheetState extends State<CustomDraggableBottomSheet>
    with SingleTickerProviderStateMixin {
  double _offsetY = 0;
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isClosing = false;

  @override
  void initState() {
    super.initState();
    // 初始化动画控制器
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _animation = Tween<double>(begin: 0, end: 0).animate(_controller);
    _controller.addListener(() {
      setState(() {
        _offsetY = _animation.value;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // 处理下滑拖动
  void _onVerticalDragUpdate(DragUpdateDetails details) {
    if (_isClosing) return;
    setState(() {
      _offsetY += details.delta.dy;
      if (_offsetY < 0) _offsetY = 0;
    });
  }

  // 拖动结束，判断是否关闭或回弹
  void _onVerticalDragEnd(DragEndDetails details) {
    if (_isClosing) return;
    if (_offsetY > 80 ||
        (details.primaryVelocity != null && details.primaryVelocity! > 800)) {
      // 拖动距离大于80或快速下滑，关闭弹层
      _isClosing = true;
      _animation = Tween<double>(
        begin: _offsetY,
        end: 600,
      ).animate(_controller);
      _controller.forward(from: 0).then((_) {
        widget.onClose();
      });
    } else {
      // 回弹到原位
      _animation = Tween<double>(begin: _offsetY, end: 0).animate(_controller);
      _controller.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 不要用 Scaffold，直接 Align+Material，避免内容区域覆盖全屏
    return Align(
      alignment: Alignment.bottomCenter,
      child: Material(
        color: Colors.transparent,
        child: GestureDetector(
          onVerticalDragUpdate: _onVerticalDragUpdate,
          onVerticalDragEnd: _onVerticalDragEnd,
          behavior: HitTestBehavior.opaque,
          child: Transform.translate(
            offset: Offset(0, _offsetY),
            child: FractionallySizedBox(
              widthFactor: 1,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16), // 默认左右边距
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 10),
                      // 顶部小横条，提示可拖动
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Color(0xFFE0E0E0),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // 真实内容区域
                      widget.child,
                      const SizedBox(height: 24), // 底部内边距
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class CustomBottomSheetHelper {
  /// 弹出自定义底部弹窗的静态方法
  /// - context: 上下文
  /// - child: 弹层内容（建议用 Column）
  /// - barrierDismissible: 是否允许点击遮罩关闭
  /// - animationDuration: 动画时长
  static Future<T?> showCustomBottomSheet<T>({
    required BuildContext context,
    required Widget child,
    bool barrierDismissible = true,
    Duration animationDuration = const Duration(milliseconds: 400),
  }) {
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black.withAlpha(128), // 128/255 ≈ 0.5
      transitionDuration: animationDuration,
      pageBuilder: (context, animation, secondaryAnimation) {
        // 只渲染内容区域，遮罩由 showGeneralDialog 处理
        return CustomDraggableBottomSheet(
          onClose: () => Navigator.of(context).maybePop(),
          child: child,
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        // 下滑+渐隐动画
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(curved),
          child: FadeTransition(opacity: curved, child: child),
        );
      },
    );
  }
}
