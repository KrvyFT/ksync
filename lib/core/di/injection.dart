import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../data/repositories/file_metadata_repository_impl.dart';
import '../../data/repositories/sync_log_repository_impl.dart';
import '../../data/repositories/sync_settings_repository_impl.dart';
import '../../data/repositories/webdav_repository_impl.dart';
import '../../domain/repositories/file_metadata_repository.dart';
import '../../domain/repositories/sync_log_repository.dart';
import '../../domain/repositories/sync_settings_repository.dart';
import '../../domain/repositories/webdav_repository.dart';
import '../../domain/usecases/sync_engine_usecase.dart';

final getIt = GetIt.instance;

Future<void> configureDependencies() async {
  // 注册第三方依赖
  if (!getIt.isRegistered<SharedPreferences>()) {
    getIt.registerSingletonAsync<SharedPreferences>(() async {
      return await SharedPreferences.getInstance();
    });
  }

  if (!getIt.isRegistered<FlutterSecureStorage>()) {
    getIt.registerSingleton<FlutterSecureStorage>(
      const FlutterSecureStorage(),
    );
  }

  // 注册仓库实现
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
      await getIt.isReady<SharedPreferences>();
      final prefs = await getIt.getAsync<SharedPreferences>();
      final secureStorage = getIt.get<FlutterSecureStorage>();
      return SyncSettingsRepositoryImpl(
        prefs: prefs,
        secureStorage: secureStorage,
      );
    });
  }

  if (!getIt.isRegistered<WebdavRepository>()) {
    getIt.registerSingleton<WebdavRepository>(
      WebdavRepositoryImpl(),
    );
  }

  // 注册用例
  if (!getIt.isRegistered<SyncEngineUseCase>()) {
    getIt.registerSingletonAsync<SyncEngineUseCase>(() async {
      await getIt.isReady<FileMetadataRepository>();
      await getIt.isReady<SyncLogRepository>();
      await getIt.isReady<SyncSettingsRepository>();
      final fileMetadataRepository = await getIt.getAsync<FileMetadataRepository>();
      final syncLogRepository = await getIt.getAsync<SyncLogRepository>();
      final syncSettingsRepository = await getIt.getAsync<SyncSettingsRepository>();
      final webdavRepository = getIt.get<WebdavRepository>();

      return SyncEngineUseCase(
        fileMetadataRepository: fileMetadataRepository,
        syncLogRepository: syncLogRepository,
        syncSettingsRepository: syncSettingsRepository,
        webdavRepository: webdavRepository,
      );
    });
  }
}
