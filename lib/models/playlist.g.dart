// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'playlist.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PlaylistAdapter extends TypeAdapter<Playlist> {
  @override
  final int typeId = 1;

  @override
  Playlist read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Playlist(
      id: fields[0] as String,
      name: fields[1] as String,
      url: fields[2] as String,
      lastUpdated: fields[3] as DateTime?,
      channelCount: fields[4] as int,
      isActive: fields[5] as bool,
      username: fields[6] as String?,
      password: fields[7] as String?,
      type: fields[8] as PlaylistType,
    );
  }

  @override
  void write(BinaryWriter writer, Playlist obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.url)
      ..writeByte(3)
      ..write(obj.lastUpdated)
      ..writeByte(4)
      ..write(obj.channelCount)
      ..writeByte(5)
      ..write(obj.isActive)
      ..writeByte(6)
      ..write(obj.username)
      ..writeByte(7)
      ..write(obj.password)
      ..writeByte(8)
      ..write(obj.type);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlaylistAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PlaylistTypeAdapter extends TypeAdapter<PlaylistType> {
  @override
  final int typeId = 3;

  @override
  PlaylistType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return PlaylistType.m3u;
      case 1:
        return PlaylistType.xtreamCodes;
      default:
        return PlaylistType.m3u;
    }
  }

  @override
  void write(BinaryWriter writer, PlaylistType obj) {
    switch (obj) {
      case PlaylistType.m3u:
        writer.writeByte(0);
        break;
      case PlaylistType.xtreamCodes:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlaylistTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
