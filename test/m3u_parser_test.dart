import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_iptv/services/m3u_parser.dart';

void main() {
  // ────────────────────────────────────────────────────────────────
  // Stream URL parser tests
  // ────────────────────────────────────────────────────────────────
  group('parseStreamUrl()', () {
    test('plain HLS URL — no pipe', () {
      const url =
          'https://ott-balancer.tvri.go.id/live/eds/SportHD/hls/SportHD.m3u8';
      final result = M3UParser.parseStreamUrl(url);
      expect(result.url, equals(url));
      expect(result.headers, isEmpty);
      expect(result.hasDrm, isFalse);
    });

    test('MPD with ClearKey DRM and User-Agent (VisionPlus style)', () {
      const raw =
          'https://d2xz2v5wuvgur6.cloudfront.net/out/v1/d6b026ad50f14b7f9af5ddd5450007d4/index.mpd'
          '|license_type=clearkey'
          '&license_key=c3004565365a42d08e3bde39a516d64e:dbfdc0967cfbbed01dba730c99d9c14a'
          '&User-Agent=referrer=https://www.visionplus.id/';

      final result = M3UParser.parseStreamUrl(raw);

      expect(result.url,
          'https://d2xz2v5wuvgur6.cloudfront.net/out/v1/d6b026ad50f14b7f9af5ddd5450007d4/index.mpd');
      expect(result.licenseType, 'clearkey');
      expect(result.rawLicenseKey,
          'c3004565365a42d08e3bde39a516d64e:dbfdc0967cfbbed01dba730c99d9c14a');
      expect(result.headers['User-Agent'],
          'referrer=https://www.visionplus.id/');
      expect(result.hasClearKey, isTrue);
      expect(result.clearKeys.length, 1);
      expect(result.clearKeys.first['kid'],
          'c3004565365a42d08e3bde39a516d64e');
      expect(result.clearKeys.first['key'],
          'dbfdc0967cfbbed01dba730c99d9c14a');
    });

    test('MPD with multiple ClearKey pairs', () {
      const raw =
          'https://cdn.example.com/stream.mpd'
          '|license_type=clearkey'
          '&license_key=aaa111:bbb222,ccc333:ddd444';

      final result = M3UParser.parseStreamUrl(raw);
      expect(result.clearKeys.length, 2);
      expect(result.clearKeys[0], {'kid': 'aaa111', 'key': 'bbb222'});
      expect(result.clearKeys[1], {'kid': 'ccc333', 'key': 'ddd444'});
    });

    test('URL with Referer header only', () {
      const raw =
          'https://live.example.com/stream.m3u8|Referer=https://example.com/';
      final result = M3UParser.parseStreamUrl(raw);
      expect(result.url, 'https://live.example.com/stream.m3u8');
      expect(result.headers['Referer'], 'https://example.com/');
      expect(result.hasDrm, isFalse);
    });
  });

  // ────────────────────────────────────────────────────────────────
  // Full M3U content parsing
  // ────────────────────────────────────────────────────────────────
  group('parseContent()', () {
    const sampleM3U = '''
#EXTM3U
#EXTINF:-1 tvg-logo="https://encrypted-tbn0.gstatic.com/images?q=tbn:ADITYA" group-title="INDONESIA", ADITYA
https://ott-balancer.tvri.go.id/live/eds/SportHD/hls/SportHD-avc1_900000=10002-mp4a_96000=20002.m3u8
#EXTINF:-1 tvg-logo="https://upload.wikimedia.org/wikipedia/commons/0/06/MNCTV.png" group-title="INDONESIA",MNC TV
https://d2xz2v5wuvgur6.cloudfront.net/out/v1/d6b026ad/index.mpd|license_type=clearkey&license_key=c3004565365a42d08e3bde39a516d64e:dbfdc0967cfbbed01dba730c99d9c14a&User-Agent=referrer=https://www.visionplus.id/
#EXTINF:-1 tvg-logo="https://upload.wikimedia.org/rcti.png" group-title="INDONESIA",RCTI (1) V+
https://d2xz2v5wuvgur6.cloudfront.net/out/v1/997ce876/index.mpd|license_type=clearkey&license_key=d386001215594043a8995db796ad9e9c:3404792cb4c804902acdc6ca65c1a298&User-Agent=referrer=https://www.visionplus.id/
''';

    test('parses all 3 channels', () {
      final channels = M3UParser.parseContent(sampleM3U);
      expect(channels.length, 3);
    });

    test('ADITYA — plain HLS, no DRM', () {
      final channels = M3UParser.parseContent(sampleM3U);
      final ch = channels[0];
      expect(ch.name, 'ADITYA');
      expect(ch.groupTitle, 'INDONESIA');
      expect(ch.streamUrl,
          'https://ott-balancer.tvri.go.id/live/eds/SportHD/hls/SportHD-avc1_900000=10002-mp4a_96000=20002.m3u8');
      expect(ch.hasDrm, isFalse);
      expect(ch.headers, isNull);
    });

    test('MNC TV — MPD with ClearKey DRM', () {
      final channels = M3UParser.parseContent(sampleM3U);
      final ch = channels[1];
      expect(ch.name, 'MNC TV');
      expect(ch.streamUrl,
          'https://d2xz2v5wuvgur6.cloudfront.net/out/v1/d6b026ad/index.mpd');
      expect(ch.hasDrm, isTrue);
      expect(ch.hasClearKey, isTrue);
      expect(ch.licenseType, 'clearkey');
      expect(ch.clearKeys!.length, 1);
      expect(ch.clearKeys!.first['kid'], 'c3004565365a42d08e3bde39a516d64e');
      expect(ch.clearKeys!.first['key'], 'dbfdc0967cfbbed01dba730c99d9c14a');
      expect(ch.headers!['User-Agent'],
          'referrer=https://www.visionplus.id/');
    });

    test('RCTI — MPD with different ClearKey', () {
      final channels = M3UParser.parseContent(sampleM3U);
      final ch = channels[2];
      expect(ch.name, 'RCTI (1) V+');
      expect(ch.hasClearKey, isTrue);
      expect(ch.clearKeys!.first['kid'], 'd386001215594043a8995db796ad9e9c');
      expect(ch.clearKeys!.first['key'], '3404792cb4c804902acdc6ca65c1a298');
    });

    test('categories extracted correctly', () {
      final channels = M3UParser.parseContent(sampleM3U);
      final cats = M3UParser.extractCategories(channels);
      expect(cats, contains('INDONESIA'));
    });
  });

  // ────────────────────────────────────────────────────────────────
  // KODIPROP / EXTVLCOPT directives
  // ────────────────────────────────────────────────────────────────
  group('KODIPROP & EXTVLCOPT', () {
    const m3uWithKodiprop = '''
#EXTM3U
#EXTINF:-1 group-title="Test",Test Channel
#KODIPROP:inputstream.adaptive.license_type=clearkey
#KODIPROP:inputstream.adaptive.license_key=abc123:def456
https://cdn.example.com/stream.mpd
''';

    test('parses KODIPROP DRM correctly', () {
      final channels = M3UParser.parseContent(m3uWithKodiprop);
      expect(channels.length, 1);
      final ch = channels.first;
      expect(ch.hasClearKey, isTrue);
      expect(ch.clearKeys!.first['kid'], 'abc123');
      expect(ch.clearKeys!.first['key'], 'def456');
    });

    const m3uWithVlcopt = '''
#EXTM3U
#EXTINF:-1 group-title="Test",VLC Test
#EXTVLCOPT:http-user-agent=CustomAgent/1.0
#EXTVLCOPT:http-referrer=https://example.com/
https://cdn.example.com/live.m3u8
''';

    test('parses EXTVLCOPT headers correctly', () {
      final channels = M3UParser.parseContent(m3uWithVlcopt);
      expect(channels.length, 1);
      final ch = channels.first;
      expect(ch.headers!['User-Agent'], 'CustomAgent/1.0');
      expect(ch.headers!['Referer'], 'https://example.com/');
    });
  });
}
