import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as path;

import '../entities/file_metadata.dart';
import '../entities/sync_log.dart';
import '../entities/sync_settings.dart';
import '../repositories/file_metadata_repository.dart';
import '../repositories/sync_log_repository.dart';
import '../repositories/sync_settings_repository.dart';
import '../repositories/webdav_repository.dart';

/// 同步进度回调
typedef SyncProgressCallback = void Function(
  SyncProgress progress,
);

/// 同步进度信息
class SyncProgress {
  final String currentFile;
  final int currentFileIndex;
  final int totalFiles;
  final int filesSynced;
  final int filesFailed;
  final SyncStatus status;
  final String? errorMessage;

  const SyncProgress({
    required this.currentFile,
    required this.currentFileIndex,
    required this.totalFiles,
    required this.filesSynced,
    required this.filesFailed,
    required this.status,
    this.errorMessage,
  });

  /// 获取进度百分比
  double get progressPercentage {
    if (totalFiles == 0) return 0.0;
    return currentFileIndex / totalFiles;
  }
}

/// 同步引擎用例
class SyncEngineUseCase {
  final FileMetadataRepository _fileMetadataRepository;
  final SyncLogRepository _syncLogRepository;
  final SyncSettingsRepository _syncSettingsRepository;
  final WebdavRepository _webdavRepository;

  SyncEngineUseCase({
    required FileMetadataRepository fileMetadataRepository,
    required SyncLogRepository syncLogRepository,
    required SyncSettingsRepository syncSettingsRepository,
    required WebdavRepository webdavRepository,
  })  : _fileMetadataRepository = fileMetadataRepository,
        _syncLogRepository = syncLogRepository,
        _syncSettingsRepository = syncSettingsRepository,
        _webdavRepository = webdavRepository;

  /// 执行同步任务
  Future<SyncLog> executeSync({
    SyncProgressCallback? onProgress,
  }) async {
    final settings = await _syncSettingsRepository.getSyncSettings();

    if (!settings.isWebdavConfigured) {
      throw Exception('WebDAV 未配置');
    }

    if (!settings.hasSyncDirectories) {
      throw Exception('未选择同步目录');
    }

    final jobId = _generateJobId();
    final startTime = DateTime.now();

    // 创建同步日志
    final syncLog = SyncLog(
      jobId: jobId,
      startTime: startTime,
      status: SyncStatus.inProgress,
      filesSynced: 0,
      filesFailed: 0,
      errorMessages: const [],
    );

    await _syncLogRepository.saveSyncLog(syncLog);

    try {
      // 连接到 WebDAV 服务器
      final password = await _syncSettingsRepository.getPassword();
      if (password == null) {
        throw Exception('WebDAV 密码未设置');
      }

      await _webdavRepository.connect(
        settings.webdavUrl!,
        settings.username!,
        password,
      );

      // 执行同步逻辑
      final result = await _performSync(
        settings: settings,
        onProgress: onProgress,
      );

      // 更新同步日志
      final updatedSyncLog = syncLog.copyWith(
        endTime: DateTime.now(),
        status: SyncStatus.success,
        filesSynced: result.filesSynced,
        filesFailed: result.filesFailed,
        errorMessages: result.errorMessages,
      );

      await _syncLogRepository.updateSyncLog(updatedSyncLog);

      return updatedSyncLog;
    } catch (e) {
      // 更新同步日志为失败状态
      final updatedSyncLog = syncLog.copyWith(
        endTime: DateTime.now(),
        status: SyncStatus.failed,
        errorMessages: [e.toString()],
      );

      await _syncLogRepository.updateSyncLog(updatedSyncLog);

      rethrow;
    } finally {
      // 断开 WebDAV 连接
      await _webdavRepository.disconnect();
    }
  }

  /// 执行具体的同步逻辑
  Future<SyncResult> _performSync({
    required SyncSettings settings,
    SyncProgressCallback? onProgress,
  }) async {
    final allFiles = <String>[];
    final errorMessages = <String>[];
    int filesSynced = 0;
    int filesFailed = 0;

    // 扫描所有同步目录
    for (final directory in settings.syncDirectories) {
      try {
        final files = await _scanDirectory(directory, settings.excludePatterns);
        allFiles.addAll(files);
      } catch (e) {
        errorMessages.add('扫描目录 $directory 失败: $e');
      }
    }

    // 处理删除的文件
    final deletedFiles = await _handleDeletedFiles();
    filesSynced += deletedFiles;

    // 处理新增和修改的文件
    for (int i = 0; i < allFiles.length; i++) {
      final file = allFiles[i];

      try {
        onProgress?.call(SyncProgress(
          currentFile: file,
          currentFileIndex: i,
          totalFiles: allFiles.length,
          filesSynced: filesSynced,
          filesFailed: filesFailed,
          status: SyncStatus.inProgress,
        ));

        final result = await _syncFile(file, settings);
        if (result) {
          filesSynced++;
        } else {
          filesFailed++;
        }
      } catch (e) {
        filesFailed++;
        errorMessages.add('同步文件 $file 失败: $e');
      }
    }

    return SyncResult(
      filesSynced: filesSynced,
      filesFailed: filesFailed,
      errorMessages: errorMessages,
    );
  }

