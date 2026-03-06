// GENERATED CODE - DO NOT MODIFY BY HAND
// Updated to include DRM fields (HiveField 14, 15, 16)

part of 'channel.dart';

class ChannelAdapter extends TypeAdapter<Channel> {
  @override
  final int typeId = 0;

  @override
  Channel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Channel(
      id: fields[0] as String,
      name: fields[1] as String,
      streamUrl: fields[2] as String,
      logoUrl: fields[3] as String?,
      groupTitle: fields[4] as String,
      tvgId: fields[5] as String?,
      tvgName: fields[6] as String?,
      epgChannelId: fields[7] as String?,
      headers: (fields[8] as Map?)?.cast<String, String>(),
      isFavorite: fields[9] as bool,
      country: fields[10] as String?,
      language: fields[11] as String?,
      watchCount: fields[12] as int,
      lastWatched: fields[13] as DateTime?,
      licenseType: fields[14] as String?,
      rawLicenseKey: fields[15] as String?,
      clearKeys: (fields[16] as List?)
          ?.map((e) => (e as Map).cast<String, String>())
          .toList(),
    );
  }

  @override
  void write(BinaryWriter writer, Channel obj) {
    writer
      ..writeByte(17)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.streamUrl)
      ..writeByte(3)
      ..write(obj.logoUrl)
      ..writeByte(4)
      ..write(obj.groupTitle)
      ..writeByte(5)
      ..write(obj.tvgId)
      ..writeByte(6)
      ..write(obj.tvgName)
      ..writeByte(7)
      ..write(obj.epgChannelId)
      ..writeByte(8)
      ..write(obj.headers)
      ..writeByte(9)
      ..write(obj.isFavorite)
      ..writeByte(10)
      ..write(obj.country)
      ..writeByte(11)
      ..write(obj.language)
      ..writeByte(12)
      ..write(obj.watchCount)
      ..writeByte(13)
      ..write(obj.lastWatched)
      ..writeByte(14)
      ..write(obj.licenseType)
      ..writeByte(15)
      ..write(obj.rawLicenseKey)
      ..writeByte(16)
      ..write(obj.clearKeys);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChannelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class CategoryModelAdapter extends TypeAdapter<CategoryModel> {
  @override
  final int typeId = 2;

  @override
  CategoryModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CategoryModel(
      name: fields[0] as String,
      channelCount: fields[1] as int,
    );
  }

  @override
  void write(BinaryWriter writer, CategoryModel obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.channelCount);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CategoryModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
