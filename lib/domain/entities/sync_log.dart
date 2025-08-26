import 'package:equatable/equatable.dart';

/// 同步状态枚举
enum SyncStatus {
  success,
  failed,
  canceled,
  inProgress,
}

/// 同步日志实体，用于记录同步任务的执行情况
class SyncLog extends Equatable {
  final String jobId;
  final DateTime startTime;
  final DateTime? endTime;
  final SyncStatus status;
  final int filesSynced;
  final int filesFailed;
  final List<String> errorMessages;

  const SyncLog({
    required this.jobId,
    required this.startTime,
    this.endTime,
    required this.status,
    required this.filesSynced,
    required this.filesFailed,
    required this.errorMessages,
  });

  /// 获取同步持续时间
  Duration? get duration {
    if (endTime == null) return null;
    return endTime!.difference(startTime);
  }

  /// 获取总文件数
  int get totalFiles => filesSynced + filesFailed;

  /// 获取成功率
  double get successRate {
    if (totalFiles == 0) return 0.0;
    return filesSynced / totalFiles;
  }

  @override
  List<Object?> get props => [
        jobId,
        startTime,
        endTime,
        status,
        filesSynced,
        filesFailed,
        errorMessages,
      ];

  /// 创建副本并更新指定字段
  SyncLog copyWith({
    String? jobId,
    DateTime? startTime,
    DateTime? endTime,
    SyncStatus? status,
    int? filesSynced,
    int? filesFailed,
    List<String>? errorMessages,
  }) {
    return SyncLog(
      jobId: jobId ?? this.jobId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      status: status ?? this.status,
      filesSynced: filesSynced ?? this.filesSynced,
      filesFailed: filesFailed ?? this.filesFailed,
      errorMessages: errorMessages ?? this.errorMessages,
    );
  }

  /// 从 JSON 创建实例
  factory SyncLog.fromJson(Map<String, dynamic> json) {
    return SyncLog(
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
    };
  }
}
