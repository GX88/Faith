import 'config.default.dart';

class ProdConfig extends Config {
  @override
  String get apiBaseUrl => 'https://api.production.com';

  @override
  bool get enableLogging => false; // 生产环境禁用日志

  @override
  int get apiTimeout => 15000; // 生产环境超时时间更短

  @override
  int get cacheMaxAge => 86400; // 生产环境缓存时间更长 (24小时)

  // 是否开启指纹认证
  @override
  bool get loginAuthentication => true;

  // 生产环境更新APK配置
  @override
  String get updateApkUrl =>
      'https://yourdomain.com/path/to/your_app_release.apk';
  @override
  String get updateApkFileName => 'faith.apk';
}
