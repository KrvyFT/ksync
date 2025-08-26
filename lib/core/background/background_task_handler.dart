import 'package:workmanager/workmanager.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../di/injection.dart';
import '../../domain/usecases/sync_engine_usecase.dart';
import '../../domain/entities/sync_log.dart';

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
      print('后台任务执行失败: $e');
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
    print('同步任务执行失败: $e');
    
    // 发送失败通知
    await _sendFailureNotification(e.toString());
    
    return false;
  }
}

/// 发送同步完成通知
Future<void> _sendNotification(SyncLog syncLog) async {
  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  
  // 初始化通知
  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const iosSettings = DarwinInitializationSettings();
  const initSettings = InitializationSettings(
    android: androidSettings,
    iOS: iosSettings,
  );
  
  await flutterLocalNotificationsPlugin.initialize(initSettings);
  
  // 创建通知
  const androidDetails = AndroidNotificationDetails(
    'sync_channel',
    '同步通知',
    channelDescription: 'WebDAV 同步状态通知',
    importance: Importance.low,
    priority: Priority.low,
  );
  
  const iosDetails = DarwinNotificationDetails();
  
  const details = NotificationDetails(
    android: androidDetails,
    iOS: iosDetails,
  );
  
  String title;
  String body;
  
  if (syncLog.status == SyncStatus.success) {
    title = '同步完成';
    body = '成功同步 ${syncLog.filesSynced} 个文件';
    if (syncLog.filesFailed > 0) {
      body += '，失败 ${syncLog.filesFailed} 个文件';
    }
  } else {
    title = '同步失败';
    body = syncLog.errorMessages.isNotEmpty 
        ? syncLog.errorMessages.first 
        : '未知错误';
  }
  
  await flutterLocalNotificationsPlugin.show(
    syncLog.hashCode,
    title,
    body,
    details,
  );
}

/// 发送同步失败通知
Future<void> _sendFailureNotification(String error) async {
  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  
  // 初始化通知
  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const iosSettings = DarwinInitializationSettings();
  const initSettings = InitializationSettings(
    android: androidSettings,
    iOS: iosSettings,
  );
  
  await flutterLocalNotificationsPlugin.initialize(initSettings);
  
  // 创建通知
  const androidDetails = AndroidNotificationDetails(
    'sync_channel',
    '同步通知',
    channelDescription: 'WebDAV 同步状态通知',
    importance: Importance.high,
    priority: Priority.high,
  );
  
  const iosDetails = DarwinNotificationDetails();
  
  const details = NotificationDetails(
    android: androidDetails,
    iOS: iosDetails,
  );
  
  await flutterLocalNotificationsPlugin.show(
    DateTime.now().millisecondsSinceEpoch,
    '同步失败',
    error,
    details,
  );
}
