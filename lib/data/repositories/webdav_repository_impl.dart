import 'dart:io' as io;
import 'dart:typed_data' show Uint8List;
import 'package:webdav_client/webdav_client.dart' as wd;
import 'package:path/path.dart' as p;
import 'dart:async';

import '../../domain/repositories/webdav_repository.dart';

/// WebDAV 仓库实现
class WebdavRepositoryImpl implements WebdavRepository {
  wd.Client? _client;
  String? _currentUrl;
  String? _currentUsername;
  String? _currentPassword;

  @override
  Future<void> connect(String url, String username, String password) async {
    if (_client != null &&
        _currentUrl == url &&
        _currentUsername == username &&
        _currentPassword == password) {
      return;
    }
    await disconnect();
    try {
      _client = wd.newClient(
        url,
        user: username,
        password: password,
      );
      await _client!.readDir('/');
      _currentUrl = url;
      _currentUsername = username;
      _currentPassword = password;
    } catch (e) {
      _client = null;
      _currentUrl = null;
      _currentUsername = null;
      _currentPassword = null;
      throw Exception('连接 WebDAV 服务器失败: $e');
    }
  }

  @override
  Future<void> disconnect() async {
    _client = null;
    _currentUrl = null;
    _currentUsername = null;
    _currentPassword = null;
  }

  @override
  Future<bool> testConnection() async {
    if (_client == null) return false;
    try {
      await _client!.readDir('/');
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<List<WebdavFileInfo>> listDirectory(String path) async {
    _ensureConnected();
    try {
      final items = await _client!.readDir(path);
      return items
          .map((item) => WebdavFileInfo(
                path: item.path ?? '',
                name: item.name ?? '',
                isDirectory: item.isDir ?? false,
                size: item.size ?? 0,
                lastModified: item.mTime ?? DateTime.now(),
              ))
          .toList();
    } catch (e) {
      throw Exception('列出目录失败: $e');
    }
  }

  @override
  Future<void> createDirectory(String path) async {
    _ensureConnected();
    try {
      await _client!.mkdir(path);
    } catch (e) {
      throw Exception('创建目录失败: $e');
    }
  }

  @override
  Future<void> createDirectoryRecursive(String path) async {
    _ensureConnected();
    try {
      final pathParts =
          path.split('/').where((part) => part.isNotEmpty).toList();
      String currentPath = '';
      for (final part in pathParts) {
        currentPath += '/$part';
        try {
          await _client!.mkdir(currentPath);
        } catch (e) {
          if (!e.toString().contains('already exists')) {
            rethrow;
          }
        }
      }
    } catch (e) {
      throw Exception('递归创建目录失败: $e');
    }
  }

  @override
  Future<void> uploadFile(
    String localPath,
    String remotePath,
    UploadProgressCallback? onProgress,
  ) async {
    _ensureConnected();
    try {
      final file = io.File(localPath);
      if (!await file.exists()) {
        throw Exception('本地文件不存在: $localPath');
      }
      final remoteDir = p.dirname(remotePath);
      if (remoteDir.isNotEmpty && remoteDir != '/' && remoteDir != '.') {
        await createDirectoryRecursive(remoteDir);
      }
      await _client!
          .writeFromFile(localPath, remotePath, onProgress: onProgress);
    } catch (e) {
      print('Upload failed for $localPath -> $remotePath. Error: $e');
      throw Exception('上传文件失败: $e');
    }
  }

  @override
  Future<void> downloadFile(
    String remotePath,
    String localPath,
    DownloadProgressCallback? onProgress,
  ) async {
    _ensureConnected();
    try {
      final localDir = p.dirname(localPath);
      final localDirectory = io.Directory(localDir);
      if (!await localDirectory.exists()) {
        await localDirectory.create(recursive: true);
      }
      final bytes = await _client!.read(remotePath, onProgress: onProgress);
      final f = io.File(localPath);
      await f.writeAsBytes(bytes);
    } catch (e) {
      throw Exception('下载文件失败: $e');
    }
  }

  @override
  Future<void> delete(String path) async {
    _ensureConnected();
    try {
      await _client!.remove(path);
    } catch (e) {
      throw Exception('删除失败: $e');
    }
  }

  @override
  Future<bool> exists(String path) async {
    _ensureConnected();
    try {
      // readDir is a reliable way to check for existence in v1.2.2
      await _client!.readDir(path);
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<WebdavFileInfo?> getFileInfo(String path) async {
    _ensureConnected();
    try {
      final items = await _client!.readDir(path);
      if (items.isEmpty) return null;
      final item = items.first;
      return WebdavFileInfo(
        path: item.path ?? '',
        name: item.name ?? '',
        isDirectory: item.isDir ?? false,
        size: item.size ?? 0,
        lastModified: item.mTime ?? DateTime.now(),
      );
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> move(String sourcePath, String destinationPath) async {
    _ensureConnected();
    try {
      // v1.2.2 doesn't have a reliable move, so we copy then delete
      await copy(sourcePath, destinationPath);
      await delete(sourcePath);
    } catch (e) {
      throw Exception('移动文件失败: $e');
    }
  }

  @override
  Future<void> copy(String sourcePath, String destinationPath) async {
    _ensureConnected();
    try {
      final data = await _client!.read(sourcePath);
      await _client!.write(destinationPath, Uint8List.fromList(data));
    } catch (e) {
      throw Exception('复制文件失败: $e');
    }
  }

  @override
  Future<int> getFileSize(String path) async {
    final info = await getFileInfo(path);
    return info?.size ?? 0;
  }

  @override
  Future<DateTime> getLastModified(String path) async {
    final info = await getFileInfo(path);
    return info?.lastModified ?? DateTime.now();
  }

  @override
  Future<bool> isDirectory(String path) async {
    final info = await getFileInfo(path);
    return info?.isDirectory ?? false;
  }

  @override
  Future<bool> isFile(String path) async {
    final info = await getFileInfo(path);
    return !(info?.isDirectory ?? true);
  }

  void _ensureConnected() {
    if (_client == null) {
      throw Exception('未连接到 WebDAV 服务器');
    }
  }

  @override
  Future<List<WebdavFileInfo>> listDirectoryRecursive(String path) async {
    final allFiles = <WebdavFileInfo>[];
    final queue = <String>[path];

    while (queue.isNotEmpty) {
      final currentPath = queue.removeAt(0);
      try {
        final items = await listDirectory(currentPath);
        for (final item in items) {
          if (item.isDirectory) {
            // Avoid infinite loops for '.' or self-references if any
            if (item.path != currentPath) {
              queue.add(item.path);
            }
          } else {
            allFiles.add(item);
          }
        }
      } catch (e) {
        // Log error but continue trying to list other directories
        print('Failed to list directory $currentPath: $e');
      }
    }
    return allFiles;
  }
}
