import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/file_metadata_model.dart';
import '../../data/models/sync_log_model.dart';
import '../../data/repositories/file_metadata_repository_impl.dart';
import '../../data/repositories/sync_log_repository_impl.dart';
import '../../data/repositories/sync_settings_repository_impl.dart';
import '../../data/repositories/webdav_repository_impl.dart';
import '../../domain/entities/sync_log.dart';
import '../../domain/repositories/file_metadata_repository.dart';
import '../../domain/repositories/sync_log_repository.dart';
import '../../domain/repositories/sync_settings_repository.dart';
import '../../domain/repositories/webdav_repository.dart';
import '../../domain/usecases/sync_engine_usecase.dart';

final getIt = GetIt.instance;

Future<void> configureDependencies() async {
  // 确保 Hive 初始化和适配器注册只进行一次
  if (!Hive.isAdapterRegistered(FileMetadataModelAdapter().typeId)) {
    await Hive.initFlutter();
    Hive.registerAdapter(FileMetadataModelAdapter());
    Hive.registerAdapter(SyncLogModelAdapter());
    Hive.registerAdapter(SyncStatusAdapter());
  }

  // 第三方依赖
  if (!getIt.isRegistered<SharedPreferences>()) {
    getIt.registerSingletonAsync<SharedPreferences>(
        () => SharedPreferences.getInstance());
  }

  if (!getIt.isRegistered<FlutterSecureStorage>()) {
    getIt.registerSingleton<FlutterSecureStorage>(const FlutterSecureStorage());
  }

  // 仓库实现
  if (!getIt.isRegistered<FileMetadataRepository>()) {
    getIt.registerSingletonAsync<FileMetadataRepository>(() async {
      final repository = FileMetadataRepositoryImpl();
      await repository.initialize();
      return repository;
    });
  }

  if (!getIt.isRegistered<SyncLogRepository>()) {
    getIt.registerSingletonAsync<SyncLogRepository>(() async {
      final repository = SyncLogRepositoryImpl();
      await repository.initialize();
      return repository;
    });
  }

  if (!getIt.isRegistered<SyncSettingsRepository>()) {
    getIt.registerSingletonAsync<SyncSettingsRepository>(() async {
      final prefs = await getIt.getAsync<SharedPreferences>();
      final secureStorage = getIt.get<FlutterSecureStorage>();
      return SyncSettingsRepositoryImpl(
        prefs: prefs,
        secureStorage: secureStorage,
      );
    });
  }

  if (!getIt.isRegistered<WebdavRepository>()) {
    getIt.registerLazySingleton<WebdavRepository>(() => WebdavRepositoryImpl());
  }

  // 用例
  if (!getIt.isRegistered<SyncEngineUseCase>()) {
    getIt.registerSingletonAsync<SyncEngineUseCase>(() async {
      await getIt.isReady<FileMetadataRepository>();
      await getIt.isReady<SyncLogRepository>();
      await getIt.isReady<SyncSettingsRepository>();

      return SyncEngineUseCase(
        fileMetadataRepository: getIt<FileMetadataRepository>(),
        syncLogRepository: getIt<SyncLogRepository>(),
        syncSettingsRepository: getIt<SyncSettingsRepository>(),
        webdavRepository: getIt<WebdavRepository>(),
      );
    });
  }
}
