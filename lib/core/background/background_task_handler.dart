import 'package:workmanager/workmanager.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../di/injection.dart';
import '../../domain/usecases/sync_engine_usecase.dart';
import '../../domain/entities/sync_log.dart';
import '../utils/logging.dart';

/// 后台任务回调函数
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      switch (task) {
        case 'syncJob':
          return await _handleSyncJob();
        default:
          return false;
      }
    } catch (e) {
      // print('后台任务执行失败: $e');
      return false;
    }
  });
}

/// 处理同步任务
Future<bool> _handleSyncJob() async {
  try {
    // 初始化依赖注入
    await configureDependencies();

    // 获取同步引擎用例
    final syncEngine = await getIt.getAsync<SyncEngineUseCase>();

    // 执行同步
    final syncLog = await syncEngine.executeSync();

    // 发送通知
    await _sendNotification(syncLog);

    return syncLog.status == SyncStatus.success;
  } catch (e) {
    // print('同步任务执行失败: $e');

    // 记录错误
    logger.error('Background sync job failed', e);

    // 发送失败通知
    await _sendFailureNotification(e.toString());

    return false;
  }
}

Future<FlutterLocalNotificationsPlugin> _initializeNotifications() async {
  final plugin = FlutterLocalNotificationsPlugin();
  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const iosSettings = DarwinInitializationSettings();
  const initSettings = InitializationSettings(
    android: androidSettings,
    iOS: iosSettings,
  );
  await plugin.initialize(initSettings);
  return plugin;
}

NotificationDetails _getNotificationDetails(bool isError) {
  final importance = isError ? Importance.high : Importance.high;
  final priority = isError ? Priority.high : Priority.high;

  final androidDetails = AndroidNotificationDetails(
    'sync_channel',
    '同步通知',
    channelDescription: 'WebDAV 同步状态通知',
    importance: importance,
    priority: priority,
  );
  const iosDetails = DarwinNotificationDetails();
  return NotificationDetails(android: androidDetails, iOS: iosDetails);
}

Future<void> _showNotification(
    {required String title, required String body, bool isError = false}) async {
  final plugin = await _initializeNotifications();
  final details = _getNotificationDetails(isError);
  await plugin.show(
    DateTime.now().millisecondsSinceEpoch, // Use timestamp for unique ID
    title,
    body,
    details,
  );
}

/// 发送同步完成通知
Future<void> _sendNotification(SyncLog syncLog) async {
  String title;
  String body;
  bool isError = false;

  if (syncLog.status == SyncStatus.success) {
    if (syncLog.filesFailed > 0) {
      title = '部分同步完成';
      body = '成功 ${syncLog.filesSynced}，失败 ${syncLog.filesFailed}';
      isError = true; // 部分失败也算是一种需要用户关注的状态
    } else if (syncLog.filesSynced == 0) {
      title = '文件已是最新';
      body = '本地与云端文件一致';
    } else {
      title = '同步完成';
      body = '成功同步 ${syncLog.filesSynced} 个文件';
    }
  } else {
    title = '同步失败';
    body =
        syncLog.errorMessages.isNotEmpty ? syncLog.errorMessages.first : '未知错误';
    isError = true;
  }

  await _showNotification(title: title, body: body, isError: isError);
}

/// 发送同步失败通知
Future<void> _sendFailureNotification(String error) async {
  await _showNotification(title: '同步失败', body: error, isError: true);
}
