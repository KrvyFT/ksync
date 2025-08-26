import 'package:equatable/equatable.dart';

/// 同步频率枚举
enum SyncFrequency {
  every15Minutes,
  every30Minutes,
  everyHour,
  every2Hours,
  every6Hours,
  daily,
  manual,
}


/// 同步设置实体，用于存储用户的同步配置
class SyncSettings extends Equatable {
  final String? webdavUrl;
  final String? username;
  final List<String> syncDirectories;
  final SyncFrequency syncFrequency;
  final bool syncOnlyOnWifi;
  final bool syncOnlyWhenCharging;
  final bool syncOnlyWhenIdle;
  final bool syncOnlyWhenBatteryNotLow;
  final List<String> excludePatterns;
  final bool enableNotifications;
  final bool enableConflictResolution;

  const SyncSettings({
    this.webdavUrl,
    this.username,
    this.syncDirectories = const [],
    this.syncFrequency = SyncFrequency.manual,
    this.syncOnlyOnWifi = true,
    this.syncOnlyWhenCharging = false,
    this.syncOnlyWhenIdle = false,
    this.syncOnlyWhenBatteryNotLow = true,
    this.excludePatterns = const [],
    this.enableNotifications = true,
    this.enableConflictResolution = true,
  });

  /// 检查是否已配置 WebDAV 连接
  bool get isWebdavConfigured => 
      webdavUrl != null && webdavUrl!.isNotEmpty && username != null && username!.isNotEmpty;

  /// 检查是否已选择同步目录
  bool get hasSyncDirectories => syncDirectories.isNotEmpty;

  /// 检查是否可以进行自动同步
  bool get canAutoSync => isWebdavConfigured && hasSyncDirectories && syncFrequency != SyncFrequency.manual;

  @override
  List<Object?> get props => [
        webdavUrl,
        username,
        syncDirectories,
        syncFrequency,
        syncOnlyOnWifi,
        syncOnlyWhenCharging,
        syncOnlyWhenIdle,
        syncOnlyWhenBatteryNotLow,
        excludePatterns,
        enableNotifications,
        enableConflictResolution,
      ];

  /// 创建副本并更新指定字段
  SyncSettings copyWith({
    String? webdavUrl,
    String? username,
    List<String>? syncDirectories,
    SyncFrequency? syncFrequency,
    bool? syncOnlyOnWifi,
    bool? syncOnlyWhenCharging,
    bool? syncOnlyWhenIdle,
    bool? syncOnlyWhenBatteryNotLow,
    List<String>? excludePatterns,
    bool? enableNotifications,
    bool? enableConflictResolution,
  }) {
    return SyncSettings(
      webdavUrl: webdavUrl ?? this.webdavUrl,
      username: username ?? this.username,
      syncDirectories: syncDirectories ?? this.syncDirectories,
      syncFrequency: syncFrequency ?? this.syncFrequency,
      syncOnlyOnWifi: syncOnlyOnWifi ?? this.syncOnlyOnWifi,
      syncOnlyWhenCharging: syncOnlyWhenCharging ?? this.syncOnlyWhenCharging,
      syncOnlyWhenIdle: syncOnlyWhenIdle ?? this.syncOnlyWhenIdle,
      syncOnlyWhenBatteryNotLow: syncOnlyWhenBatteryNotLow ?? this.syncOnlyWhenBatteryNotLow,
      excludePatterns: excludePatterns ?? this.excludePatterns,
      enableNotifications: enableNotifications ?? this.enableNotifications,
      enableConflictResolution: enableConflictResolution ?? this.enableConflictResolution,
    );
  }

  /// 从 JSON 创建实例
  factory SyncSettings.fromJson(Map<String, dynamic> json) {
    return SyncSettings(
      webdavUrl: json['webdavUrl'] as String?,
      username: json['username'] as String?,
      syncDirectories: List<String>.from(json['syncDirectories'] as List? ?? []),
      syncFrequency: SyncFrequency.values.firstWhere(
        (e) => e.name == json['syncFrequency'],
        orElse: () => SyncFrequency.manual,
      ),
      syncOnlyOnWifi: json['syncOnlyOnWifi'] as bool? ?? true,
      syncOnlyWhenCharging: json['syncOnlyWhenCharging'] as bool? ?? false,
      syncOnlyWhenIdle: json['syncOnlyWhenIdle'] as bool? ?? false,
      syncOnlyWhenBatteryNotLow: json['syncOnlyWhenBatteryNotLow'] as bool? ?? true,
      excludePatterns: List<String>.from(json['excludePatterns'] as List? ?? []),
      enableNotifications: json['enableNotifications'] as bool? ?? true,
      enableConflictResolution: json['enableConflictResolution'] as bool? ?? true,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'webdavUrl': webdavUrl,
      'username': username,
      'syncDirectories': syncDirectories,
      'syncFrequency': syncFrequency.name,
      'syncOnlyOnWifi': syncOnlyOnWifi,
      'syncOnlyWhenCharging': syncOnlyWhenCharging,
      'syncOnlyWhenIdle': syncOnlyWhenIdle,
      'syncOnlyWhenBatteryNotLow': syncOnlyWhenBatteryNotLow,
      'excludePatterns': excludePatterns,
      'enableNotifications': enableNotifications,
      'enableConflictResolution': enableConflictResolution,
    };
  }

  /// 获取同步频率对应的 Duration
  Duration? get syncFrequencyDuration {
    switch (syncFrequency) {
      case SyncFrequency.every15Minutes:
        return const Duration(minutes: 15);
      case SyncFrequency.every30Minutes:
        return const Duration(minutes: 30);
      case SyncFrequency.everyHour:
        return const Duration(hours: 1);
      case SyncFrequency.every2Hours:
        return const Duration(hours: 2);
      case SyncFrequency.every6Hours:
        return const Duration(hours: 6);
      case SyncFrequency.daily:
        return const Duration(days: 1);
      case SyncFrequency.manual:
        return null;
    }
  }
}
