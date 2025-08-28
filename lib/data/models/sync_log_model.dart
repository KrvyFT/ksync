import 'package:hive/hive.dart';
import '../../domain/entities/sync_log.dart';

part 'sync_log_model.g.dart';

@HiveType(typeId: 1)
class SyncLogModel extends HiveObject {
  @HiveField(0)
  final String jobId;

  @HiveField(1)
  final DateTime startTime;

  @HiveField(2)
  final DateTime? endTime;

  @HiveField(3)
  final SyncStatus status;

  @HiveField(4)
  final int filesSynced;

  @HiveField(5)
  final int filesFailed;

  @HiveField(6)
  final List<String> errorMessages;

  @HiveField(7)
  final List<String> syncedFiles;

  @HiveField(8)
  final Map<String, String> failedFiles;

  SyncLogModel({
    required this.jobId,
    required this.startTime,
    this.endTime,
    required this.status,
    required this.filesSynced,
    required this.filesFailed,
    required this.errorMessages,
    required this.syncedFiles,
    required this.failedFiles,
  });

  /// 从实体创建模型
  factory SyncLogModel.fromEntity(SyncLog entity) {
    return SyncLogModel(
      jobId: entity.jobId,
      startTime: entity.startTime,
      endTime: entity.endTime,
      status: entity.status,
      filesSynced: entity.filesSynced,
      filesFailed: entity.filesFailed,
      errorMessages: entity.errorMessages,
      syncedFiles: entity.syncedFiles,
      failedFiles: entity.failedFiles,
    );
  }

  /// 转换为实体
  SyncLog toEntity() {
    return SyncLog(
      jobId: jobId,
      startTime: startTime,
      endTime: endTime,
      status: status,
      filesSynced: filesSynced,
      filesFailed: filesFailed,
      errorMessages: errorMessages,
      syncedFiles: syncedFiles,
      failedFiles: failedFiles,
    );
  }

  /// 从 JSON 创建实例
  factory SyncLogModel.fromJson(Map<String, dynamic> json) {
    return SyncLogModel(
      jobId: json['jobId'] as String,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: json['endTime'] != null 
          ? DateTime.parse(json['endTime'] as String) 
          : null,
      status: SyncStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => SyncStatus.failed,
      ),
      filesSynced: json['filesSynced'] as int,
      filesFailed: json['filesFailed'] as int,
      errorMessages: List<String>.from(json['errorMessages'] as List),
      syncedFiles: List<String>.from(json['syncedFiles'] as List? ?? []),
      failedFiles: Map<String, String>.from(json['failedFiles'] as Map? ?? {}),
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'jobId': jobId,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'status': status.name,
      'filesSynced': filesSynced,
      'filesFailed': filesFailed,
      'errorMessages': errorMessages,
      'syncedFiles': syncedFiles,
      'failedFiles': failedFiles,
    };
  }
}
