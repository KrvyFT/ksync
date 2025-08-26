import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../data/models/file_metadata_model.dart';
import '../../data/models/sync_log_model.dart';
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
  // 初始化 Hive
  await Hive.initFlutter();
  
  // 注册 Hive 适配器
  Hive.registerAdapter(FileMetadataModelAdapter());
  Hive.registerAdapter(SyncLogModelAdapter());

  // 注册第三方依赖
  getIt.registerSingletonAsync<SharedPreferences>(() async {
    return await SharedPreferences.getInstance();
  });

  getIt.registerSingleton<FlutterSecureStorage>(
    const FlutterSecureStorage(),
  );

  // 注册仓库实现
  getIt.registerSingletonAsync<FileMetadataRepository>(() async {
    final repository = FileMetadataRepositoryImpl();
    await repository.initialize();
    return repository;
  });

  getIt.registerSingletonAsync<SyncLogRepository>(() async {
    final repository = SyncLogRepositoryImpl();
    await repository.initialize();
    return repository;
  });

  getIt.registerSingletonAsync<SyncSettingsRepository>(() async {
    final prefs = await getIt.getAsync<SharedPreferences>();
    final secureStorage = getIt.get<FlutterSecureStorage>();
    return SyncSettingsRepositoryImpl(
      prefs: prefs,
      secureStorage: secureStorage,
    );
  });

  getIt.registerSingleton<WebdavRepository>(
    WebdavRepositoryImpl(),
  );

  // 注册用例
  getIt.registerSingletonAsync<SyncEngineUseCase>(() async {
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
