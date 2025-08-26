import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../domain/entities/sync_settings.dart';
import '../../domain/repositories/sync_settings_repository.dart';

/// 同步设置仓库实现
class SyncSettingsRepositoryImpl implements SyncSettingsRepository {
  static const String _webdavUrlKey = 'webdav_url';
  static const String _usernameKey = 'username';
  static const String _passwordKey = 'password';
  static const String _syncDirectoriesKey = 'sync_directories';
  static const String _syncFrequencyKey = 'sync_frequency';
  static const String _syncOnlyOnWifiKey = 'sync_only_on_wifi';
  static const String _syncOnlyWhenChargingKey = 'sync_only_when_charging';
  static const String _syncOnlyWhenIdleKey = 'sync_only_when_idle';
  static const String _syncOnlyWhenBatteryNotLowKey = 'sync_only_when_battery_not_low';
  static const String _excludePatternsKey = 'exclude_patterns';
  static const String _enableNotificationsKey = 'enable_notifications';
  static const String _enableConflictResolutionKey = 'enable_conflict_resolution';

  final SharedPreferences _prefs;
  final FlutterSecureStorage _secureStorage;

  SyncSettingsRepositoryImpl({
    required SharedPreferences prefs,
    required FlutterSecureStorage secureStorage,
  })  : _prefs = prefs,
        _secureStorage = secureStorage;

  @override
  Future<SyncSettings> getSyncSettings() async {
    final webdavUrl = _prefs.getString(_webdavUrlKey);
    final username = _prefs.getString(_usernameKey);
    final syncDirectories = _prefs.getStringList(_syncDirectoriesKey) ?? [];
    final syncFrequencyName = _prefs.getString(_syncFrequencyKey);
    final syncFrequency = syncFrequencyName != null
        ? SyncFrequency.values.firstWhere(
            (e) => e.name == syncFrequencyName,
            orElse: () => SyncFrequency.manual,
          )
        : SyncFrequency.manual;
    final syncOnlyOnWifi = _prefs.getBool(_syncOnlyOnWifiKey) ?? true;
    final syncOnlyWhenCharging = _prefs.getBool(_syncOnlyWhenChargingKey) ?? false;
    final syncOnlyWhenIdle = _prefs.getBool(_syncOnlyWhenIdleKey) ?? false;
    final syncOnlyWhenBatteryNotLow = _prefs.getBool(_syncOnlyWhenBatteryNotLowKey) ?? true;
    final excludePatterns = _prefs.getStringList(_excludePatternsKey) ?? [];
    final enableNotifications = _prefs.getBool(_enableNotificationsKey) ?? true;
    final enableConflictResolution = _prefs.getBool(_enableConflictResolutionKey) ?? true;

    return SyncSettings(
      webdavUrl: webdavUrl,
      username: username,
      syncDirectories: syncDirectories,
      syncFrequency: syncFrequency,
      syncOnlyOnWifi: syncOnlyOnWifi,
      syncOnlyWhenCharging: syncOnlyWhenCharging,
      syncOnlyWhenIdle: syncOnlyWhenIdle,
      syncOnlyWhenBatteryNotLow: syncOnlyWhenBatteryNotLow,
      excludePatterns: excludePatterns,
      enableNotifications: enableNotifications,
      enableConflictResolution: enableConflictResolution,
    );
  }

  @override
  Future<void> saveSyncSettings(SyncSettings settings) async {
    await updateSyncSettings(settings);
  }

  @override
  Future<void> updateSyncSettings(SyncSettings settings) async {
    if (settings.webdavUrl != null) {
      await _prefs.setString(_webdavUrlKey, settings.webdavUrl!);
    }
    if (settings.username != null) {
      await _prefs.setString(_usernameKey, settings.username!);
    }
    await _prefs.setStringList(_syncDirectoriesKey, settings.syncDirectories);
    await _prefs.setString(_syncFrequencyKey, settings.syncFrequency.name);
    await _prefs.setBool(_syncOnlyOnWifiKey, settings.syncOnlyOnWifi);
    await _prefs.setBool(_syncOnlyWhenChargingKey, settings.syncOnlyWhenCharging);
    await _prefs.setBool(_syncOnlyWhenIdleKey, settings.syncOnlyWhenIdle);
    await _prefs.setBool(_syncOnlyWhenBatteryNotLowKey, settings.syncOnlyWhenBatteryNotLow);
    await _prefs.setStringList(_excludePatternsKey, settings.excludePatterns);
    await _prefs.setBool(_enableNotificationsKey, settings.enableNotifications);
    await _prefs.setBool(_enableConflictResolutionKey, settings.enableConflictResolution);
  }

  @override
  Future<String?> getWebdavUrl() async {
    return _prefs.getString(_webdavUrlKey);
  }

