import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../utils/smart_status_bar.dart';
import '../controller/tfa_controller.dart';
import '../models/totp_account.dart';
import 'edit_account_page.dart';
import 'qr_scanner_page.dart';

class TfaPage extends StatefulWidget {
  const TfaPage({super.key});

  @override
  State<TfaPage> createState() => _TfaPageState();
}

class _TfaPageState extends State<TfaPage> with SmartStatusBarMixin {
  final TfaController _tfaController = Get.put(TfaController());
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tfaController.loadAccounts();

    // 页面构建完成后分析并设置状态栏样式
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SmartStatusBar.analyzeAndSetStatusBar();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// 显示添加选项
  void _showAddOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 32,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                '添加2FA账户',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 20),
              _buildAddOption(
                icon: Icons.qr_code_scanner_outlined,
                title: '扫描二维码',
                subtitle: '使用相机扫描二维码',
                onTap: () {
                  Get.back();
                  Get.to(() => const QrScannerPage());
                },
              ),
              _buildAddOption(
                icon: Icons.edit_outlined,
                title: '手动添加',
                subtitle: '手动输入账户信息',
                onTap: () {
                  Get.back();
                  Get.to(() => const EditAccountPage());
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建添加选项
  Widget _buildAddOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Colors.grey[700], size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 16, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: pageKey,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: const Color.fromARGB(0, 255, 0, 0),
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black, size: 24),
            onPressed: () => Get.back(),
          ),
          title: const Text(
            '身份验证器',
            style: TextStyle(
              color: Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.add, color: Colors.black, size: 24),
              onPressed: _showAddOptions,
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              // 搜索栏
              _buildSearchBar(),
              const SizedBox(height: 16),
              // 账户列表
              Expanded(child: Obx(() => _buildAccountList())),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建搜索栏
  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _tfaController.setSearchKeyword,
        decoration: InputDecoration(
          hintText: '搜索账户...',
          hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
          prefixIcon: Icon(Icons.search, color: Colors.grey[400], size: 20),
          suffixIcon: Obx(
            () => _tfaController.searchKeyword.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.close, color: Colors.grey[400], size: 20),
                    onPressed: () {
                      _searchController.clear();
                      _tfaController.clearSearch();
                    },
                  )
                : const SizedBox.shrink(),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  /// 构建账户列表
  Widget _buildAccountList() {
    if (_tfaController.isLoading.value) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.black),
      );
    }

    final accounts = _tfaController.filteredAccounts;

    if (accounts.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _tfaController.refreshData,
      color: Colors.black,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: accounts.length,
        itemBuilder: (context, index) {
          final account = accounts[index];
          return _buildAccountCard(account);
        },
      ),
    );
  }

  /// 构建空状态
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(40),
            ),
            child: Icon(
              Icons.security_outlined,
              size: 40,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            '还没有2FA账户',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '点击右上角的 + 按钮添加您的第一个账户',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _showAddOptions,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: const Text(
              '添加账户',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建账户卡片
  Widget _buildAccountCard(TotpAccount account) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: InkWell(
        onTap: () => Get.to(() => EditAccountPage(account: account)),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 账户信息
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        account.name.isNotEmpty
                            ? account.name[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          account.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          account.account,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.more_vert,
                      color: Colors.grey[400],
                      size: 20,
                    ),
                    onPressed: () =>
                        Get.to(() => EditAccountPage(account: account)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // TOTP代码和进度
              Obx(() {
                final code = _tfaController.totpCodes[account.id] ?? '------';
                final progress = _tfaController.progress.value;
                final remainingTime = _tfaController.remainingTime.value;

                return Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _tfaController.copyTotpCode(account.id),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  code,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'monospace',
                                    color: Colors.black,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.copy,
                                size: 16,
                                color: Colors.grey[500],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // 倒计时和进度环
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: Stack(
                        children: [
                          Center(
                            child: CircularProgressIndicator(
                              value: progress,
                              backgroundColor: Colors.grey[200],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                remainingTime <= 5
                                    ? Colors.red[400]!
                                    : Colors.black,
                              ),
                              strokeWidth: 2,
                            ),
                          ),
                          Center(
                            child: Text(
                              remainingTime.toString(),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: remainingTime <= 5
                                    ? Colors.red[400]
                                    : Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
