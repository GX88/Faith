import 'config.default.dart';

class LocalConfig extends Config {
  @override
  String get apiBaseUrl => 'http://localhost:8080';

  @override
  bool get enableLogging => true;

  @override
  int get cacheMaxAge => 0; // 开发环境禁用缓存
}
