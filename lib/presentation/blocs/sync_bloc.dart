import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../domain/entities/sync_log.dart';
import '../../domain/entities/sync_settings.dart';
import '../../domain/usecases/sync_engine_usecase.dart';
import '../../core/di/injection.dart';
import '../../core/background/sync_scheduler.dart';
import '../../domain/repositories/sync_settings_repository.dart';
import '../../core/utils/logging.dart';

// Events
abstract class SyncEvent extends Equatable {
  const SyncEvent();

  @override
  List<Object?> get props => [];
}

class StartSync extends SyncEvent {
  const StartSync();
}

class StopSync extends SyncEvent {
  const StopSync();
}

class UpdateSyncProgress extends SyncEvent {
  final SyncProgress progress;

  const UpdateSyncProgress(this.progress);

  @override
  List<Object?> get props => [progress];
}

class SyncCompleted extends SyncEvent {
  final SyncLog syncLog;

  const SyncCompleted(this.syncLog);

  @override
  List<Object?> get props => [syncLog];
}

class SyncFailed extends SyncEvent {
  final String error;

  const SyncFailed(this.error);

  @override
  List<Object?> get props => [error];
}

class LoadSyncSettings extends SyncEvent {
  const LoadSyncSettings();
}

class UpdateSyncSettings extends SyncEvent {
  final SyncSettings settings;

  const UpdateSyncSettings(this.settings);

  @override
  List<Object?> get props => [settings];
}

// States
abstract class SyncState extends Equatable {
  const SyncState();

  @override
  List<Object?> get props => [];
}

class SyncInitial extends SyncState {
  const SyncInitial();
}

class SyncLoading extends SyncState {
  const SyncLoading();
}

class SyncInProgress extends SyncState {
  final SyncProgress progress;
  final SyncSettings settings;

  const SyncInProgress({
    required this.progress,
    required this.settings,
  });

  @override
  List<Object?> get props => [progress, settings];
}

class SyncSuccess extends SyncState {
  final SyncLog syncLog;
  final SyncSettings settings;

  const SyncSuccess({
    required this.syncLog,
    required this.settings,
  });

  @override
  List<Object?> get props => [syncLog, settings];
}

class SyncFailure extends SyncState {
  final String error;
  final SyncSettings settings;

  const SyncFailure({
    required this.error,
    required this.settings,
  });

  @override
  List<Object?> get props => [error, settings];
}

class SyncSettingsLoaded extends SyncState {
  final SyncSettings settings;

  const SyncSettingsLoaded(this.settings);

  @override
  List<Object?> get props => [settings];
}

// BLoC
class SyncBloc extends Bloc<SyncEvent, SyncState> {
  SyncEngineUseCase? _syncEngineUseCase;
  StreamSubscription<SyncProgress>? _progressSubscription;

  SyncBloc() : super(const SyncInitial()) {
    on<StartSync>(_onStartSync);
    on<StopSync>(_onStopSync);
    on<UpdateSyncProgress>(_onUpdateSyncProgress);
    on<SyncCompleted>(_onSyncCompleted);
    on<SyncFailed>(_onSyncFailed);
    on<LoadSyncSettings>(_onLoadSyncSettings);
    on<UpdateSyncSettings>(_onUpdateSyncSettings);
  }

  Future<void> _onStartSync(StartSync event, Emitter<SyncState> emit) async {
    logger.info('Manual sync triggered from UI.');
    try {
      emit(const SyncLoading());

      // 获取依赖
      if (_syncEngineUseCase == null) {
        await configureDependencies();
        _syncEngineUseCase = await getIt.getAsync<SyncEngineUseCase>();
      }

      // 获取设置
      final settingsRepository = await getIt.getAsync<SyncSettingsRepository>();
      final settings = await settingsRepository.getSyncSettings();

      if (!settings.isWebdavConfigured) {
        emit(SyncFailure(
          error: 'WebDAV 未配置',
          settings: settings,
        ));
        return;
      }

      if (!settings.hasSyncDirectories) {
        emit(SyncFailure(
          error: '未选择同步目录',
          settings: settings,
        ));
        return;
      }

      // 开始同步
      emit(SyncInProgress(
        progress: const SyncProgress(
          currentFile: '',
          currentFileIndex: 0,
          totalFiles: 0,
          filesSynced: 0,
          filesFailed: 0,
          status: SyncStatus.inProgress,
        ),
        settings: settings,
      ));

      // 执行同步
      final syncLog = await _syncEngineUseCase!.executeSync(
        onProgress: (progress) {
          add(UpdateSyncProgress(progress));
        },
      );

      add(SyncCompleted(syncLog));
    } catch (e, s) {
      logger.error('Manual sync failed', e, s);
      final settingsRepository = await getIt.getAsync<SyncSettingsRepository>();
      final settings = await settingsRepository.getSyncSettings();

      emit(SyncFailure(
        error: e.toString(),
        settings: settings,
      ));
    }
  }

  Future<void> _onStopSync(StopSync event, Emitter<SyncState> emit) async {
    await _progressSubscription?.cancel();

    final settingsRepository = await getIt.getAsync<SyncSettingsRepository>();
    final settings = await settingsRepository.getSyncSettings();

    emit(SyncSettingsLoaded(settings));
  }

  void _onUpdateSyncProgress(
      UpdateSyncProgress event, Emitter<SyncState> emit) {
    if (state is SyncInProgress) {
      final currentState = state as SyncInProgress;
      emit(SyncInProgress(
        progress: event.progress,
        settings: currentState.settings,
      ));
    }
  }

  void _onSyncCompleted(SyncCompleted event, Emitter<SyncState> emit) {
    final currentState = state;
    if (currentState is SyncInProgress) {
      emit(SyncSuccess(
        syncLog: event.syncLog,
        settings: currentState.settings,
      ));
    }
  }

  void _onSyncFailed(SyncFailed event, Emitter<SyncState> emit) {
    final currentState = state;
    if (currentState is SyncInProgress) {
      emit(SyncFailure(
        error: event.error,
        settings: currentState.settings,
      ));
    }
  }

  Future<void> _onLoadSyncSettings(
      LoadSyncSettings event, Emitter<SyncState> emit) async {
    try {
      final settingsRepository = await getIt.getAsync<SyncSettingsRepository>();
      final settings = await settingsRepository.getSyncSettings();
      emit(SyncSettingsLoaded(settings));

      // 在加载设置后，也需要调度任务
      await SyncScheduler.schedulePeriodicSync(settings);
    } catch (e) {
      emit(SyncFailure(
        error: '加载设置失败: $e',
        settings: const SyncSettings(),
      ));
    }
  }

  Future<void> _onUpdateSyncSettings(
      UpdateSyncSettings event, Emitter<SyncState> emit) async {
    try {
      final settingsRepository = await getIt.getAsync<SyncSettingsRepository>();
      await settingsRepository.updateSyncSettings(event.settings);

      // 更新调度
      await SyncScheduler.schedulePeriodicSync(event.settings);

      emit(SyncSettingsLoaded(event.settings));
    } catch (e) {
      emit(SyncFailure(
        error: '更新设置失败: $e',
        settings: event.settings,
      ));
    }
  }

  @override
  Future<void> close() {
    _progressSubscription?.cancel();
    return super.close();
  }
}
