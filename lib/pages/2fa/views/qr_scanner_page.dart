import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../utils/smart_status_bar.dart';
import '../controller/tfa_controller.dart';

/// 二维码扫描页面
/// 用于扫描2FA二维码并添加账户
class QrScannerPage extends StatefulWidget {
  const QrScannerPage({super.key});

  @override
  State<QrScannerPage> createState() => _QrScannerPageState();
}

class _QrScannerPageState extends State<QrScannerPage>
    with SmartStatusBarMixin {
  late MobileScannerController _scannerController;
  final TfaController _tfaController = Get.find<TfaController>();
  bool _isScanning = true;

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      formats: [BarcodeFormat.qrCode],
    );
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  /// 处理扫描结果
  void _onDetect(BarcodeCapture capture) {
    if (!_isScanning) return;

    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      if (barcode.rawValue != null) {
        _isScanning = false;
        _handleQrCodeData(barcode.rawValue!);
        break;
      }
    }
  }

  /// 处理二维码数据
  Future<void> _handleQrCodeData(String qrData) async {
    try {
      await _tfaController.addAccountFromQrCode(qrData);
      if (mounted) {
        // 显示成功弹窗
        Get.snackbar('成功', '账户添加成功', snackPosition: SnackPosition.TOP);

        // 成功添加账户后关闭页面
        if (mounted) {
          Navigator.of(context).pop(); // 使用 Navigator.pop() 替代 Get.back()
        }
      }
    } catch (e) {
      if (mounted) {
        // 显示错误弹窗
        Get.snackbar('错误', e.toString().replaceFirst('Exception: ', ''));

        // 失败时重新启用扫描，不关闭页面
        setState(() {
          _isScanning = true;
        });
      }
    }
  }

  /// 切换闪光灯
  void _toggleFlash() {
    _scannerController.toggleTorch();
  }

  /// 切换摄像头
  void _switchCamera() {
    _scannerController.switchCamera();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: pageKey,
      child: Scaffold(
        backgroundColor: Colors.black,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 22),
            onPressed: () => Get.back(),
            style: IconButton.styleFrom(
              backgroundColor: Colors.black.withValues(alpha: 0.2),
              shape: const CircleBorder(),
            ),
          ),
          title: const Text(
            '扫描二维码',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.flash_on, color: Colors.white, size: 22),
              onPressed: _toggleFlash,
              style: IconButton.styleFrom(
                backgroundColor: Colors.black.withValues(alpha: 0.2),
                shape: const CircleBorder(),
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(
                Icons.flip_camera_ios,
                color: Colors.white,
                size: 22,
              ),
              onPressed: _switchCamera,
              style: IconButton.styleFrom(
                backgroundColor: Colors.black.withValues(alpha: 0.2),
                shape: const CircleBorder(),
              ),
            ),
            const SizedBox(width: 12),
          ],
        ),
        body: Stack(
          children: [
            // 摄像头预览
            MobileScanner(controller: _scannerController, onDetect: _onDetect),
            // 扫描框覆盖层
            _buildScanOverlay(),
            // 底部提示
            _buildBottomTip(),
          ],
        ),
      ),
    );
  }

  /// 构建扫描覆盖层
  Widget _buildScanOverlay() {
    return CustomPaint(
      painter: QrScannerOverlayPainter(
        borderColor: Colors.white,
        borderWidth: 2.0,
        overlayColor: Colors.black.withValues(alpha: 0.7),
        borderRadius: 12,
        borderLength: 24,
        cutOutSize: 240,
      ),
      child: const SizedBox.expand(),
    );
  }

  /// 构建底部提示
  Widget _buildBottomTip() {
    return Positioned(
      bottom: 80,
      left: 0,
      right: 0,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 32),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.qr_code_scanner, color: Colors.white, size: 24),
            SizedBox(height: 6),
            Text(
              '将二维码放入扫描框内',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 2),
            Text(
              '支持Google Authenticator等应用生成的二维码',
              style: TextStyle(color: Colors.white70, fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// 二维码扫描覆盖层绘制器
class QrScannerOverlayPainter extends CustomPainter {
  final Color borderColor;
  final double borderWidth;
  final Color overlayColor;
  final double borderRadius;
  final double borderLength;
  final double cutOutSize;

  const QrScannerOverlayPainter({
    this.borderColor = Colors.white,
    this.borderWidth = 2.0,
    this.overlayColor = const Color.fromRGBO(0, 0, 0, 180),
    this.borderRadius = 12,
    this.borderLength = 24,
    this.cutOutSize = 240,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;

    // 计算扫描框的位置和大小
    final cutOutWidth = cutOutSize;
    final cutOutHeight = cutOutSize;
    final cutOutX = (width - cutOutWidth) / 2;
    final cutOutY = (height - cutOutHeight) / 2;

    final cutOutRect = Rect.fromLTWH(
      cutOutX,
      cutOutY,
      cutOutWidth,
      cutOutHeight,
    );

    // 绘制半透明覆盖层
    final backgroundPaint = Paint()
      ..color = overlayColor
      ..style = PaintingStyle.fill;

    final backgroundPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, width, height))
      ..addRRect(
        RRect.fromRectAndRadius(cutOutRect, Radius.circular(borderRadius)),
      )
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(backgroundPath, backgroundPaint);

    // 绘制扫描框四个角的边框
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth
      ..strokeCap = StrokeCap.round;

    // 左上角
    canvas.drawPath(
      Path()
        ..moveTo(cutOutX, cutOutY + borderLength)
        ..lineTo(cutOutX, cutOutY + borderRadius)
        ..quadraticBezierTo(cutOutX, cutOutY, cutOutX + borderRadius, cutOutY)
        ..lineTo(cutOutX + borderLength, cutOutY),
      borderPaint,
    );

    // 右上角
    canvas.drawPath(
      Path()
        ..moveTo(cutOutX + cutOutWidth - borderLength, cutOutY)
        ..lineTo(cutOutX + cutOutWidth - borderRadius, cutOutY)
        ..quadraticBezierTo(
          cutOutX + cutOutWidth,
          cutOutY,
          cutOutX + cutOutWidth,
          cutOutY + borderRadius,
        )
        ..lineTo(cutOutX + cutOutWidth, cutOutY + borderLength),
      borderPaint,
    );

    // 右下角
    canvas.drawPath(
      Path()
        ..moveTo(cutOutX + cutOutWidth, cutOutY + cutOutHeight - borderLength)
        ..lineTo(cutOutX + cutOutWidth, cutOutY + cutOutHeight - borderRadius)
        ..quadraticBezierTo(
          cutOutX + cutOutWidth,
          cutOutY + cutOutHeight,
          cutOutX + cutOutWidth - borderRadius,
          cutOutY + cutOutHeight,
        )
        ..lineTo(cutOutX + cutOutWidth - borderLength, cutOutY + cutOutHeight),
      borderPaint,
    );

    // 左下角
    canvas.drawPath(
      Path()
        ..moveTo(cutOutX + borderLength, cutOutY + cutOutHeight)
        ..lineTo(cutOutX + borderRadius, cutOutY + cutOutHeight)
        ..quadraticBezierTo(
          cutOutX,
          cutOutY + cutOutHeight,
          cutOutX,
          cutOutY + cutOutHeight - borderRadius,
        )
        ..lineTo(cutOutX, cutOutY + cutOutHeight - borderLength),
      borderPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
