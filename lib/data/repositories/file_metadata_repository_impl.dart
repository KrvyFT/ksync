import 'package:hive_flutter/hive_flutter.dart';
import 'package:path/path.dart' as path;

import '../../domain/entities/file_metadata.dart';
import '../../domain/repositories/file_metadata_repository.dart';
import '../models/file_metadata_model.dart';

/// 文件元数据仓库实现
class FileMetadataRepositoryImpl implements FileMetadataRepository {
  static const String _boxName = 'file_metadata_box';
  late Box<FileMetadataModel> _box;

  /// 初始化仓库
  Future<void> initialize() async {
    _box = await Hive.openBox<FileMetadataModel>(_boxName);
  }

  @override
  Future<List<FileMetadata>> getAllFileMetadata() async {
    final models = _box.values.toList();
    return models.map((model) => model.toEntity()).toList();
  }

  @override
  Future<FileMetadata?> getFileMetadataByLocalPath(String localPath) async {
    final model = _box.get(localPath);
    return model?.toEntity();
  }

  @override
  Future<FileMetadata?> getFileMetadataByRemotePath(String remotePath) async {
    final models = _box.values.where((model) => model.remotePath == remotePath);
    if (models.isEmpty) return null;
    return models.first.toEntity();
  }

  @override
  Future<void> saveFileMetadata(FileMetadata metadata) async {
    final model = FileMetadataModel.fromEntity(metadata);
    await _box.put(metadata.localPath, model);
  }

  @override
  Future<void> updateFileMetadata(FileMetadata metadata) async {
    await saveFileMetadata(metadata);
  }

  @override
  Future<void> deleteFileMetadata(String localPath) async {
    await _box.delete(localPath);
  }

  @override
  Future<void> saveAllFileMetadata(List<FileMetadata> metadataList) async {
    final models = metadataList.map((metadata) => 
        MapEntry(metadata.localPath, FileMetadataModel.fromEntity(metadata)));
    await _box.putAll(Map.fromEntries(models));
  }

  @override
  Future<void> deleteAllFileMetadata(List<String> localPaths) async {
    await _box.deleteAll(localPaths);
  }

  @override
  Future<void> clearAllFileMetadata() async {
    await _box.clear();
  }

  @override
  Future<List<FileMetadata>> getFileMetadataByDirectory(String directoryPath) async {
    final models = _box.values.where((model) => 
        path.dirname(model.localPath) == directoryPath);
    return models.map((model) => model.toEntity()).toList();
  }

  @override
  Future<bool> exists(String localPath) async {
    return _box.containsKey(localPath);
  }

  /// 关闭仓库
  Future<void> close() async {
    await _box.close();
  }
}
