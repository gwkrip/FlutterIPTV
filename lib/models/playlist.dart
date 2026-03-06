import 'package:hive/hive.dart';

part 'playlist.g.dart';

@HiveType(typeId: 1)
class Playlist extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  final String url;

  @HiveField(3)
  DateTime? lastUpdated;

  @HiveField(4)
  int channelCount;

  @HiveField(5)
  bool isActive;

  @HiveField(6)
  final String? username;

  @HiveField(7)
  final String? password;

  @HiveField(8)
  final PlaylistType type;

  Playlist({
    required this.id,
    required this.name,
    required this.url,
    this.lastUpdated,
    this.channelCount = 0,
    this.isActive = false,
    this.username,
    this.password,
    this.type = PlaylistType.m3u,
  });
}

@HiveType(typeId: 3)
enum PlaylistType {
  @HiveField(0)
  m3u,
  @HiveField(1)
  xtreamCodes,
}
