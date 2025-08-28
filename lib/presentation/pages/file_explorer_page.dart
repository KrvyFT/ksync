import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:path/path.dart' as p;

import '../../domain/repositories/sync_settings_repository.dart';
import '../blocs/file_explorer_bloc.dart';
import 'media_viewer_page.dart';

class FileExplorerPage extends StatelessWidget {
  const FileExplorerPage({super.key});

  @override
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => FileExplorerBloc()..add(const NavigateToPath('/')),
      child: Scaffold(
        body: BlocBuilder<FileExplorerBloc, FileExplorerState>(
          builder: (context, state) {
            return CustomScrollView(
              slivers: [
                SliverAppBar.medium(
                  title: Text(_getTitle(state)),
                  leading: _buildLeading(context, state),
                  floating: true,
                  snap: true,
                ),
                _buildBody(context, state),
              ],
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            // TODO: Implement file upload logic
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Upload feature coming soon!')),
            );
          },
          child: const Icon(Icons.upload_file),
          tooltip: 'Upload File',
        ),
      ),
    );
  }

  String _getTitle(FileExplorerState state) {
    if (state is FileExplorerLoaded) {
      return state.currentPath == '/'
          ? 'Server Root'
          : p.basename(state.currentPath);
    }
    return 'Browse Server';
  }

  Widget? _buildLeading(BuildContext context, FileExplorerState state) {
    if (state is FileExplorerLoaded && state.currentPath != '/') {
      return IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          final parentPath = p.dirname(state.currentPath);
          context.read<FileExplorerBloc>().add(NavigateToPath(parentPath));
        },
      );
    }
    // On root, show a close button instead of back
    return const CloseButton();
  }

  Widget _buildBody(BuildContext context, FileExplorerState state) {
    if (state is FileExplorerLoading) {
      return const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator()),
      );
    } else if (state is FileExplorerError) {
      return SliverFillRemaining(
        child: _buildInfoState(
          context: context,
          icon: Icons.cloud_off,
          message: state.message,
          onRetry: () => context.read<FileExplorerBloc>().add(const NavigateToPath('/')),
        ),
      );
    } else if (state is FileExplorerLoaded) {
      if (state.files.isEmpty) {
        return SliverFillRemaining(
          child: _buildInfoState(
            context: context,
            icon: Icons.folder_off_outlined,
            message: 'This folder is empty.',
          ),
        );
      }
      return SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final file = state.files[index];
            return ListTile(
              leading: Icon(
                file.isDirectory ? Icons.folder_outlined : _getFileIcon(file.name),
              ),
              title: Text(
                file.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                file.isDirectory ? 'Folder' : _formatSize(file.size),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              onTap: () {
                if (file.isDirectory) {
                  context.read<FileExplorerBloc>().add(NavigateToPath(file.path));
                } else {
                  _handleFileTap(context, file);
                }
              },
            );
          },
          childCount: state.files.length,
        ),
      );
    }
    return SliverFillRemaining(
      child: _buildInfoState(
        context: context,
        icon: Icons.hourglass_empty,
        message: 'Initializing...',
      ),
    );
  }
  
  IconData _getFileIcon(String fileName) {
    final extension = p.extension(fileName).toLowerCase();
    if (['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp'].contains(extension)) {
      return Icons.image_outlined;
    }
    if (['.mp4', '.mov', '.avi', '.mkv', '.wmv', '.flv'].contains(extension)) {
      return Icons.video_library_outlined;
    }
    if (['.mp3', '.wav', '.aac', '.flac'].contains(extension)) {
      return Icons.music_note_outlined;
    }
    if (['.zip', '.rar', '.7z', '.tar'].contains(extension)) {
      return Icons.archive_outlined;
    }
    return Icons.insert_drive_file_outlined;
  }

  Widget _buildInfoState({
    required BuildContext context,
    required IconData icon,
    required String message,
    VoidCallback? onRetry,
  }) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: theme.colorScheme.primary),
            const SizedBox(height: 24),
            Text(message,
                textAlign: TextAlign.center, style: theme.textTheme.titleMedium),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              )
            ]
          ],
        ),
      ),
    );
  }

  void _handleFileTap(BuildContext context, file) async {
    if (_isMediaFile(file.path)) {
      try {
        final currentState = BlocProvider.of<FileExplorerBloc>(context).state;
        if (currentState is! FileExplorerLoaded) return;

        final mediaFiles = currentState.files
            .where((f) => !f.isDirectory && _isMediaFile(f.path))
            .toList();
        final initialIndex = mediaFiles.indexOf(file);

        if (initialIndex == -1) return;

        final settingsRepo = await GetIt.instance.getAsync<SyncSettingsRepository>();
        final settings = await settingsRepo.getSyncSettings();
        final password = await settingsRepo.getPassword();

        if (settings.isWebdavConfigured &&
            password != null &&
            settings.username != null) {
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  MediaViewerPage(
                mediaFiles: mediaFiles,
                initialIndex: initialIndex,
                webdavUrl: settings.webdavUrl!,
                username: settings.username!,
                password: password,
              ),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                return FadeTransition(opacity: animation, child: child);
              },
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'WebDAV is not configured or username/password is missing.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open file: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  bool _isMediaFile(String path) {
    final extension = p.extension(path).toLowerCase();
    const imageExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp'];
    const videoExtensions = ['.mp4', '.mov', '.avi', '.mkv', '.wmv', '.flv'];
    return imageExtensions.contains(extension) ||
        videoExtensions.contains(extension);
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}
