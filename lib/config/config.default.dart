import 'package:flutter/foundation.dart';

import 'config.local.dart';
import 'config.prod.dart';

class Config {
  // 配置项
  String get apiBaseUrl => 'https://api.example.com';
  int get apiTimeout => 30000; // 30秒
  bool get enableLogging => true;
  String get appName => 'Faith App';
  String get appVersion => '1.0.0';
  int get cacheMaxAge => 7200; // 2小时

  // 新增：更新APK下载地址和文件名配置（由子类实现）
  String get updateApkUrl => '';
  String get updateApkFileName => '';

  // Github 更新配置
  String get appUpdateUrl =>
      'https://api.github.com/repos/GX88/faith-release/releases/latest';

  // 单例实现
  static Config? _instance;

  static Config get instance {
    _instance ??= kReleaseMode ? ProdConfig() : LocalConfig();
    return _instance!;
  }

  // 手动设置配置（用于测试）
  static void setConfig(Config config) {
    _instance = config;
  }

  // 环境判断
  static bool get isProd => instance is ProdConfig;
  static bool get isLocal => instance is LocalConfig;

  // 是否开启指纹认证，默认false，子类可覆盖
  bool get loginAuthentication => false;
}
