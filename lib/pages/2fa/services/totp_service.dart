import 'dart:math';
import 'package:hive/hive.dart';
import 'package:otp/otp.dart';
import '../models/totp_account.dart';

/// TOTP服务类
/// 负责处理2FA相关的业务逻辑
class TotpService {
  static const String _boxName = 'totp_accounts';
  static TotpService? _instance;
  Box<Map>? _box;

  TotpService._();

  /// 获取单例实例
  static TotpService get instance {
    _instance ??= TotpService._();
    return _instance!;
  }

  /// 初始化Hive存储
  Future<void> init() async {
    if (_box == null || !_box!.isOpen) {
      _box = await Hive.openBox<Map>(_boxName);
    }
  }

  /// 生成随机密钥
  String generateSecret({int length = 32}) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
    final random = Random.secure();
    return List.generate(
      length,
      (index) => chars[random.nextInt(chars.length)],
    ).join();
  }

  /// 生成TOTP代码
  String generateTotpCode(String secret, {int period = 30, int digits = 6, String algorithm = 'SHA1'}) {
    try {
      // 清理密钥格式
      final cleanSecret = secret.toUpperCase().replaceAll(RegExp(r'[^A-Z2-7]'), '');
      
      // 验证密钥格式
      if (!_isValidBase32(cleanSecret)) {
        throw Exception('无效的Base32密钥格式');
      }
      
      // 获取当前时间戳（毫秒）- 根据OTP库文档，应该使用毫秒时间戳
      final now = DateTime.now().millisecondsSinceEpoch;
      
      Algorithm otpAlgorithm;
      switch (algorithm.toUpperCase()) {
        case 'SHA256':
          otpAlgorithm = Algorithm.SHA256;
          break;
        case 'SHA512':
          otpAlgorithm = Algorithm.SHA512;
          break;
        case 'SHA1':
        default:
          otpAlgorithm = Algorithm.SHA1;
          break;
      }
      
      // 生成TOTP代码 - 直接使用毫秒时间戳
      final code = OTP.generateTOTPCodeString(
        cleanSecret,
        now, // 直接使用毫秒时间戳
        length: digits,
        interval: period,
        algorithm: otpAlgorithm,
        isGoogle: true,
      );
      
      return code;
    } catch (e) {
      throw Exception('生成TOTP代码失败: $e');
    }
  }

  /// 验证TOTP代码
  bool verifyTotpCode(
    String secret,
    String code, {
    int period = 30,
    int digits = 6,
    String algorithm = 'SHA1',
  }) {
    try {
      // 清理密钥格式
      final cleanSecret = secret.toUpperCase().replaceAll(RegExp(r'[^A-Z2-7]'), '');
      
      // 验证密钥格式
      if (!_isValidBase32(cleanSecret)) {
        return false;
      }
      
      // 获取当前时间戳（毫秒）
      final now = DateTime.now().millisecondsSinceEpoch;
      
      Algorithm otpAlgorithm;
      switch (algorithm.toUpperCase()) {
        case 'SHA256':
          otpAlgorithm = Algorithm.SHA256;
          break;
        case 'SHA512':
          otpAlgorithm = Algorithm.SHA512;
          break;
        case 'SHA1':
        default:
          otpAlgorithm = Algorithm.SHA1;
          break;
      }
      
      // 验证当前时间窗口和前后一个时间窗口的代码（允许时间偏差）
      final periodMs = period * 1000; // 转换为毫秒
      for (int i = -1; i <= 1; i++) {
        final testTime = now + (i * periodMs);
        final generatedCode = OTP.generateTOTPCodeString(
          cleanSecret,
          testTime,
          length: digits,
          interval: period,
          algorithm: otpAlgorithm,
          isGoogle: true,
        );
        if (generatedCode == code) {
          return true;
        }
      }
      
      return false;
    } catch (e) {
      return false;
    }
  }

  /// 生成二维码URI
  String generateQrCodeUri({
    required String secret,
    required String account,
    required String issuer,
    int period = 30,
    int digits = 6,
    String algorithm = 'SHA1',
  }) {
    final uri = Uri(
      scheme: 'otpauth',
      host: 'totp',
      path: '/$issuer:$account',
      queryParameters: {
        'secret': secret,
        'issuer': issuer,
        'algorithm': algorithm,
        'digits': digits.toString(),
        'period': period.toString(),
      },
    );
    return uri.toString();
  }

  /// 解析二维码URI
  TotpAccount? parseQrCodeUri(String uri) {
    try {
      final parsedUri = Uri.parse(uri);

      if (parsedUri.scheme != 'otpauth' || parsedUri.host != 'totp') {
        return null;
      }

      final path = parsedUri.path.substring(1); // 移除开头的'/'
      final parts = path.split(':');

      String issuer = '';
      String account = '';

      if (parts.length == 2) {
        issuer = parts[0];
        account = parts[1];
      } else if (parts.length == 1) {
        account = parts[0];
        issuer = parsedUri.queryParameters['issuer'] ?? '';
      } else {
        return null;
      }

      final secret = parsedUri.queryParameters['secret'];
      if (secret == null || secret.isEmpty) {
        return null;
      }

      // 清理密钥格式：移除空格并转换为大写
      final cleanSecret = secret.toUpperCase().replaceAll(' ', '').replaceAll('-', '');
      
      // 验证Base32格式
      if (!_isValidBase32(cleanSecret)) {
        return null;
      }
      
      final now = DateTime.now();
      return TotpAccount(
        id: _generateId(),
        name: issuer.isNotEmpty ? issuer : account,
        account: account,
        secret: cleanSecret,
        issuer: issuer,
        period: int.tryParse(parsedUri.queryParameters['period'] ?? '30') ?? 30,
        digits: int.tryParse(parsedUri.queryParameters['digits'] ?? '6') ?? 6,
        algorithm: parsedUri.queryParameters['algorithm'] ?? 'SHA1',
        createdAt: now,
        updatedAt: now,
      );
    } catch (e) {
      return null;
    }
  }

  /// 保存账户
  Future<void> saveAccount(TotpAccount account) async {
    await init();
    await _box!.put(account.id, account.toMap());
  }

  /// 获取所有账户
  Future<List<TotpAccount>> getAllAccounts() async {
    await init();
    final accounts = <TotpAccount>[];

    for (final key in _box!.keys) {
      final data = _box!.get(key);
      if (data != null) {
        try {
          final account = TotpAccount.fromMap(Map<String, dynamic>.from(data));
          accounts.add(account);
        } catch (e) {
          // 忽略无效数据
        }
      }
    }

    // 按创建时间排序
    accounts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return accounts;
  }

  /// 根据ID获取账户
  Future<TotpAccount?> getAccountById(String id) async {
    await init();
    final data = _box!.get(id);
    if (data != null) {
      try {
        return TotpAccount.fromMap(Map<String, dynamic>.from(data));
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  /// 更新账户
  Future<void> updateAccount(TotpAccount account) async {
    await init();
    final updatedAccount = account.copyWith(updatedAt: DateTime.now());
    await _box!.put(account.id, updatedAccount.toMap());
  }

  /// 删除账户
  Future<void> deleteAccount(String id) async {
    await init();
    await _box!.delete(id);
  }

  /// 清空所有账户
  Future<void> clearAllAccounts() async {
    await init();
    await _box!.clear();
  }

  /// 生成唯一ID
  String _generateId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(999999);
    return '${timestamp}_$random';
  }

  /// 验证Base32格式
  bool _isValidBase32(String secret) {
    // Base32字符集：A-Z和2-7
    final base32Regex = RegExp(r'^[A-Z2-7]+$');
    return base32Regex.hasMatch(secret) && secret.length >= 16;
  }

  /// 获取剩余时间（秒）
  int getRemainingTime(int period) {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final remaining = period - (now % period);
    return remaining == period ? 0 : remaining; // 修复边界情况
  }

  /// 获取进度百分比
  double getProgress(int period) {
    final remaining = getRemainingTime(period);
    return (period - remaining) / period;
  }

  /// 调试方法：获取详细的TOTP信息
  Map<String, dynamic> getTotpDebugInfo(String secret, {int period = 30, int digits = 6, String algorithm = 'SHA1'}) {
    try {
      final cleanSecret = secret.toUpperCase().replaceAll(RegExp(r'[^A-Z2-7]'), '');
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      final nowSec = nowMs ~/ 1000;
      final timeStep = nowSec ~/ period;
      final remaining = getRemainingTime(period);
      final progress = getProgress(period);
      
      return {
        'originalSecret': secret,
        'cleanSecret': cleanSecret,
        'isValidSecret': _isValidBase32(cleanSecret),
        'currentTimeMs': nowMs,
        'currentTimeSec': nowSec,
        'timeStep': timeStep,
        'period': period,
        'remaining': remaining,
        'progress': progress,
        'algorithm': algorithm,
        'digits': digits,
      };
    } catch (e) {
      return {
        'error': e.toString(),
      };
    }
  }

  /// 关闭存储
  Future<void> close() async {
    if (_box != null && _box!.isOpen) {
      await _box!.close();
    }
  }
}
