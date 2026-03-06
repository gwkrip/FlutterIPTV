import 'package:hive/hive.dart';

part 'channel.g.dart';

@HiveType(typeId: 0)
class Channel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String streamUrl;

  @HiveField(3)
  final String? logoUrl;

  @HiveField(4)
  final String groupTitle;

  @HiveField(5)
  final String? tvgId;

  @HiveField(6)
  final String? tvgName;

  @HiveField(7)
  final String? epgChannelId;

  @HiveField(8)
  final Map<String, String>? headers;

  @HiveField(9)
  bool isFavorite;

  @HiveField(10)
  final String? country;

  @HiveField(11)
  final String? language;

  @HiveField(12)
  int watchCount;

  @HiveField(13)
  DateTime? lastWatched;

  // ── DRM fields ──────────────────────────────────────────────────
  @HiveField(14)
  final String? licenseType;

  @HiveField(15)
  final String? rawLicenseKey;

  @HiveField(16)
  final List<Map<String, String>>? clearKeys;

  Channel({
    required this.id,
    required this.name,
    required this.streamUrl,
    this.logoUrl,
    required this.groupTitle,
    this.tvgId,
    this.tvgName,
    this.epgChannelId,
    this.headers,
    this.isFavorite = false,
    this.country,
    this.language,
    this.watchCount = 0,
    this.lastWatched,
    this.licenseType,
    this.rawLicenseKey,
    this.clearKeys,
  });

  bool get hasDrm => licenseType != null;
  bool get hasClearKey =>
      licenseType == 'clearkey' &&
      clearKeys != null &&
      clearKeys!.isNotEmpty;

  Channel copyWith({
    String? id,
    String? name,
    String? streamUrl,
    String? logoUrl,
    String? groupTitle,
    String? tvgId,
    String? tvgName,
    String? epgChannelId,
    Map<String, String>? headers,
    bool? isFavorite,
    String? country,
    String? language,
    int? watchCount,
    DateTime? lastWatched,
    String? licenseType,
    String? rawLicenseKey,
    List<Map<String, String>>? clearKeys,
  }) {
    return Channel(
      id: id ?? this.id,
      name: name ?? this.name,
      streamUrl: streamUrl ?? this.streamUrl,
      logoUrl: logoUrl ?? this.logoUrl,
      groupTitle: groupTitle ?? this.groupTitle,
      tvgId: tvgId ?? this.tvgId,
      tvgName: tvgName ?? this.tvgName,
      epgChannelId: epgChannelId ?? this.epgChannelId,
      headers: headers ?? this.headers,
      isFavorite: isFavorite ?? this.isFavorite,
      country: country ?? this.country,
      language: language ?? this.language,
      watchCount: watchCount ?? this.watchCount,
      lastWatched: lastWatched ?? this.lastWatched,
      licenseType: licenseType ?? this.licenseType,
      rawLicenseKey: rawLicenseKey ?? this.rawLicenseKey,
      clearKeys: clearKeys ?? this.clearKeys,
    );
  }

  @override
  String toString() =>
      'Channel(name: $name, group: $groupTitle, drm: $licenseType)';
}

@HiveType(typeId: 2)
class CategoryModel extends HiveObject {
  @HiveField(0)
  final String name;

  @HiveField(1)
  int channelCount;

  CategoryModel({
    required this.name,
    this.channelCount = 0,
  });
}
