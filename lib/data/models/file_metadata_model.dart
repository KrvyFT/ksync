import 'package:hive/hive.dart';
import '../../domain/entities/file_metadata.dart';

part 'file_metadata_model.g.dart';

@HiveType(typeId: 0)
class FileMetadataModel extends HiveObject {
  @HiveField(0)
  final String localPath;

  @HiveField(1)
  final String remotePath;

  @HiveField(2)
  final int size;

  @HiveField(3)
  final int lastModifiedTimestamp;

  @HiveField(4)
  final String contentHash;

  FileMetadataModel({
    required this.localPath,
    required this.remotePath,
    required this.size,
    required this.lastModifiedTimestamp,
    required this.contentHash,
  });

  /// 从实体创建模型
  factory FileMetadataModel.fromEntity(FileMetadata entity) {
    return FileMetadataModel(
      localPath: entity.localPath,
      remotePath: entity.remotePath,
      size: entity.size,
      lastModifiedTimestamp: entity.lastModifiedTimestamp,
      contentHash: entity.contentHash,
    );
  }

  /// 转换为实体
  FileMetadata toEntity() {
    return FileMetadata(
      localPath: localPath,
      remotePath: remotePath,
      size: size,
      lastModifiedTimestamp: lastModifiedTimestamp,
      contentHash: contentHash,
    );
  }

  /// 从 JSON 创建实例
  factory FileMetadataModel.fromJson(Map<String, dynamic> json) {
    return FileMetadataModel(
      localPath: json['localPath'] as String,
      remotePath: json['remotePath'] as String,
      size: json['size'] as int,
      lastModifiedTimestamp: json['lastModifiedTimestamp'] as int,
      contentHash: json['contentHash'] as String,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'localPath': localPath,
      'remotePath': remotePath,
      'size': size,
      'lastModifiedTimestamp': lastModifiedTimestamp,
      'contentHash': contentHash,
    };
  }
}
