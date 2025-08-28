// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_log_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SyncLogModelAdapter extends TypeAdapter<SyncLogModel> {
  @override
  final int typeId = 1;

  @override
  SyncLogModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SyncLogModel(
      jobId: fields[0] as String,
      startTime: fields[1] as DateTime,
      endTime: fields[2] as DateTime?,
      status: fields[3] as SyncStatus,
      filesSynced: fields[4] as int,
      filesFailed: fields[5] as int,
      errorMessages: (fields[6] as List).cast<String>(),
      syncedFiles: (fields[7] as List).cast<String>(),
      failedFiles: (fields[8] as Map).cast<String, String>(),
    );
  }

  @override
  void write(BinaryWriter writer, SyncLogModel obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.jobId)
      ..writeByte(1)
      ..write(obj.startTime)
      ..writeByte(2)
      ..write(obj.endTime)
      ..writeByte(3)
      ..write(obj.status)
      ..writeByte(4)
      ..write(obj.filesSynced)
      ..writeByte(5)
      ..write(obj.filesFailed)
      ..writeByte(6)
      ..write(obj.errorMessages)
      ..writeByte(7)
      ..write(obj.syncedFiles)
      ..writeByte(8)
      ..write(obj.failedFiles);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SyncLogModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
