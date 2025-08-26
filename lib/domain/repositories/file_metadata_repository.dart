import '../entities/file_metadata.dart';

/// 文件元数据仓库接口
abstract class FileMetadataRepository {
  /// 获取所有文件元数据
  Future<List<FileMetadata>> getAllFileMetadata();
  
  /// 根据本地路径获取文件元数据
  Future<FileMetadata?> getFileMetadataByLocalPath(String localPath);
  
  /// 根据远程路径获取文件元数据
  Future<FileMetadata?> getFileMetadataByRemotePath(String remotePath);
  
  /// 保存文件元数据
  Future<void> saveFileMetadata(FileMetadata metadata);
  
  /// 更新文件元数据
  Future<void> updateFileMetadata(FileMetadata metadata);
  
  /// 删除文件元数据
  Future<void> deleteFileMetadata(String localPath);
  
  /// 批量保存文件元数据
  Future<void> saveAllFileMetadata(List<FileMetadata> metadataList);
  
  /// 批量删除文件元数据
  Future<void> deleteAllFileMetadata(List<String> localPaths);
  
  /// 清空所有文件元数据
  Future<void> clearAllFileMetadata();
  
  /// 获取指定目录下的所有文件元数据
  Future<List<FileMetadata>> getFileMetadataByDirectory(String directoryPath);
  
  /// 检查文件元数据是否存在
  Future<bool> exists(String localPath);
}
