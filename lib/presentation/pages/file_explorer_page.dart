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
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => FileExplorerBloc()..add(const NavigateToPath('/')),
      child: Scaffold(
        appBar: AppBar(
          title: BlocBuilder<FileExplorerBloc, FileExplorerState>(
            builder: (context, state) {
              if (state is FileExplorerLoaded) {
                return Text(state.currentPath == '/'
                    ? 'Server Root'
                    : p.basename(state.currentPath));
              }
              return const Text('Browse Server');
            },
          ),
          leading: BlocBuilder<FileExplorerBloc, FileExplorerState>(
            builder: (context, state) {
              if (state is FileExplorerLoaded && state.currentPath != '/') {
                return IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    final parentPath = p.dirname(state.currentPath);
                    context
                        .read<FileExplorerBloc>()
                        .add(NavigateToPath(parentPath));
                  },
                );
              }
              return const CloseButton();
            },
          ),
        ),
        body: BlocBuilder<FileExplorerBloc, FileExplorerState>(
          builder: (context, state) {
            if (state is FileExplorerLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is FileExplorerError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline,
                          color: Colors.red, size: 48),
                      const SizedBox(height: 16),
                      Text(
                        state.message,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          context
                              .read<FileExplorerBloc>()
                              .add(const NavigateToPath('/'));
                        },
                        child: const Text('Retry'),
                      )
                    ],
                  ),
                ),
              );
            } else if (state is FileExplorerLoaded) {
              if (state.files.isEmpty) {
                return const Center(child: Text('This folder is empty.'));
              }
              return ListView.builder(
                itemCount: state.files.length,
                itemBuilder: (context, index) {
                  final file = state.files[index];
                  return ListTile(
                    leading: Icon(
                        file.isDirectory ? Icons.folder : Icons.insert_drive_file),
                    title: Text(file.name),
                    subtitle: Text(
                        file.isDirectory ? 'Folder' : '${_formatSize(file.size)}'),
                    onTap: () {
                      if (file.isDirectory) {
                        context
                            .read<FileExplorerBloc>()
                            .add(NavigateToPath(file.path));
                      } else {
                        _handleFileTap(context, file);
                      }
                    },
                  );
                },
              );
            }
            return const Center(
                child: Text('Initializing file explorer...'));
          },
        ),
      ),
    );
  }

  void _handleFileTap(BuildContext context, file) async {
    if (_isMediaFile(file.path)) {
      try {
        final settingsRepo = await GetIt.instance.getAsync<SyncSettingsRepository>();
        final settings = await settingsRepo.getSyncSettings();
        final password = await settingsRepo.getPassword();

        if (settings.isWebdavConfigured && password != null && settings.username != null) {
          // Note: This might not handle all edge cases for URL encoding, but works for many servers.
          final fileUrl = Uri.encodeFull('${settings.webdavUrl}${file.path}');
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MediaViewerPage(
                filePath: file.path,
                fileUrl: fileUrl,
                username: settings.username!,
                password: password,
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('WebDAV is not configured or username/password is missing.')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open file: $e')),
        );
      }
    }
    // You could add handlers for other file types here
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
