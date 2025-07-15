import 'package:flutter/services.dart';
import 'package:local_auth/error_codes.dart' as auth_error;
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';

/// 生物识别认证服务
class BiometricAuth {
  static final BiometricAuth _instance = BiometricAuth._internal();
  factory BiometricAuth() => _instance;
  BiometricAuth._internal();

  final LocalAuthentication _auth = LocalAuthentication();

  /// 检查设备是否支持生物识别
  Future<bool> isDeviceSupported() async {
    try {
      return await _auth.isDeviceSupported();
    } catch (e) {
      return false;
    }
  }

  /// 检查是否已设置生物识别
  Future<bool> isBiometricsAvailable() async {
    try {
      final List<BiometricType> availableBiometrics = await _auth
          .getAvailableBiometrics();
      return availableBiometrics.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// 获取可用的生物识别类型
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } catch (e) {
      return [];
    }
  }

  /// 直接调用认证（不阻塞页面显示）
  Future<BiometricResult> directAuthenticate() async {
    try {
      final bool didAuthenticate = await _auth.authenticate(
        localizedReason: ' ',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
        authMessages: <AuthMessages>[
          const AndroidAuthMessages(
            signInTitle: ' ',
            biometricHint: ' ',
            biometricNotRecognized: '指纹未识别，请重试',
            biometricSuccess: '验证成功',
            cancelButton: '取消',
          ),
        ],
      );

      return BiometricResult(
        success: didAuthenticate,
        error: didAuthenticate ? null : BiometricError.failed,
        message: didAuthenticate ? '认证成功' : '认证失败',
      );
    } on PlatformException catch (e) {
      return _handlePlatformException(e);
    } catch (e) {
      return BiometricResult(
        success: false,
        error: BiometricError.unknown,
        message: '发生未知错误：$e',
      );
    }
  }

  /// 强制认证（必须通过认证才能继续）
  Future<BiometricResult> authenticate({
    String localizedReason = '请验证指纹以继续',
    bool biometricOnly = true,
  }) async {
    try {
      // 首先检查设备支持
      if (!await isDeviceSupported()) {
        return BiometricResult(
          success: false,
          error: BiometricError.notSupported,
          message: '设备不支持生物识别',
        );
      }

      // 检查是否已设置生物识别
      if (!await isBiometricsAvailable()) {
        return BiometricResult(
          success: false,
          error: BiometricError.notEnrolled,
          message: '设备未设置生物识别',
        );
      }

      return directAuthenticate();
    } catch (e) {
      return BiometricResult(
        success: false,
        error: BiometricError.unknown,
        message: '发生未知错误：$e',
      );
    }
  }

  /// 处理平台异常
  BiometricResult _handlePlatformException(PlatformException exception) {
    switch (exception.code) {
      case auth_error.notAvailable:
        return BiometricResult(
          success: false,
          error: BiometricError.notAvailable,
          message: '生物识别功能不可用',
        );
      case auth_error.notEnrolled:
        return BiometricResult(
          success: false,
          error: BiometricError.notEnrolled,
          message: '设备未设置生物识别',
        );
      case auth_error.lockedOut:
        return BiometricResult(
          success: false,
          error: BiometricError.lockedOut,
          message: '尝试次数过多，请稍后再试',
        );
      case auth_error.permanentlyLockedOut:
        return BiometricResult(
          success: false,
          error: BiometricError.permanentlyLockedOut,
          message: '生物识别已被永久锁定，请使用其他方式解锁',
        );
      default:
        return BiometricResult(
          success: false,
          error: BiometricError.unknown,
          message: '认证失败：${exception.message}',
        );
    }
  }
}

/// 生物识别错误类型
enum BiometricError {
  notSupported, // 设备不支持
  notAvailable, // 功能不可用
  notEnrolled, // 未设置生物识别
  lockedOut, // 临时锁定
  permanentlyLockedOut, // 永久锁定
  failed, // 认证失败
  unknown, // 未知错误
}

/// 生物识别结果
class BiometricResult {
  final bool success;
  final BiometricError? error;
  final String message;

  const BiometricResult({
    required this.success,
    this.error,
    required this.message,
  });
}
