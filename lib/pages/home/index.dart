import 'package:faith/router/index.dart';
import 'package:faith/utils/biometric_auth.dart';
import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('首页')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 直接认证按钮
            ElevatedButton(
              onPressed: () async {
                final biometricAuth = BiometricAuth();
                final result = await biometricAuth.directAuthenticate();
                if (result.success) {
                  // 认证成功的处理
                  if (context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text('直接认证成功')));
                  }
                }
              },
              child: const Text('测试直接认证'),
            ),
            const SizedBox(height: 20),
            // 可返回的认证页面
            ElevatedButton(
              onPressed: () {
                RouteHelper.push(RoutePath.biometricAuth);
              },
              child: const Text('测试可返回的认证页面'),
            ),
            const SizedBox(height: 20),
            // 不可返回的认证页面
            ElevatedButton(
              onPressed: () {
                RouteHelper.push(
                  RoutePath.biometricAuth,
                  arguments: {
                    'canPop': false, // 禁止返回
                    'showBackButton': false, // 不显示返回按钮
                    'nextRoute': RoutePath.home, // 认证成功后返回首页
                    'title': '安全验证',
                    'description': '您必须完成认证后才可以继续使用',
                  },
                );
              },
              child: const Text('测试强制认证（不可返回）'),
            ),
          ],
        ),
      ),
    );
  }
}
