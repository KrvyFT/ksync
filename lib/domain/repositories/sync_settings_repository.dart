import '../entities/sync_settings.dart';

/// 同步设置仓库接口
abstract class SyncSettingsRepository {
  /// 获取同步设置
  Future<SyncSettings> getSyncSettings();
  
  /// 保存同步设置
  Future<void> saveSyncSettings(SyncSettings settings);
  
  /// 更新同步设置
  Future<void> updateSyncSettings(SyncSettings settings);
  
  /// 获取 WebDAV URL
  Future<String?> getWebdavUrl();
  
  /// 设置 WebDAV URL
  Future<void> setWebdavUrl(String url);
  
  /// 获取用户名
  Future<String?> getUsername();
  
  /// 设置用户名
  Future<void> setUsername(String username);
  
  /// 获取密码
  Future<String?> getPassword();
  
  /// 设置密码
  Future<void> setPassword(String password);
  
  /// 获取同步目录列表
  Future<List<String>> getSyncDirectories();
  
  /// 添加同步目录
  Future<void> addSyncDirectory(String directory);
  
  /// 移除同步目录
  Future<void> removeSyncDirectory(String directory);
  
  /// 设置同步目录列表
  Future<void> setSyncDirectories(List<String> directories);
  
  /// 获取同步频率
  Future<SyncFrequency> getSyncFrequency();
  
  /// 设置同步频率
  Future<void> setSyncFrequency(SyncFrequency frequency);
  
  /// 获取网络约束设置
  Future<bool> getSyncOnlyOnWifi();
  
  /// 设置网络约束
  Future<void> setSyncOnlyOnWifi(bool value);
  
  /// 获取充电约束设置
  Future<bool> getSyncOnlyWhenCharging();
  
  /// 设置充电约束
  Future<void> setSyncOnlyWhenCharging(bool value);
  
  /// 获取空闲约束设置
  Future<bool> getSyncOnlyWhenIdle();
  
  /// 设置空闲约束
  Future<void> setSyncOnlyWhenIdle(bool value);
  
  /// 获取电池约束设置
  Future<bool> getSyncOnlyWhenBatteryNotLow();
  
  /// 设置电池约束
  Future<void> setSyncOnlyWhenBatteryNotLow(bool value);
  
  /// 获取排除模式列表
  Future<List<String>> getExcludePatterns();
  
  /// 添加排除模式
  Future<void> addExcludePattern(String pattern);
  
  /// 移除排除模式
  Future<void> removeExcludePattern(String pattern);
  
  /// 设置排除模式列表
  Future<void> setExcludePatterns(List<String> patterns);
  
  /// 获取通知设置
  Future<bool> getEnableNotifications();
  
  /// 设置通知
  Future<void> setEnableNotifications(bool value);
  
  /// 获取冲突解决设置
  Future<bool> getEnableConflictResolution();
  
  /// 设置冲突解决
  Future<void> setEnableConflictResolution(bool value);
  
  /// 清除所有设置
  Future<void> clearAllSettings();
}
