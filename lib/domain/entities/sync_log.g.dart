// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_log.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SyncStatusAdapter extends TypeAdapter<SyncStatus> {
  @override
  final int typeId = 2;

  @override
  SyncStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return SyncStatus.success;
      case 1:
        return SyncStatus.failed;
      case 2:
        return SyncStatus.canceled;
      case 3:
        return SyncStatus.inProgress;
      default:
        return SyncStatus.success;
    }
  }

  @override
  void write(BinaryWriter writer, SyncStatus obj) {
    switch (obj) {
      case SyncStatus.success:
        writer.writeByte(0);
        break;
      case SyncStatus.failed:
        writer.writeByte(1);
        break;
      case SyncStatus.canceled:
        writer.writeByte(2);
        break;
      case SyncStatus.inProgress:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SyncStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
