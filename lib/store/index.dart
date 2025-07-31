import 'package:hive_flutter/hive_flutter.dart';

import 'app_state.dart';

/// 统一初始化所有本地持久化store
Future<void> initAllStores() async {
  await Hive.initFlutter();
  await AppStateStore.init();
}
