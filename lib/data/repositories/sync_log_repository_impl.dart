import 'package:hive_flutter/hive_flutter.dart';

import '../../domain/entities/sync_log.dart';
import '../../domain/repositories/sync_log_repository.dart';
import '../models/sync_log_model.dart';

/// 同步日志仓库实现
class SyncLogRepositoryImpl implements SyncLogRepository {
  static const String _boxName = 'sync_log_box';
  late Box<SyncLogModel> _box;

  /// 初始化仓库
  Future<void> initialize() async {
    _box = await Hive.openBox<SyncLogModel>(_boxName);
  }

  @override
  Future<List<SyncLog>> getAllSyncLogs() async {
    final models = _box.values.toList();
    // 按开始时间倒序排列
    models.sort((a, b) => b.startTime.compareTo(a.startTime));
    return models.map((model) => model.toEntity()).toList();
  }

  @override
  Future<SyncLog?> getSyncLogById(String jobId) async {
    final models = _box.values.where((model) => model.jobId == jobId);
    if (models.isEmpty) return null;
    return models.first.toEntity();
  }

  @override
  Future<void> saveSyncLog(SyncLog syncLog) async {
    final model = SyncLogModel.fromEntity(syncLog);
    await _box.put(syncLog.jobId, model);
  }

  @override
  Future<void> updateSyncLog(SyncLog syncLog) async {
    await saveSyncLog(syncLog);
  }

  @override
  Future<void> deleteSyncLog(String jobId) async {
    await _box.delete(jobId);
  }

  @override
  Future<List<SyncLog>> getRecentSyncLogs(int limit) async {
    final allLogs = await getAllSyncLogs();
    return allLogs.take(limit).toList();
  }

  @override
  Future<List<SyncLog>> getSyncLogsByDateRange(DateTime startDate, DateTime endDate) async {
    final models = _box.values.where((model) => 
        model.startTime.isAfter(startDate) && model.startTime.isBefore(endDate));
    final sortedModels = models.toList()
      ..sort((a, b) => b.startTime.compareTo(a.startTime));
    return sortedModels.map((model) => model.toEntity()).toList();
  }

  @override
  Future<List<SyncLog>> getFailedSyncLogs() async {
    final models = _box.values.where((model) => model.status == SyncStatus.failed);
    final sortedModels = models.toList()
      ..sort((a, b) => b.startTime.compareTo(a.startTime));
    return sortedModels.map((model) => model.toEntity()).toList();
  }

  @override
  Future<List<SyncLog>> getSuccessfulSyncLogs() async {
    final models = _box.values.where((model) => model.status == SyncStatus.success);
    final sortedModels = models.toList()
      ..sort((a, b) => b.startTime.compareTo(a.startTime));
    return sortedModels.map((model) => model.toEntity()).toList();
  }

  @override
  Future<void> clearAllSyncLogs() async {
    await _box.clear();
  }

  @override
  Future<void> deleteOldSyncLogs(int keepCount) async {
    final allLogs = await getAllSyncLogs();
    if (allLogs.length <= keepCount) return;

    final logsToDelete = allLogs.skip(keepCount);
    for (final log in logsToDelete) {
      await deleteSyncLog(log.jobId);
    }
  }

  @override
  Future<SyncStatistics> getSyncStatistics() async {
    final allLogs = await getAllSyncLogs();
    
    if (allLogs.isEmpty) {
      return const SyncStatistics(
        totalSyncs: 0,
        successfulSyncs: 0,
        failedSyncs: 0,
        totalFilesSynced: 0,
        totalFilesFailed: 0,
        averageSyncDuration: Duration.zero,
      );
    }

    final successfulSyncs = allLogs.where((log) => log.status == SyncStatus.success).length;
    final failedSyncs = allLogs.where((log) => log.status == SyncStatus.failed).length;
    
    final totalFilesSynced = allLogs.fold<int>(0, (sum, log) => sum + log.filesSynced);
    final totalFilesFailed = allLogs.fold<int>(0, (sum, log) => sum + log.filesFailed);
    
    // 计算平均同步时间
    final completedLogs = allLogs.where((log) => log.duration != null).toList();
    Duration averageDuration = Duration.zero;
    if (completedLogs.isNotEmpty) {
      final totalDuration = completedLogs.fold<Duration>(
        Duration.zero, 
        (sum, log) => sum + log.duration!
      );
      averageDuration = Duration(
        milliseconds: totalDuration.inMilliseconds ~/ completedLogs.length
      );
    }

    final lastSyncTime = allLogs.isNotEmpty ? allLogs.first.startTime : null;

    return SyncStatistics(
      totalSyncs: allLogs.length,
      successfulSyncs: successfulSyncs,
      failedSyncs: failedSyncs,
      totalFilesSynced: totalFilesSynced,
      totalFilesFailed: totalFilesFailed,
      averageSyncDuration: averageDuration,
      lastSyncTime: lastSyncTime,
    );
  }

  /// 关闭仓库
  Future<void> close() async {
    await _box.close();
  }
}
