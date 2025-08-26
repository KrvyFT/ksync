// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'file_metadata_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FileMetadataModelAdapter extends TypeAdapter<FileMetadataModel> {
  @override
  final int typeId = 0;

  @override
  FileMetadataModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FileMetadataModel(
      localPath: fields[0] as String,
      remotePath: fields[1] as String,
      size: fields[2] as int,
      lastModifiedTimestamp: fields[3] as int,
      contentHash: fields[4] as String,
    );
  }

  @override
  void write(BinaryWriter writer, FileMetadataModel obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.localPath)
      ..writeByte(1)
      ..write(obj.remotePath)
      ..writeByte(2)
      ..write(obj.size)
      ..writeByte(3)
      ..write(obj.lastModifiedTimestamp)
      ..writeByte(4)
      ..write(obj.contentHash);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FileMetadataModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