  @override
  Future<void> setWebdavUrl(String url) async {
    await _prefs.setString(_webdavUrlKey, url);
  }

  @override
  Future<String?> getUsername() async {
    return _prefs.getString(_usernameKey);
  }

  @override
  Future<void> setUsername(String username) async {
    await _prefs.setString(_usernameKey, username);
  }

  @override
  Future<String?> getPassword() async {
    return await _secureStorage.read(key: _passwordKey);
  }

  @override
  Future<void> setPassword(String password) async {
    await _secureStorage.write(key: _passwordKey, value: password);
  }

  @override
  Future<List<String>> getSyncDirectories() async {
    return _prefs.getStringList(_syncDirectoriesKey) ?? [];
  }

  @override
  Future<void> addSyncDirectory(String directory) async {
    final directories = await getSyncDirectories();
    if (!directories.contains(directory)) {
      directories.add(directory);
      await _prefs.setStringList(_syncDirectoriesKey, directories);
    }
  }

  @override
  Future<void> removeSyncDirectory(String directory) async {
    final directories = await getSyncDirectories();
    directories.remove(directory);
    await _prefs.setStringList(_syncDirectoriesKey, directories);
  }

  @override
  Future<void> setSyncDirectories(List<String> directories) async {
    await _prefs.setStringList(_syncDirectoriesKey, directories);
  }

  @override
  Future<SyncFrequency> getSyncFrequency() async {
    final frequencyName = _prefs.getString(_syncFrequencyKey);
    return frequencyName != null
        ? SyncFrequency.values.firstWhere(
            (e) => e.name == frequencyName,
            orElse: () => SyncFrequency.manual,
          )
        : SyncFrequency.manual;
  }

  @override
  Future<void> setSyncFrequency(SyncFrequency frequency) async {
    await _prefs.setString(_syncFrequencyKey, frequency.name);
  }

  @override
  Future<bool> getSyncOnlyOnWifi() async {
    return _prefs.getBool(_syncOnlyOnWifiKey) ?? true;
  }

  @override
  Future<void> setSyncOnlyOnWifi(bool value) async {
    await _prefs.setBool(_syncOnlyOnWifiKey, value);
  }

  @override
  Future<bool> getSyncOnlyWhenCharging() async {
    return _prefs.getBool(_syncOnlyWhenChargingKey) ?? false;
  }

  @override
  Future<void> setSyncOnlyWhenCharging(bool value) async {
    await _prefs.setBool(_syncOnlyWhenChargingKey, value);
  }

  @override
  Future<bool> getSyncOnlyWhenIdle() async {
    return _prefs.getBool(_syncOnlyWhenIdleKey) ?? false;
  }

  @override
  Future<void> setSyncOnlyWhenIdle(bool value) async {
    await _prefs.setBool(_syncOnlyWhenIdleKey, value);
  }

  @override
  Future<bool> getSyncOnlyWhenBatteryNotLow() async {
    return _prefs.getBool(_syncOnlyWhenBatteryNotLowKey) ?? true;
  }

  @override
  Future<void> setSyncOnlyWhenBatteryNotLow(bool value) async {
    await _prefs.setBool(_syncOnlyWhenBatteryNotLowKey, value);
  }

  @override
  Future<List<String>> getExcludePatterns() async {
    return _prefs.getStringList(_excludePatternsKey) ?? [];
  }

  @override
  Future<void> addExcludePattern(String pattern) async {
    final patterns = await getExcludePatterns();
    if (!patterns.contains(pattern)) {
      patterns.add(pattern);
      await _prefs.setStringList(_excludePatternsKey, patterns);
    }
  }

  @override
  Future<void> removeExcludePattern(String pattern) async {
    final patterns = await getExcludePatterns();
    patterns.remove(pattern);
    await _prefs.setStringList(_excludePatternsKey, patterns);
  }

  @override
  Future<void> setExcludePatterns(List<String> patterns) async {
    await _prefs.setStringList(_excludePatternsKey, patterns);
  }

  @override
  Future<bool> getEnableNotifications() async {
    return _prefs.getBool(_enableNotificationsKey) ?? true;
  }

  @override
  Future<void> setEnableNotifications(bool value) async {
    await _prefs.setBool(_enableNotificationsKey, value);
  }

  @override
  Future<bool> getEnableConflictResolution() async {
    return _prefs.getBool(_enableConflictResolutionKey) ?? true;
  }

  @override
  Future<void> setEnableConflictResolution(bool value) async {
    await _prefs.setBool(_enableConflictResolutionKey, value);
  }

  @override
  Future<void> clearAllSettings() async {
    await _prefs.clear();
    await _secureStorage.deleteAll();
  }
}
