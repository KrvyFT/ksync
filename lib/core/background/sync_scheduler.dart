import 'package:workmanager/workmanager.dart';

import '../../domain/entities/sync_settings.dart';
import 'background_task_handler.dart';

/// 同步调度器
class SyncScheduler {
  static const String _syncTaskName = 'webdav-sync-task';
  static const String _syncTaskTag = 'syncJob';

  /// 初始化 WorkManager
  static Future<void> initialize() async {
    await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);
  }

  /// 调度周期性同步任务
  static Future<void> schedulePeriodicSync(SyncSettings settings) async {
    if (!settings.canAutoSync) {
      await cancelSync();
      return;
    }

    final frequency = settings.syncFrequencyDuration;
    if (frequency == null) {
      await cancelSync();
      return;
    }

    // 构建约束条件
    final constraints = Constraints(
      networkType: settings.syncOnlyOnWifi 
          ? NetworkType.unmetered 
          : NetworkType.connected,
      requiresCharging: settings.syncOnlyWhenCharging,
      requiresDeviceIdle: settings.syncOnlyWhenIdle,
      requiresBatteryNotLow: settings.syncOnlyWhenBatteryNotLow,
    );

    // 注册周期性任务
    await Workmanager().registerPeriodicTask(
      _syncTaskName,
      _syncTaskTag,
      frequency: frequency,
      initialDelay: const Duration(minutes: 5),
      constraints: constraints,
      existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
    );
  }

  /// 调度一次性同步任务
  static Future<void> scheduleOneTimeSync({
    Duration delay = Duration.zero,
    bool requiresCharging = false,
    bool requiresWifi = true,
  }) async {
    final constraints = Constraints(
      networkType: requiresWifi ? NetworkType.unmetered : NetworkType.connected,
      requiresCharging: requiresCharging,
    );

    await Workmanager().registerOneOffTask(
      '${_syncTaskName}_${DateTime.now().millisecondsSinceEpoch}',
      _syncTaskTag,
      initialDelay: delay,
      constraints: constraints,
    );
  }

  /// 取消同步任务
  static Future<void> cancelSync() async {
    await Workmanager().cancelByUniqueName(_syncTaskName);
  }

  /// 取消所有同步任务
  static Future<void> cancelAllSync() async {
    await Workmanager().cancelAll();
  }

  // 新版插件未提供直接查询任务列表的 API，如需状态可自行持久化。
}
