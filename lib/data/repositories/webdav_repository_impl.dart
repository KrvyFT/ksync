import 'dart:io' as io;
import 'dart:typed_data' show Uint8List;
import 'package:webdav_client/webdav_client.dart' as wd;
import 'package:path/path.dart' as p;
import 'dart:typed_data';

import '../../domain/repositories/webdav_repository.dart';

/// WebDAV 仓库实现
class WebdavRepositoryImpl implements WebdavRepository {
  wd.Client? _client;
  String? _currentUrl;
  String? _currentUsername;
  String? _currentPassword;

  @override
  Future<void> connect(String url, String username, String password) async {
    // 如果已经连接到相同的服务器，不需要重新连接
    if (_client != null && 
        _currentUrl == url && 
        _currentUsername == username && 
        _currentPassword == password) {
      return;
    }

    // 断开现有连接
    await disconnect();

    try {
      // 创建新的客户端连接
      _client = wd.newClient(
        url,
        user: username,
        password: password,
      );

      // 测试连接
      await _client!.readDir('/');
      
      // 保存连接信息
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
      return items.map((item) => WebdavFileInfo(
        path: item.path ?? '',
        name: item.name ?? '',
        isDirectory: item.isDir ?? false,
        size: item.size ?? 0,
        lastModified: item.mTime ?? DateTime.now(),
      )).toList();
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
      final pathParts = path.split('/').where((part) => part.isNotEmpty).toList();
      String currentPath = '';
      
      for (final part in pathParts) {
        currentPath += '/$part';
        try {
          await _client!.mkdir(currentPath);
        } catch (e) {
          // 如果目录已存在，忽略错误
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

      // 确保远程目录存在
      final remoteDir = p.dirname(remotePath);
      if (remoteDir.isNotEmpty && remoteDir != '.') {
        await createDirectoryRecursive(remoteDir);
      }

      // 上传文件
      await _client!.writeFromFile(localPath, remotePath);
    } catch (e) {
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
      // 确保本地目录存在
      final localDir = p.dirname(localPath);
      final localDirectory = io.Directory(localDir);
      if (!await localDirectory.exists()) {
        await localDirectory.create(recursive: true);
      }

      // 下载文件
      // webdav_client 1.x 没有 readToFile；使用 read 将内容写入本地
      final bytes = await _client!.read(remotePath);
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
      // webdav_client 1.x 无 move，采用 copy+remove 近似处理
      final data2 = await _client!.read(sourcePath);
      await _client!.write(destinationPath, Uint8List.fromList(data2));
      await _client!.remove(sourcePath);
    } catch (e) {
      throw Exception('移动文件失败: $e');
    }
  }

  @override
  Future<void> copy(String sourcePath, String destinationPath) async {
    _ensureConnected();
    
    try {
      // webdav_client 1.x 的 copy 接口签名不一致，这里以读写方式实现复制
      final data = await _client!.read(sourcePath);
      await _client!.write(destinationPath, Uint8List.fromList(data)); // <-- 就是把 'io.' 去掉
    } catch (e) {
      throw Exception('复制文件失败: $e');
    }
  }

  @override
  Future<int> getFileSize(String path) async {
    _ensureConnected();
    
    try {
      final items = await _client!.readDir(path);
      if (items.isEmpty) return 0;
      
      return items.first.size ?? 0;
    } catch (e) {
      throw Exception('获取文件大小失败: $e');
    }
  }

  @override
  Future<DateTime> getLastModified(String path) async {
    _ensureConnected();
    
    try {
      final items = await _client!.readDir(path);
      if (items.isEmpty) return DateTime.now();
      
      return items.first.mTime ?? DateTime.now();
    } catch (e) {
      throw Exception('获取最后修改时间失败: $e');
    }
  }

  @override
  Future<bool> isDirectory(String path) async {
    _ensureConnected();
    
    try {
      final items = await _client!.readDir(path);
      if (items.isEmpty) return false;
      
      return items.first.isDir ?? false;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> isFile(String path) async {
    _ensureConnected();
    
    try {
      final items = await _client!.readDir(path);
      if (items.isEmpty) return false;
      
      return !(items.first.isDir ?? true);
    } catch (e) {
      return false;
    }
  }

  /// 确保已连接到 WebDAV 服务器
  void _ensureConnected() {
    if (_client == null) {
      throw Exception('未连接到 WebDAV 服务器');
    }
  }
}
