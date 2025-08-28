import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../core/di/injection.dart';
import '../../domain/repositories/webdav_repository.dart';
import '../../domain/repositories/sync_settings_repository.dart';

// Events
abstract class FileExplorerEvent extends Equatable {
  const FileExplorerEvent();
  @override
  List<Object> get props => [];
}

class NavigateToPath extends FileExplorerEvent {
  final String path;
  final bool forceRefresh;

  const NavigateToPath(this.path, {this.forceRefresh = false});

  @override
  List<Object> get props => [path, forceRefresh];
}

// States
abstract class FileExplorerState extends Equatable {
  const FileExplorerState();
  @override
  List<Object> get props => [];
}

class FileExplorerInitial extends FileExplorerState {}

class FileExplorerLoading extends FileExplorerState {}

class FileExplorerLoaded extends FileExplorerState {
  final String currentPath;
  final List<WebdavFileInfo> files;
  const FileExplorerLoaded(this.currentPath, this.files);
  @override
  List<Object> get props => [currentPath, files];
}

class FileExplorerError extends FileExplorerState {
  final String message;
  const FileExplorerError(this.message);
  @override
  List<Object> get props => [message];
}

// Bloc
class FileExplorerBloc extends Bloc<FileExplorerEvent, FileExplorerState> {
  WebdavRepository? _webdavRepository;
  final Map<String, List<WebdavFileInfo>> _cache = {};

  FileExplorerBloc() : super(FileExplorerInitial()) {
    on<NavigateToPath>(_onNavigateToPath);
  }

  Future<WebdavRepository> _getConnectedRepository() async {
    if (_webdavRepository != null) {
      return _webdavRepository!;
    }

    final settingsRepo = await getIt.getAsync<SyncSettingsRepository>();
    final settings = await settingsRepo.getSyncSettings();
    final password = await settingsRepo.getPassword();

    if (!settings.isWebdavConfigured || password == null) {
      throw Exception('WebDAV not configured. Please check your settings.');
    }

    _webdavRepository = getIt<WebdavRepository>();
    await _webdavRepository!
        .connect(settings.webdavUrl!, settings.username!, password);
    return _webdavRepository!;
  }

  Future<void> _onNavigateToPath(
      NavigateToPath event, Emitter<FileExplorerState> emit) async {
    emit(FileExplorerLoading());

    // Check cache first, unless a refresh is forced
    if (event.forceRefresh) {
      _cache.remove(event.path);
    } else if (_cache.containsKey(event.path)) {
      emit(FileExplorerLoaded(event.path, _cache[event.path]!));
      return;
    }

    try {
      final repo = await _getConnectedRepository();
      final files = await repo.listDirectory(event.path);

      // Sort files: folders first, then alphabetically
      files.sort((a, b) {
        if (a.isDirectory && !b.isDirectory) return -1;
        if (!a.isDirectory && b.isDirectory) return 1;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
      
      _cache[event.path] = files; // Save to cache
      emit(FileExplorerLoaded(event.path, files));
    } catch (e) {
      // DO NOT invalidate repository here. Let's try to recover on the next attempt.
      emit(FileExplorerError('Failed to load files: ${e.toString()}'));
    }
  }
}
