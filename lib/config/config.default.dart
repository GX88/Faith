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
}
