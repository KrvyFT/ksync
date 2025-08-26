import 'package:equatable/equatable.dart';

/// 文件元数据实体，用于存储文件的同步信息
class FileMetadata extends Equatable {
  final String localPath;
  final String remotePath;
  final int size;
  final int lastModifiedTimestamp;
  final String contentHash;

  const FileMetadata({
    required this.localPath,
    required this.remotePath,
    required this.size,
    required this.lastModifiedTimestamp,
    required this.contentHash,
  });

  @override
  List<Object?> get props => [
        localPath,
        remotePath,
        size,
        lastModifiedTimestamp,
        contentHash,
      ];

  /// 创建副本并更新指定字段
  FileMetadata copyWith({
    String? localPath,
    String? remotePath,
    int? size,
    int? lastModifiedTimestamp,
    String? contentHash,
  }) {
    return FileMetadata(
      localPath: localPath ?? this.localPath,
      remotePath: remotePath ?? this.remotePath,
      size: size ?? this.size,
      lastModifiedTimestamp: lastModifiedTimestamp ?? this.lastModifiedTimestamp,
      contentHash: contentHash ?? this.contentHash,
    );
  }

  /// 从 JSON 创建实例
  factory FileMetadata.fromJson(Map<String, dynamic> json) {
    return FileMetadata(
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
