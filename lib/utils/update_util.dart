import 'dart:isolate';
import 'dart:ui';

import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

// 将 typedef 移到类外部
typedef DownloadProgressCallback =
    void Function(String id, DownloadTaskStatus status, int progress);

@pragma('vm:entry-point')
class DownloadUtils {
  // 单例模式
  static final DownloadUtils _instance = DownloadUtils._internal();
  factory DownloadUtils() => _instance;
  DownloadUtils._internal();

  // 接收端口
  ReceivePort? _port; // 改为可空
  // 回调列表
  final List<DownloadProgressCallback> _callbacks = [];
  // 是否已初始化
  bool _isInit = false;

  /// 初始化下载器
  Future<void> initialize() async {
    if (_isInit) return;

    await FlutterDownloader.initialize(debug: true);

    // 确保之前的端口被关闭
    _unbindBackgroundIsolate();
    // 注册新的后台隔离回调
    _bindBackgroundIsolate();

    _isInit = true;
  }

  /// 绑定后台隔离
  void _bindBackgroundIsolate() {
    _port = ReceivePort();
    IsolateNameServer.removePortNameMapping('downloader_send_port');
    IsolateNameServer.registerPortWithName(
      _port!.sendPort,
      'downloader_send_port',
    );
    print('DownloadUtils: _bindBackgroundIsolate 注册端口');
    _port!.listen((dynamic data) {
      print('DownloadUtils: received data from isolate: $data');
      if (data is List && data.length == 3) {
        final String id = data[0] as String;
        final DownloadTaskStatus status = DownloadTaskStatus.fromInt(
          data[1] as int,
        );
        final int progress = data[2] as int;
        for (final callback in _callbacks) {
          print('DownloadUtils: 调用 callback $id, $status, $progress');
          callback(id, status, progress);
        }
      }
    });
    FlutterDownloader.registerCallback(downloadCallback, step: 1);
    print('DownloadUtils: registerCallback 完成');
  }

  /// 解绑后台隔离
  void _unbindBackgroundIsolate() {
    IsolateNameServer.removePortNameMapping('downloader_send_port');
    _port?.close(); // 关闭端口
    _port = null;
  }

  /// 下载回调函数
  @pragma('vm:entry-point')
  static void downloadCallback(String id, int status, int progress) {
    print('DownloadUtils: downloadCallback called: $id, $status, $progress');
    final SendPort? sendPort = IsolateNameServer.lookupPortByName(
      'downloader_send_port',
    );
    if (sendPort == null) {
      print('DownloadUtils: sendPort is null!');
      return;
    }
    sendPort.send([id, status, progress]);
  }

  /// 注册下载状态回调
  void registerCallback(DownloadProgressCallback callback) {
    if (!_callbacks.contains(callback)) {
      _callbacks.add(callback);
    }
  }

  /// 取消注册下载状态回调
  void unregisterCallback(DownloadProgressCallback callback) {
    _callbacks.remove(callback);
  }

  /// 开始下载
  Future<String?> startDownload({
    required String url,
    String? fileName,
    Map<String, String>? headers,
    bool showNotification = true,
    bool openFileFromNotification = true,
    String? savedDir,
    bool requiresStorageNotLow = true,
  }) async {
    try {
      // 检查存储权限
      if (!await _checkPermission()) {
        throw Exception('Storage permission denied');
      }

      // 获取存储目录
      final dir = savedDir ?? (await _getDefaultDownloadDir());
      if (dir == null) {
        throw Exception('Cannot get download directory');
      }

      // 开始下载任务
      return await FlutterDownloader.enqueue(
        url: url,
        fileName: fileName,
        savedDir: dir,
        showNotification: showNotification,
        openFileFromNotification: openFileFromNotification,
        headers: headers ?? {}, // 确保headers不为null
        saveInPublicStorage: true, // 新增参数，保存到公共存储
      );
    } catch (e) {
      print('Download error: $e');
      return null;
    }
  }

  /// 获取默认下载目录
  Future<String?> _getDefaultDownloadDir() async {
    try {
      final dir = await getExternalStorageDirectory();
      return dir?.path;
    } catch (e) {
      print('Get directory error: $e');
      return null;
    }
  }

  /// 检查存储权限
  Future<bool> _checkPermission() async {
    if (await Permission.storage.isDenied) {
      final status = await Permission.storage.request();
      return status.isGranted;
    }
    return true;
  }

  /// 暂停下载
  Future<bool> pauseDownload(String taskId) async {
    try {
      await FlutterDownloader.pause(taskId: taskId);
      return true;
    } catch (e) {
      print('Pause download error: $e');
      return false;
    }
  }

  /// 恢复下载
  Future<String?> resumeDownload(String taskId) async {
    try {
      return await FlutterDownloader.resume(taskId: taskId);
    } catch (e) {
      print('Resume download error: $e');
      return null;
    }
  }

  /// 重试下载
  Future<String?> retryDownload(String taskId) async {
    try {
      return await FlutterDownloader.retry(taskId: taskId);
    } catch (e) {
      print('Retry download error: $e');
      return null;
    }
  }

  /// 取消下载
  Future<bool> cancelDownload(String taskId) async {
    try {
      await FlutterDownloader.cancel(taskId: taskId);
      return true;
    } catch (e) {
      print('Cancel download error: $e');
      return false;
    }
  }

  /// 删除下载任务
  Future<bool> removeDownload(
    String taskId, {
    bool shouldDeleteContent = false,
  }) async {
    try {
      await FlutterDownloader.remove(
        taskId: taskId,
        shouldDeleteContent: shouldDeleteContent,
      );
      return true;
    } catch (e) {
      print('Remove download error: $e');
      return false;
    }
  }

  /// 加载所有下载任务
  Future<List<DownloadTask>?> loadTasks() async {
    try {
      return await FlutterDownloader.loadTasks();
    } catch (e) {
      print('Load tasks error: $e');
      return null;
    }
  }

  /// 清理资源
  void dispose() {
    _callbacks.clear();
    _unbindBackgroundIsolate();
    _isInit = false; // 重置初始化状态
  }
}
