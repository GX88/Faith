import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../models/totp_account.dart';
import '../services/totp_service.dart';

/// 2FA页面控制器
/// 负责管理2FA页面的状态和业务逻辑
class TfaController extends GetxController {
  final TotpService _totpService = TotpService.instance;

  /// 账户列表
  final RxList<TotpAccount> accounts = <TotpAccount>[].obs;

  /// 加载状态
  final RxBool isLoading = false.obs;

  /// TOTP代码映射
  final RxMap<String, String> totpCodes = <String, String>{}.obs;

  /// 剩余时间映射
  final RxMap<String, int> remainingTimes = <String, int>{}.obs;

  /// 进度映射
  final RxMap<String, double> progressValues = <String, double>{}.obs;

  /// 定时器
  Timer? _timer;

  /// 搜索关键词
  final RxString searchKeyword = ''.obs;

  /// 过滤后的账户列表
  List<TotpAccount> get filteredAccounts {
    if (searchKeyword.value.isEmpty) {
      return accounts;
    }
    return accounts.where((account) {
      final keyword = searchKeyword.value.toLowerCase();
      return account.name.toLowerCase().contains(keyword) ||
          account.account.toLowerCase().contains(keyword) ||
          account.issuer.toLowerCase().contains(keyword);
    }).toList();
  }

  /// 当前进度（0.0-1.0）
  RxDouble get progress {
    if (progressValues.isEmpty) {
      return 0.0.obs;
    }
    // 返回第一个账户的进度，或者可以根据需要修改逻辑
    return (progressValues.values.first).obs;
  }

  /// 当前剩余时间（秒）
  RxInt get remainingTime {
    if (remainingTimes.isEmpty) {
      return 0.obs;
    }
    // 返回第一个账户的剩余时间，或者可以根据需要修改逻辑
    return (remainingTimes.values.first).obs;
  }

  @override
  void onInit() {
    super.onInit();
    _initService();
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }

  /// 初始化服务
  Future<void> _initService() async {
    try {
      isLoading.value = true;
      await _totpService.init();
      await loadAccounts();
      _startTimer();
    } catch (e) {
      Get.snackbar(
        '错误',
        '初始化失败: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.8),
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// 加载所有账户
  Future<void> loadAccounts() async {
    try {
      final loadedAccounts = await _totpService.getAllAccounts();
      accounts.value = loadedAccounts;
      _updateAllCodes();
    } catch (e) {
      Get.snackbar(
        '错误',
        '加载账户失败: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.8),
        colorText: Colors.white,
      );
    }
  }

  /// 添加账户
  Future<void> addAccount(TotpAccount account) async {
    try {
      await _totpService.saveAccount(account);
      accounts.add(account);
      _updateCodeForAccount(account);
      Get.snackbar(
        '成功',
        '账户添加成功',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.withValues(alpha: 0.8),
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        '错误',
        '添加账户失败: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.8),
        colorText: Colors.white,
      );
    }
  }

  /// 更新账户
  Future<void> updateAccount(TotpAccount account) async {
    try {
      await _totpService.updateAccount(account);
      final index = accounts.indexWhere((a) => a.id == account.id);
      if (index != -1) {
        accounts[index] = account;
        _updateCodeForAccount(account);
      }
      // 移除成功时的 Snackbar，让调用方处理
    } catch (e) {
      // 保留错误提示
      Get.snackbar(
        '错误',
        '更新账户失败: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.8),
        colorText: Colors.white,
      );
      rethrow; // 重新抛出异常让调用方知道失败了
    }
  }

  /// 删除账户
  Future<void> deleteAccount(String accountId) async {
    try {
      await _totpService.deleteAccount(accountId);
      accounts.removeWhere((account) => account.id == accountId);
      totpCodes.remove(accountId);
      remainingTimes.remove(accountId);
      progressValues.remove(accountId);
      // 移除成功时的 Snackbar，让调用方处理
    } catch (e) {
      // 保留错误提示
      Get.snackbar(
        '错误',
        '删除账户失败: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.8),
        colorText: Colors.white,
      );
      rethrow; // 重新抛出异常让调用方知道失败了
    }
  }

  /// 从二维码URI添加账户
  Future<void> addAccountFromQrCode(String qrCodeData) async {
    final account = _totpService.parseQrCodeUri(qrCodeData);
    if (account == null) {
      String errorMessage = '无效的二维码格式';

      // 提供更详细的错误信息
      if (!qrCodeData.startsWith('otpauth://totp/')) {
        errorMessage = '不是有效的TOTP二维码';
      } else if (!qrCodeData.contains('secret=')) {
        errorMessage = '二维码中缺少密钥信息';
      } else {
        // 提取密钥并检查格式
        final uri = Uri.tryParse(qrCodeData);
        if (uri != null) {
          final secret = uri.queryParameters['secret'];
          if (secret != null) {
            final cleanSecret = secret
                .toUpperCase()
                .replaceAll(' ', '')
                .replaceAll('-', '');
            if (cleanSecret.length < 16) {
              errorMessage = '密钥长度不足，至少需要16个字符';
            } else if (!RegExp(r'^[A-Z2-7]+$').hasMatch(cleanSecret)) {
              errorMessage = '密钥格式无效，必须是Base32编码';
            }
          }
        }
      }

      throw Exception(errorMessage);
    }

    // 检查是否已存在相同账户
    final existingAccount = accounts.firstWhereOrNull(
      (a) => a.account == account.account && a.issuer == account.issuer,
    );

    if (existingAccount != null) {
      throw Exception('该账户已存在');
    }

    // 添加账户
    await _totpService.saveAccount(account);
    accounts.add(account);
    _updateCodeForAccount(account);
  }

  /// 手动添加账户
  Future<void> addAccountManually({
    required String name,
    required String account,
    required String secret,
    String? issuer,
    int period = 30,
    int digits = 6,
  }) async {
    try {
      final now = DateTime.now();
      final newAccount = TotpAccount(
        id: _generateId(),
        name: name,
        account: account,
        secret: secret.toUpperCase().replaceAll(' ', ''),
        issuer: issuer ?? name,
        period: period,
        digits: digits,
        createdAt: now,
        updatedAt: now,
      );

      // 验证密钥是否有效
      try {
        _totpService.generateTotpCode(
          newAccount.secret,
          period: newAccount.period,
          digits: newAccount.digits,
          algorithm: newAccount.algorithm,
        );
      } catch (e) {
        Get.snackbar(
          '错误',
          '无效的密钥格式',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withValues(alpha: 0.8),
          colorText: Colors.white,
        );
        return;
      }

      await addAccount(newAccount);
    } catch (e) {
      Get.snackbar(
        '错误',
        '添加账户失败: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.8),
        colorText: Colors.white,
      );
    }
  }

  /// 复制TOTP代码到剪贴板
  Future<void> copyTotpCode(String accountId) async {
    final code = totpCodes[accountId];
    if (code != null && code != '错误') {
      try {
        await Clipboard.setData(ClipboardData(text: code));
        Get.snackbar('成功', '验证码已复制到剪贴板', snackPosition: SnackPosition.TOP);
      } catch (e) {
        Get.snackbar('错误', '复制失败', snackPosition: SnackPosition.TOP);
      }
    }
  }

  /// 设置搜索关键词
  void setSearchKeyword(String keyword) {
    searchKeyword.value = keyword;
  }

  /// 清空搜索
  void clearSearch() {
    searchKeyword.value = '';
  }

  /// 启动定时器
  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateAllCodes();
    });
  }

  /// 更新所有账户的TOTP代码
  void _updateAllCodes() {
    for (final account in accounts) {
      _updateCodeForAccount(account);
    }
  }

  /// 更新单个账户的TOTP代码
  void _updateCodeForAccount(TotpAccount account) {
    try {
      final code = _totpService.generateTotpCode(
        account.secret,
        period: account.period,
        digits: account.digits,
        algorithm: account.algorithm,
      );
      final remaining = _totpService.getRemainingTime(account.period);
      final progress = _totpService.getProgress(account.period);

      totpCodes[account.id] = code;
      remainingTimes[account.id] = remaining;
      progressValues[account.id] = progress;
    } catch (e) {
      totpCodes[account.id] = '错误';
      remainingTimes[account.id] = 0;
      progressValues[account.id] = 0.0;
    }
  }

  /// 生成唯一ID
  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  /// 刷新数据
  @override
  Future<void> refresh() async {
    await loadAccounts();
  }

  /// 刷新数据（别名方法）
  Future<void> refreshData() async {
    await refresh();
  }
}
