import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../utils/smart_status_bar.dart';
import '../controller/tfa_controller.dart';
import '../models/totp_account.dart';

/// 账户编辑页面
/// 用于新增或编辑2FA账户信息
/// 当account为null时为新增模式，否则为编辑模式
class EditAccountPage extends StatefulWidget {
  final TotpAccount? account;

  const EditAccountPage({super.key, this.account});

  @override
  State<EditAccountPage> createState() => _EditAccountPageState();
}

class _EditAccountPageState extends State<EditAccountPage>
    with SmartStatusBarMixin {
  final TfaController _tfaController = Get.find<TfaController>();
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _accountController;
  late final TextEditingController _secretController;
  late final TextEditingController _issuerController;

  late int _selectedPeriod;
  late int _selectedDigits;
  bool _isLoading = false;

  /// 是否为新增模式
  bool get _isAddMode => widget.account == null;

  @override
  void initState() {
    super.initState();
    // 根据是否有account数据来初始化表单字段
    _nameController = TextEditingController(text: widget.account?.name ?? '');
    _accountController = TextEditingController(text: widget.account?.account ?? '');
    _secretController = TextEditingController();
    _issuerController = TextEditingController(text: widget.account?.issuer ?? '');
    _selectedPeriod = widget.account?.period ?? 30;
    _selectedDigits = widget.account?.digits ?? 6;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _accountController.dispose();
    _secretController.dispose();
    _issuerController.dispose();
    super.dispose();
  }

  /// 提交表单
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    log('提交表单');

    try {
      if (_isAddMode) {
        // 新增模式
        await _tfaController.addAccountManually(
          name: _nameController.text.trim(),
          account: _accountController.text.trim(),
          secret: _secretController.text.trim(),
          issuer: _issuerController.text.trim().isEmpty
              ? _nameController.text.trim()
              : _issuerController.text.trim(),
          period: _selectedPeriod,
          digits: _selectedDigits,
        );
      } else {
        // 编辑模式
        final updatedAccount = widget.account!.copyWith(
          name: _nameController.text.trim(),
          account: _accountController.text.trim(),
          issuer: _issuerController.text.trim().isEmpty
              ? _nameController.text.trim()
              : _issuerController.text.trim(),
          period: _selectedPeriod,
          digits: _selectedDigits,
          updatedAt: DateTime.now(),
        );

        await _tfaController.updateAccount(updatedAccount);
      }

      // 只有在成功时才显示提示和返回
      if (mounted) {
        // 显示成功提示
        Get.snackbar('成功', _isAddMode ? '账户添加成功' : '账户更新成功', snackPosition: SnackPosition.TOP);
        Navigator.of(context).pop(); // 使用 Navigator.pop() 替代 Get.back()
      }
    } catch (e) {
      Get.snackbar(
        '错误',
        '${_isAddMode ? '添加' : '更新'}账户失败: $e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.withValues(alpha: 0.8),
        colorText: Colors.white,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// 验证密钥格式
  String? _validateSecret(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '请输入密钥';
    }

    final secret = value.trim().toUpperCase().replaceAll(' ', '');

    // 检查是否为有效的Base32字符
    final base32Regex = RegExp(r'^[A-Z2-7]+$');
    if (!base32Regex.hasMatch(secret)) {
      return '密钥只能包含A-Z和2-7的字符';
    }

    // 检查长度
    if (secret.length < 16) {
      return '密钥长度至少16位';
    }

    return null;
  }

  /// 删除账户
  Future<void> _deleteAccount() async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          '确认删除',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        content: Text(
          '确定要删除账户 "${widget.account!.name}" 吗？\n\n此操作无法撤销。',
          style: const TextStyle(fontSize: 14, color: Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text(
              '取消',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            style: TextButton.styleFrom(
              backgroundColor: Colors.red.withValues(alpha: 0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              '删除',
              style: TextStyle(
                color: Colors.red,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _isLoading = true;
      });

      try {
        await _tfaController.deleteAccount(widget.account!.id);

        // 只有在成功时才显示提示和返回
        if (mounted) {
          // 显示成功提示
          Get.snackbar('成功', '账户删除成功', snackPosition: SnackPosition.TOP);
          Navigator.of(context).pop(); // 使用 Navigator.pop() 替代 Get.back()
        }
      } catch (e) {
        // 如果发生异常，说明删除失败，不执行成功逻辑
        // 错误提示已在 controller 中显示
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: pageKey,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black87, size: 20),
            onPressed: () => Get.back(),
            style: IconButton.styleFrom(backgroundColor: Colors.transparent),
          ),
          title: Text(
            _isAddMode ? '添加账户' : '编辑账户',
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
          actions: _isAddMode ? null : [
            IconButton(
              icon: const Icon(
                Icons.delete_outline,
                color: Colors.red,
                size: 20,
              ),
              onPressed: _isLoading ? null : _deleteAccount,
              style: IconButton.styleFrom(backgroundColor: Colors.transparent),
            ),
            const SizedBox(width: 16),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 8),
                  // 页面标题
                  _buildPageHeader(),
                  const SizedBox(height: 32),
                  // 表单字段
                  _buildFormFields(),
                  const SizedBox(height: 32),
                  // 高级设置
                  _buildAdvancedSettings(),
                  const SizedBox(height: 32),
                  // 密钥信息（只在编辑模式下显示）
                  if (!_isAddMode) ...
                  [
                    _buildSecretInfo(),
                    const SizedBox(height: 40),
                  ],
                  // 操作按钮
                  _buildActionButtons(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 构建页面头部
  Widget _buildPageHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _isAddMode ? '添加新账户' : '编辑 ${widget.account!.name}',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _isAddMode ? '手动输入账户信息' : '修改账户信息和设置',
          style: const TextStyle(fontSize: 14, color: Colors.black54),
        ),
      ],
    );
  }

  /// 构建表单字段
  Widget _buildFormFields() {
    return Column(
      children: [
        _buildTextField(
          controller: _nameController,
          label: '账户名称',
          hint: '例如：Google、GitHub',
          icon: Icons.account_circle_outlined,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return '请输入账户名称';
            }
            return null;
          },
        ),
        const SizedBox(height: 20),
        _buildTextField(
          controller: _accountController,
          label: '用户名/邮箱',
          hint: '例如：user@example.com',
          icon: Icons.email_outlined,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return '请输入用户名或邮箱';
            }
            return null;
          },
        ),
        // 只在新增模式下显示密钥输入字段
        if (_isAddMode) ...
        [
          const SizedBox(height: 20),
          _buildTextField(
            controller: _secretController,
            label: '密钥',
            hint: '输入Base32格式的密钥',
            icon: Icons.key_outlined,
            validator: _validateSecret,
          ),
        ],
        const SizedBox(height: 20),
        _buildTextField(
          controller: _issuerController,
          label: '发行者（可选）',
          hint: '例如：公司名称',
          icon: Icons.business_outlined,
        ),
      ],
    );
  }

  /// 构建文本输入框
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.black54, size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.black87, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
    );
  }

  /// 构建高级设置
  Widget _buildAdvancedSettings() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '高级设置',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          // 时间间隔设置
          Row(
            children: [
              const Icon(Icons.timer_outlined, color: Colors.black54, size: 20),
              const SizedBox(width: 12),
              const Text(
                '时间间隔：',
                style: TextStyle(fontSize: 14, color: Colors.black87),
              ),
              const Spacer(),
              Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: DropdownButton<int>(
                  value: _selectedPeriod,
                  items: [15, 30, 60].map((period) {
                    return DropdownMenuItem(
                      value: period,
                      child: Text('$period秒'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedPeriod = value;
                      });
                    }
                  },
                  underline: const SizedBox(),
                  icon: Icon(
                    Icons.keyboard_arrow_down,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                  dropdownColor: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 位数设置
          Row(
            children: [
              const Icon(Icons.pin_outlined, color: Colors.black54, size: 20),
              const SizedBox(width: 12),
              const Text(
                '验证码位数：',
                style: TextStyle(fontSize: 14, color: Colors.black87),
              ),
              const Spacer(),
              Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: DropdownButton<int>(
                  value: _selectedDigits,
                  items: [6, 8].map((digits) {
                    return DropdownMenuItem(
                      value: digits,
                      child: Text('$digits位'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedDigits = value;
                      });
                    }
                  },
                  underline: const SizedBox(),
                  icon: Icon(
                    Icons.keyboard_arrow_down,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                  dropdownColor: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建密钥信息
  Widget _buildSecretInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '密钥信息',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.key_outlined, color: Colors.black54, size: 20),
              const SizedBox(width: 12),
              const Text(
                '密钥：',
                style: TextStyle(fontSize: 14, color: Colors.black87),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Text(
                    '${widget.account!.secret.substring(0, 8)}...',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                      fontFamily: 'monospace',
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.schedule_outlined,
                color: Colors.black54,
                size: 20,
              ),
              const SizedBox(width: 12),
              const Text(
                '创建时间：',
                style: TextStyle(fontSize: 14, color: Colors.black87),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${widget.account!.createdAt.year}-${widget.account!.createdAt.month.toString().padLeft(2, '0')}-${widget.account!.createdAt.day.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建操作按钮
  Widget _buildActionButtons() {
    return Column(
      children: [
        // 主要操作按钮
        SizedBox(
          width: double.infinity,
          height: 36,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _submitForm,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              elevation: 0,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    _isAddMode ? '添加账户' : '保存更改',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
          ),
        ),
        // 删除按钮（只在编辑模式下显示）
        if (!_isAddMode) ...
        [
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 36,
            child: OutlinedButton(
              onPressed: _isLoading ? null : _deleteAccount,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                backgroundColor: Colors.transparent,
                side: BorderSide(color: Colors.grey.shade300),
                elevation: 0,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              child: const Text(
                '删除账户',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.red,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