  /// 扫描目录获取所有文件
  Future<List<String>> _scanDirectory(
      String directory, List<String> excludePatterns) async {
    final files = <String>[];
    final dir = Directory(directory);

    if (!await dir.exists()) {
      return files;
    }

    await for (final entity in dir.list(recursive: true)) {
      if (entity is File) {
        final relativePath = path.relative(entity.path, from: directory);

        // 检查是否被排除
        if (_shouldExclude(relativePath, excludePatterns)) {
          continue;
        }

        files.add(entity.path);
      }
    }

    return files;
  }

  /// 检查文件是否应该被排除
  bool _shouldExclude(String filePath, List<String> excludePatterns) {
    for (final pattern in excludePatterns) {
      if (_matchesPattern(filePath, pattern)) {
        return true;
      }
    }
    return false;
  }

  /// 检查文件路径是否匹配模式
  bool _matchesPattern(String filePath, String pattern) {
    // 简单的通配符匹配实现
    if (pattern.contains('*')) {
      final regex = pattern.replaceAll('*', '.*');
      return RegExp(regex).hasMatch(filePath);
    }

    return filePath.contains(pattern);
  }

  /// 处理已删除的文件
  Future<int> _handleDeletedFiles() async {
    final allMetadata = await _fileMetadataRepository.getAllFileMetadata();
    int deletedCount = 0;

    for (final metadata in allMetadata) {
      final file = File(metadata.localPath);
      if (!await file.exists()) {
        try {
          // 删除远程文件
          await _webdavRepository.delete(metadata.remotePath);

          // 删除本地元数据
          await _fileMetadataRepository.deleteFileMetadata(metadata.localPath);

          deletedCount++;
        } catch (e) {
          // 记录错误但继续处理其他文件
          print('删除远程文件失败: ${metadata.remotePath}, 错误: $e');
        }
      }
    }

    return deletedCount;
  }

  /// 同步单个文件
  Future<bool> _syncFile(String localPath, SyncSettings settings) async {
    final file = File(localPath);
    if (!await file.exists()) {
      return false;
    }

    final fileStat = await file.stat();
    final contentHash = await _calculateFileHash(localPath);

    // 构建远程路径
    final relativePath = _getRelativePath(localPath, settings.syncDirectories);
    // 根据要求，将所有文件同步到服务器的 /Sync 目录下
    final remotePath = path.join('/', relativePath);

    // 检查是否需要同步
    final existingMetadata =
        await _fileMetadataRepository.getFileMetadataByLocalPath(localPath);

    if (existingMetadata != null) {
      // 检查文件是否已修改
      if (existingMetadata.size == fileStat.size &&
          existingMetadata.lastModifiedTimestamp ==
              fileStat.modified.millisecondsSinceEpoch &&
          existingMetadata.contentHash == contentHash) {
        // 文件未修改，跳过
        return true;
      }
    }

    try {
      // 确保远程目录存在
      final remoteDir = path.dirname(remotePath);
      await _webdavRepository.createDirectoryRecursive(remoteDir);

      // 上传文件
      await _webdavRepository.uploadFile(localPath, remotePath, null);

      // 更新或创建元数据
      final newMetadata = FileMetadata(
        localPath: localPath,
        remotePath: remotePath,
        size: fileStat.size,
        lastModifiedTimestamp: fileStat.modified.millisecondsSinceEpoch,
        contentHash: contentHash,
      );

      if (existingMetadata != null) {
        await _fileMetadataRepository.updateFileMetadata(newMetadata);
      } else {
        await _fileMetadataRepository.saveFileMetadata(newMetadata);
      }

      return true;
    } catch (e) {
      print('同步文件失败: $localPath, 错误: $e');
      return false;
    }
  }

  /// 计算文件哈希值
  Future<String> _calculateFileHash(String filePath) async {
    final file = File(filePath);
    final bytes = await file.readAsBytes();
    final digest = md5.convert(bytes);
    return digest.toString();
  }

  /// 获取相对路径
  String _getRelativePath(String filePath, List<String> syncDirectories) {
    for (final directory in syncDirectories) {
      if (filePath.startsWith(directory)) {
        return path.relative(filePath, from: directory);
      }
    }
    return path.basename(filePath);
  }

  /// 生成任务ID
  String _generateJobId() {
    return 'sync_${DateTime.now().millisecondsSinceEpoch}';
  }
}

/// 同步结果
class SyncResult {
  final int filesSynced;
  final int filesFailed;
  final List<String> errorMessages;

  const SyncResult({
    required this.filesSynced,
    required this.filesFailed,
    required this.errorMessages,
  });
}
