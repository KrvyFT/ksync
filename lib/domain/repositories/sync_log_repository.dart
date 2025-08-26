import '../entities/sync_log.dart';

/// 同步日志仓库接口
abstract class SyncLogRepository {
  /// 获取所有同步日志
  Future<List<SyncLog>> getAllSyncLogs();
  
  /// 根据任务ID获取同步日志
  Future<SyncLog?> getSyncLogById(String jobId);
  
  /// 保存同步日志
  Future<void> saveSyncLog(SyncLog syncLog);
  
  /// 更新同步日志
  Future<void> updateSyncLog(SyncLog syncLog);
  
  /// 删除同步日志
  Future<void> deleteSyncLog(String jobId);
  
  /// 获取最近的同步日志
  Future<List<SyncLog>> getRecentSyncLogs(int limit);
  
  /// 获取指定时间范围内的同步日志
  Future<List<SyncLog>> getSyncLogsByDateRange(DateTime startDate, DateTime endDate);
  
  /// 获取失败的同步日志
  Future<List<SyncLog>> getFailedSyncLogs();
  
  /// 获取成功的同步日志
  Future<List<SyncLog>> getSuccessfulSyncLogs();
  
  /// 清空所有同步日志
  Future<void> clearAllSyncLogs();
  
  /// 删除旧的同步日志（保留最近N条）
  Future<void> deleteOldSyncLogs(int keepCount);
  
  /// 获取同步统计信息
  Future<SyncStatistics> getSyncStatistics();
}

/// 同步统计信息
class SyncStatistics {
  final int totalSyncs;
  final int successfulSyncs;
  final int failedSyncs;
  final int totalFilesSynced;
  final int totalFilesFailed;
  final Duration averageSyncDuration;
  final DateTime? lastSyncTime;

  const SyncStatistics({
    required this.totalSyncs,
    required this.successfulSyncs,
    required this.failedSyncs,
    required this.totalFilesSynced,
    required this.totalFilesFailed,
    required this.averageSyncDuration,
    this.lastSyncTime,
  });

  /// 获取成功率
  double get successRate {
    if (totalSyncs == 0) return 0.0;
    return successfulSyncs / totalSyncs;
  }

  /// 获取失败率
  double get failureRate {
    if (totalSyncs == 0) return 0.0;
    return failedSyncs / totalSyncs;
  }
}
