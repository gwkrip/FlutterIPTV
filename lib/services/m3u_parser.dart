import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import '../models/channel.dart';
import '../core/constants/app_constants.dart';

/// Parsed stream URL result — separates the actual URL from
/// pipe-appended options like DRM keys and custom headers.
class ParsedStreamUrl {
  /// The clean stream URL (no pipe options)
  final String url;

  /// HTTP headers to pass to the player (User-Agent, Referer, Origin, …)
  final Map<String, String> headers;

  /// ClearKey DRM info, if present.
  /// Each entry is { 'kid': '…', 'key': '…' }
  final List<Map<String, String>> clearKeys;

  /// Raw license type string (e.g. "clearkey", "widevine")
  final String? licenseType;

  /// Raw license key/URL string (before we parse it)
  final String? rawLicenseKey;

  const ParsedStreamUrl({
    required this.url,
    this.headers = const {},
    this.clearKeys = const [],
    this.licenseType,
    this.rawLicenseKey,
  });

  bool get hasDrm => licenseType != null;
  bool get hasClearKey => clearKeys.isNotEmpty;
}

class M3UParser {
  static const _uuid = Uuid();

  // ──────────────────────────────────────────────────────────────────
  // Public API
  // ──────────────────────────────────────────────────────────────────

  static Future<List<Channel>> parseFromUrl(String url) async {
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {'User-Agent': AppConstants.defaultUserAgent},
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final content = utf8.decode(response.bodyBytes);
        return parseContent(content);
      } else {
        throw Exception('Failed to fetch playlist: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error loading playlist: $e');
    }
  }

  static List<Channel> parseContent(String content) {
    final lines = content.split('\n');
    final channels = <Channel>[];

    if (lines.isEmpty || !lines.first.trim().startsWith('#EXTM3U')) {
      throw Exception('Invalid M3U file format');
    }

    String? currentName;
    String? currentLogo;
    String? currentGroup;
    String? currentTvgId;
    String? currentTvgName;
    // Headers accumulated from #EXTVLCOPT / #KODIPROP lines
    Map<String, String> currentHeaders = {};
    // DRM info from #KODIPROP lines
    String? currentLicenseType;
    String? currentLicenseKey;

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();

      if (line.startsWith('#EXTINF:')) {
        final parsed = _parseExtInf(line);
        currentName = parsed['name'];
        currentLogo = parsed['logo'];
        currentGroup = parsed['group'];
        currentTvgId = parsed['tvg-id'];
        currentTvgName = parsed['tvg-name'];
        // Reset per-entry state
        currentHeaders = {};
        currentLicenseType = null;
        currentLicenseKey = null;

      } else if (line.startsWith('#EXTVLCOPT:')) {
        // VLC-style options:
        //   #EXTVLCOPT:http-user-agent=Mozilla/5.0
        //   #EXTVLCOPT:http-referrer=https://example.com
        final opt = line.substring('#EXTVLCOPT:'.length).trim();
        _applyVlcOpt(opt, currentHeaders);

      } else if (line.startsWith('#KODIPROP:')) {
        // Kodi properties:
        //   #KODIPROP:inputstream.adaptive.license_type=clearkey
        //   #KODIPROP:inputstream.adaptive.license_key=kid:key
        final prop = line.substring('#KODIPROP:'.length).trim();
        final eqIdx = prop.indexOf('=');
        if (eqIdx != -1) {
          final key = prop.substring(0, eqIdx).trim();
          final val = prop.substring(eqIdx + 1).trim();
          if (key == 'inputstream.adaptive.license_type') {
            currentLicenseType = val;
          } else if (key == 'inputstream.adaptive.license_key') {
            currentLicenseKey = val;
          } else if (key == 'inputstream.adaptive.manifest_headers' ||
                     key == 'inputstream.adaptive.stream_headers') {
            // e.g. User-Agent=foo&Referer=bar
            _parseAmpersandHeaders(val, currentHeaders);
          }
        }

      } else if (line.isNotEmpty &&
                 !line.startsWith('#') &&
                 currentName != null) {
        // ── Stream URL line ─────────────────────────────────────────
        final parsed = parseStreamUrl(line);

        // Merge headers: KODIPROP/EXTVLCOPT headers win over pipe headers
        final mergedHeaders = <String, String>{
          ...parsed.headers,
          ...currentHeaders,
        };

        // Resolve DRM: prefer KODIPROP, fall back to pipe options
        final licenseType = currentLicenseType ?? parsed.licenseType;
        final rawLicenseKey = currentLicenseKey ?? parsed.rawLicenseKey;
        final clearKeys = parsed.clearKeys.isNotEmpty
            ? parsed.clearKeys
            : (rawLicenseKey != null && licenseType == 'clearkey'
                ? _parseClearKeys(rawLicenseKey)
                : <Map<String, String>>[]);

        final channel = Channel(
          id: _uuid.v4(),
          name: currentName,
          streamUrl: parsed.url,
          logoUrl: currentLogo,
          groupTitle: currentGroup ?? 'General',
          tvgId: currentTvgId,
          tvgName: currentTvgName,
          headers: mergedHeaders.isNotEmpty ? mergedHeaders : null,
          licenseType: licenseType,
          rawLicenseKey: rawLicenseKey,
          clearKeys: clearKeys.isNotEmpty ? clearKeys : null,
        );
        channels.add(channel);

        // Reset
        currentName = null;
        currentLogo = null;
        currentGroup = null;
        currentTvgId = null;
        currentTvgName = null;
        currentHeaders = {};
        currentLicenseType = null;
        currentLicenseKey = null;
      }
    }

    return channels;
  }

  // ──────────────────────────────────────────────────────────────────
  // Stream URL parser — handles the pipe | syntax
  //
  // Examples:
  //   https://cdn.example.com/stream.m3u8
  //   https://cdn.example.com/index.mpd|User-Agent=Mozilla&Referer=https://x.com/
  //   https://cdn.example.com/index.mpd|license_type=clearkey&license_key=kid:key&User-Agent=referrer=https://visionplus.id/
  // ──────────────────────────────────────────────────────────────────
  static ParsedStreamUrl parseStreamUrl(String rawUrl) {
    final pipeIdx = rawUrl.indexOf('|');
    if (pipeIdx == -1) {
      // No pipe — plain URL, nothing to parse
      return ParsedStreamUrl(url: rawUrl.trim());
    }

    final cleanUrl = rawUrl.substring(0, pipeIdx).trim();
    final optionsPart = rawUrl.substring(pipeIdx + 1).trim();

    final headers = <String, String>{};
    String? licenseType;
    String? rawLicenseKey;

    // Split on & but be careful — Referer/User-Agent values can contain &
    // We parse key=value pairs one by one from left to right.
    final params = _splitPipeOptions(optionsPart);

    for (final param in params) {
      final eqIdx = param.indexOf('=');
      if (eqIdx == -1) continue;

      final key = param.substring(0, eqIdx).trim();
      final value = param.substring(eqIdx + 1).trim();

      switch (key.toLowerCase()) {
        case 'license_type':
          licenseType = value;
          break;

        case 'license_key':
          rawLicenseKey = value;
          break;

        case 'user-agent':
          // Sometimes written as "User-Agent=referrer=https://..." — keep as-is
          headers['User-Agent'] = value;
          break;

        case 'referer':
        case 'referrer':
          headers['Referer'] = value;
          break;

        case 'origin':
          headers['Origin'] = value;
          break;

        default:
          // Treat any unknown key=value as a potential HTTP header
          if (_isHttpHeader(key)) {
            headers[key] = value;
          }
      }
    }

    final clearKeys = (licenseType == 'clearkey' && rawLicenseKey != null)
        ? _parseClearKeys(rawLicenseKey)
        : <Map<String, String>>[];

    return ParsedStreamUrl(
      url: cleanUrl,
      headers: headers,
      clearKeys: clearKeys,
      licenseType: licenseType,
      rawLicenseKey: rawLicenseKey,
    );
  }

  // ──────────────────────────────────────────────────────────────────
  // ClearKey parser
  //
  // Formats supported:
  //   kid:key                         (single)
  //   kid1:key1,kid2:key2             (multiple comma-separated)
  //   {"keys":[{"kty":"oct","k":"...","kid":"..."}]}   (JSON)
  // ──────────────────────────────────────────────────────────────────
  static List<Map<String, String>> _parseClearKeys(String raw) {
    final result = <Map<String, String>>[];

    // JSON format
    if (raw.trimLeft().startsWith('{')) {
      try {
        final json = jsonDecode(raw) as Map<String, dynamic>;
        final keys = json['keys'] as List?;
        if (keys != null) {
          for (final k in keys) {
            final kid = k['kid'] as String?;
            final key = k['k'] as String?;
            if (kid != null && key != null) {
              result.add({'kid': kid, 'key': key});
            }
          }
        }
      } catch (_) {
        // ignore JSON parse errors — fall through to hex format
      }
      return result;
    }

    // Hex format: kid:key or kid1:key1,kid2:key2
    for (final pair in raw.split(',')) {
      final parts = pair.trim().split(':');
      if (parts.length == 2) {
        result.add({'kid': parts[0].trim(), 'key': parts[1].trim()});
      }
    }
    return result;
  }

  // ──────────────────────────────────────────────────────────────────
  // Helpers
  // ──────────────────────────────────────────────────────────────────

  /// Split pipe option string on `&`, but preserve `&` inside URLs.
  /// Strategy: split only on `&` that are followed by a known key name.
  static List<String> _splitPipeOptions(String options) {
    // Known top-level keys in pipe syntax
    const knownKeys = [
      'license_type',
      'license_key',
      'user-agent',
      'User-Agent',
      'referer',
      'Referer',
      'referrer',
      'origin',
      'Origin',
    ];

    // Build a regex that matches & only before known keys
    final keyPattern = knownKeys
        .map((k) => RegExp.escape(k))
        .join('|');
    final splitter = RegExp('&(?=($keyPattern)=)', caseSensitive: false);

    return options.split(splitter);
  }

  static void _applyVlcOpt(String opt, Map<String, String> headers) {
    final eqIdx = opt.indexOf('=');
    if (eqIdx == -1) return;
    final key = opt.substring(0, eqIdx).trim().toLowerCase();
    final val = opt.substring(eqIdx + 1).trim();
    switch (key) {
      case 'http-user-agent':
        headers['User-Agent'] = val;
        break;
      case 'http-referrer':
      case 'http-referer':
        headers['Referer'] = val;
        break;
      case 'http-origin':
        headers['Origin'] = val;
        break;
    }
  }

  static void _parseAmpersandHeaders(String raw, Map<String, String> out) {
    for (final part in raw.split('&')) {
      final idx = part.indexOf('=');
      if (idx == -1) continue;
      out[part.substring(0, idx).trim()] = part.substring(idx + 1).trim();
    }
  }

  static bool _isHttpHeader(String key) {
    const httpHeaders = {
      'Accept', 'Accept-Encoding', 'Accept-Language', 'Authorization',
      'Cache-Control', 'Connection', 'Cookie', 'Host', 'Origin',
      'Pragma', 'Referer', 'User-Agent', 'X-Forwarded-For',
    };
    return httpHeaders.any((h) => h.toLowerCase() == key.toLowerCase());
  }

  static Map<String, String?> _parseExtInf(String line) {
    final result = <String, String?>{};

    final mainParts = line.split(',');
    if (mainParts.length >= 2) {
      result['name'] = mainParts.sublist(1).join(',').trim();
    }

    final attrs = [
      'tvg-id', 'tvg-name', 'tvg-logo', 'group-title',
      'tvg-country', 'tvg-language', 'tvg-chno',
    ];

    for (final attr in attrs) {
      final patterns = [
        RegExp('$attr="([^"]*)"', caseSensitive: false),
        RegExp("$attr='([^']*)'", caseSensitive: false),
      ];

      for (final pattern in patterns) {
        final match = pattern.firstMatch(line);
        if (match != null) {
          final value = match.group(1)?.trim();
          if (attr == 'tvg-logo') {
            result['logo'] = value;
          } else if (attr == 'group-title') {
            result['group'] = value?.isEmpty == true ? 'General' : value;
          } else {
            result[attr] = value;
          }
          break;
        }
      }
    }

    return result;
  }

  // ──────────────────────────────────────────────────────────────────
  // Category helpers
  // ──────────────────────────────────────────────────────────────────

  static List<String> extractCategories(List<Channel> channels) {
    final categories = <String>{};
    for (final channel in channels) {
      if (channel.groupTitle.isNotEmpty) categories.add(channel.groupTitle);
    }
    return categories.toList()..sort();
  }

  static Map<String, List<Channel>> groupByCategory(List<Channel> channels) {
    final grouped = <String, List<Channel>>{};
    for (final channel in channels) {
      grouped.putIfAbsent(channel.groupTitle, () => []).add(channel);
    }
    return grouped;
  }
}
