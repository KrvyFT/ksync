import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;

import '../../domain/repositories/sync_settings_repository.dart';
import '../blocs/file_explorer_bloc.dart';
import 'media_viewer_page.dart';
import '../../domain/repositories/webdav_repository.dart'; // Import WebdavFileInfo

class FileExplorerPage extends StatefulWidget {
  const FileExplorerPage({super.key});

  @override
  State<FileExplorerPage> createState() => _FileExplorerPageState();
}

class _FileExplorerPageState extends State<FileExplorerPage> {
  bool _isGridView = false;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => FileExplorerBloc()..add(const NavigateToPath('/')),
      child: Scaffold(
        body: BlocBuilder<FileExplorerBloc, FileExplorerState>(
          builder: (context, state) {
            return RefreshIndicator(
              onRefresh: () async {
                final bloc = context.read<FileExplorerBloc>();
                if (state is FileExplorerLoaded) {
                  bloc.add(NavigateToPath(state.currentPath, forceRefresh: true));
                } else if (state is FileExplorerError) {
                  bloc.add(const NavigateToPath('/', forceRefresh: true));
                }
                await bloc.stream.firstWhere((s) => s is! FileExplorerLoading);
              },
              child: CustomScrollView(
                slivers: [
                  SliverAppBar.medium(
                    title: Text(_getTitle(state)),
                    leading: _buildLeading(context, state),
                    actions: [
                      if (state is FileExplorerLoaded && state.files.isNotEmpty)
                        IconButton(
                          icon: Icon(_isGridView ? Icons.view_list_outlined : Icons.grid_view_outlined),
                          tooltip: 'Toggle View',
                          onPressed: () {
                            setState(() {
                              _isGridView = !_isGridView;
                            });
                          },
                        ),
                    ],
                    floating: true,
                    snap: true,
                  ),
                  _buildBody(context, state),
                ],
              ),
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
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
          onRetry: () => context.read<FileExplorerBloc>().add(const NavigateToPath('/', forceRefresh: true)),
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
      return _isGridView
          ? _buildGridView(context, state.files)
          : _buildListView(context, state.files);
    }
    return SliverFillRemaining(
      child: _buildInfoState(
        context: context,
        icon: Icons.hourglass_empty,
        message: 'Initializing...',
      ),
    );
  }

  Widget _buildListView(BuildContext context, List<WebdavFileInfo> files) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final file = files[index];
            return _FileListItem(
              file: file,
              onTap: () => _onFileTap(context, file),
            );
          },
          childCount: files.length,
        ),
      ),
    );
  }

  Widget _buildGridView(BuildContext context, List<WebdavFileInfo> files) {
    return SliverPadding(
      padding: const EdgeInsets.all(12.0),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 200.0,
          mainAxisSpacing: 12.0,
          crossAxisSpacing: 12.0,
          childAspectRatio: 0.9,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final file = files[index];
            return _FileGridItem(
              file: file,
              onTap: () => _onFileTap(context, file),
            );
          },
          childCount: files.length,
        ),
      ),
    );
  }

  void _onFileTap(BuildContext context, WebdavFileInfo file) {
    if (file.isDirectory) {
      context.read<FileExplorerBloc>().add(NavigateToPath(file.path));
    } else {
      _handleFileTap(context, file);
    }
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
  
  void _handleFileTap(BuildContext context, WebdavFileInfo file) async {
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
}

// --- Helper Widgets ---

class _FileListItem extends StatelessWidget {
  const _FileListItem({required this.file, this.onTap});

  final WebdavFileInfo file;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isFolder = file.isDirectory;

    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.0),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              _FileIcon(file: file),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      file.name,
                      style: theme.textTheme.bodyLarge,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isFolder
                          ? 'Folder'
                          : '${_formatSize(file.size)} • ${DateFormat.yMMMd().format(file.lastModified)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FileGridItem extends StatelessWidget {
  const _FileGridItem({required this.file, this.onTap});
  
  final WebdavFileInfo file;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Center(
                child: _FileIcon(file: file, size: 48),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                file.name,
                style: theme.textTheme.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FileIcon extends StatelessWidget {
  const _FileIcon({required this.file, this.size = 40});

  final WebdavFileInfo file;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconData = _getIconForFile(file);
    final color = file.isDirectory
        ? theme.colorScheme.primary
        : theme.colorScheme.secondary;
    
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Icon(iconData, color: color, size: size * 0.6),
    );
  }
}

// --- Utility Functions ---

IconData _getIconForFile(WebdavFileInfo file) {
  if (file.isDirectory) return Icons.folder_outlined;
  final extension = p.extension(file.name).toLowerCase();
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
  if (['.pdf'].contains(extension)) {
    return Icons.picture_as_pdf_outlined;
  }
  if (['.doc', '.docx', '.odt'].contains(extension)) {
    return Icons.description_outlined;
  }
  return Icons.insert_drive_file_outlined;
}

String _formatSize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  if (bytes < 1024 * 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
}
