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
  const NavigateToPath(this.path);
  @override
  List<Object> get props => [path];
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

  FileExplorerBloc() : super(FileExplorerInitial()) {
    on<NavigateToPath>(_onNavigateToPath);
  }

  Future<void> _onNavigateToPath(
      NavigateToPath event, Emitter<FileExplorerState> emit) async {
    emit(FileExplorerLoading());
    try {
      // Ensure repository is initialized
      if (_webdavRepository == null) {
        final settingsRepo = await getIt.getAsync<SyncSettingsRepository>();
        final settings = await settingsRepo.getSyncSettings();
        final password = await settingsRepo.getPassword();
        if (!settings.isWebdavConfigured || password == null) {
          emit(const FileExplorerError(
              'WebDAV not configured. Please check your settings.'));
          return;
        }
        // Now we can safely get the lazy singleton instance
        _webdavRepository = getIt<WebdavRepository>();
        await _webdavRepository!
            .connect(settings.webdavUrl!, settings.username!, password);
      }

      final files = await _webdavRepository!.listDirectory(event.path);
      // Sort files: folders first, then alphabetically
      files.sort((a, b) {
        if (a.isDirectory && !b.isDirectory) return -1;
        if (!a.isDirectory && b.isDirectory) return 1;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
      emit(FileExplorerLoaded(event.path, files));
    } catch (e) {
      // Invalidate repository on error to force reconnection next time
      _webdavRepository = null;
      emit(FileExplorerError('Failed to load files: ${e.toString()}'));
    }
  }
}
