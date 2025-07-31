import 'config.default.dart';

class LocalConfig extends Config {
  @override
  String get apiBaseUrl => 'http://localhost:8080';

  @override
  bool get enableLogging => true;

  @override
  int get cacheMaxAge => 0; // 开发环境禁用缓存

  // 是否开启指纹认证
  @override
  bool get loginAuthentication => false;

  // 开发环境更新APK配置
  @override
  String get updateApkUrl => 'https://cdn4.cdn-telegram.org/file/Telegram.apk';
  @override
  String get updateApkFileName => 'faith.dev.apk';
}
