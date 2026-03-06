import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import '../models/channel.dart';

class PlayerState {
  final Channel? currentChannel;
  final bool isPlaying;
  final bool isBuffering;
  final bool hasError;
  final String? errorMessage;
  final Duration position;
  final Duration duration;
  final bool showControls;
  final double volume;
  final bool isMuted;
  final PlaybackSpeed speed;
  final bool isFullscreen;
  final StreamType streamType;

  const PlayerState({
    this.currentChannel,
    this.isPlaying = false,
    this.isBuffering = false,
    this.hasError = false,
    this.errorMessage,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.showControls = true,
    this.volume = 1.0,
    this.isMuted = false,
    this.speed = PlaybackSpeed.x1,
    this.isFullscreen = true,
    this.streamType = StreamType.unknown,
  });

  bool get isLive => duration == Duration.zero;

  PlayerState copyWith({
    Channel? currentChannel,
    bool? isPlaying,
    bool? isBuffering,
    bool? hasError,
    String? errorMessage,
    Duration? position,
    Duration? duration,
    bool? showControls,
    double? volume,
    bool? isMuted,
    PlaybackSpeed? speed,
    bool? isFullscreen,
    StreamType? streamType,
    bool clearChannel = false,
    bool clearError = false,
  }) {
    return PlayerState(
      currentChannel:
          clearChannel ? null : (currentChannel ?? this.currentChannel),
      isPlaying: isPlaying ?? this.isPlaying,
      isBuffering: isBuffering ?? this.isBuffering,
      hasError: clearError ? false : (hasError ?? this.hasError),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      position: position ?? this.position,
      duration: duration ?? this.duration,
      showControls: showControls ?? this.showControls,
      volume: volume ?? this.volume,
      isMuted: isMuted ?? this.isMuted,
      speed: speed ?? this.speed,
      isFullscreen: isFullscreen ?? this.isFullscreen,
      streamType: streamType ?? this.streamType,
    );
  }
}

enum StreamType {
  unknown,
  hls,    // .m3u8
  dash,   // .mpd
  rtmp,
  rtsp,
  mp4,
}

enum PlaybackSpeed {
  x025(0.25, '0.25x'),
  x05(0.5, '0.5x'),
  x075(0.75, '0.75x'),
  x1(1.0, '1x'),
  x125(1.25, '1.25x'),
  x15(1.5, '1.5x'),
  x2(2.0, '2x');

  final double value;
  final String label;
  const PlaybackSpeed(this.value, this.label);
}

class PlayerNotifier extends StateNotifier<PlayerState> {
  late final Player _player;

  PlayerNotifier() : super(const PlayerState()) {
    _player = Player(
      configuration: const PlayerConfiguration(
        bufferSize: 32 * 1024 * 1024, // 32 MB buffer
        logLevel: MPVLogLevel.warn,
      ),
    );
    _setupListeners();
  }

  Player get player => _player;

  void _setupListeners() {
    _player.stream.playing.listen((playing) {
      state = state.copyWith(isPlaying: playing);
    });

    _player.stream.buffering.listen((buffering) {
      state = state.copyWith(isBuffering: buffering);
    });

    _player.stream.position.listen((pos) {
      state = state.copyWith(position: pos);
    });

    _player.stream.duration.listen((dur) {
      state = state.copyWith(duration: dur);
    });

    _player.stream.volume.listen((vol) {
      state = state.copyWith(volume: vol / 100.0);
    });

    _player.stream.error.listen((error) {
      if (error.isNotEmpty) {
        state = state.copyWith(
          hasError: true,
          errorMessage: _friendlyError(error),
          isBuffering: false,
        );
      }
    });
  }

  /// Detects stream type from URL
  StreamType _detectStreamType(String url) {
    final lower = url.toLowerCase();
    if (lower.contains('.m3u8') || lower.contains('hls')) return StreamType.hls;
    if (lower.contains('.mpd') || lower.contains('dash')) return StreamType.dash;
    if (lower.startsWith('rtmp')) return StreamType.rtmp;
    if (lower.startsWith('rtsp')) return StreamType.rtsp;
    if (lower.contains('.mp4')) return StreamType.mp4;
    return StreamType.unknown;
  }

  /// Build MPV options for ClearKey DRM.
  ///
  /// media_kit (libmpv) supports ClearKey via the `decryption-keys` option.
  /// Format: "kid1=key1:kid2=key2" (colon-separated pairs).
  Map<String, String> _buildClearKeyOptions(Channel channel) {
    final opts = <String, String>{};

    if (!channel.hasClearKey) return opts;

    // Build decryption-keys string: "kid1=key1:kid2=key2"
    final keyPairs = channel.clearKeys!
        .map((pair) => '${pair['kid']}=${pair['key']}')
        .join(':');

    opts['decryption-keys'] = keyPairs;

    // Tell MPV this is a DASH stream with adaptive streaming input
    opts['demuxer-lavf-o'] = 'allowed_extensions=mpd';

    return opts;
  }

  Future<void> playChannel(Channel channel) async {
    final streamType = _detectStreamType(channel.streamUrl);

    state = state.copyWith(
      currentChannel: channel,
      isBuffering: true,
      streamType: streamType,
      clearError: true,
    );

    try {
      // Merge HTTP headers: channel headers take priority
      final httpHeaders = <String, String>{
        if (channel.headers != null) ...channel.headers!,
      };

      // Build MPV-specific options
      final mpvOptions = <String, String>{};

      // ── ClearKey DRM ─────────────────────────────────────────
      if (channel.hasClearKey) {
        mpvOptions.addAll(_buildClearKeyOptions(channel));
      }

      // ── Custom User-Agent / Referer via http-header-fields ───
      if (httpHeaders.isNotEmpty) {
        // MPV accepts multiple headers as "Key: Value\r\nKey2: Value2"
        final headerString = httpHeaders.entries
            .map((e) => '${e.key}: ${e.value}')
            .join('\r\n');
        mpvOptions['http-header-fields'] = headerString;
      }

      final media = Media(
        channel.streamUrl,
        httpHeaders: httpHeaders,
        extras: mpvOptions.isNotEmpty ? mpvOptions : null,
      );

      await _player.open(media);
      await _player.play();
    } catch (e) {
      state = state.copyWith(
        hasError: true,
        errorMessage: _friendlyError(e.toString()),
        isBuffering: false,
      );
    }
  }

  String _friendlyError(String raw) {
    if (raw.contains('403') || raw.contains('Forbidden')) {
      return 'Access denied (403). The stream may require authentication.';
    }
    if (raw.contains('404') || raw.contains('Not Found')) {
      return 'Stream not found (404). The URL may have changed.';
    }
    if (raw.contains('timeout') || raw.contains('timed out')) {
      return 'Connection timed out. Check your internet connection.';
    }
    if (raw.contains('decryption') || raw.contains('DRM') || raw.contains('key')) {
      return 'DRM decryption failed. The license key may be invalid or expired.';
    }
    if (raw.contains('unsupported') || raw.contains('codec')) {
      return 'Unsupported stream format or codec.';
    }
    return 'Playback error. The stream may be offline or unsupported.';
  }

  Future<void> togglePlay() async => await _player.playOrPause();

  Future<void> stop() async {
    await _player.stop();
    state = state.copyWith(
      isPlaying: false,
      isBuffering: false,
      clearChannel: true,
    );
  }

  Future<void> seek(Duration position) async => await _player.seek(position);

  Future<void> seekRelative(Duration offset) async {
    await seek(state.position + offset);
  }

  Future<void> setVolume(double volume) async {
    await _player.setVolume(volume * 100);
  }

  Future<void> toggleMute() async {
    final newMuted = !state.isMuted;
    state = state.copyWith(isMuted: newMuted);
    await _player.setVolume(newMuted ? 0 : state.volume * 100);
  }

  Future<void> setSpeed(PlaybackSpeed speed) async {
    await _player.setRate(speed.value);
    state = state.copyWith(speed: speed);
  }

  void showControls() => state = state.copyWith(showControls: true);
  void hideControls() => state = state.copyWith(showControls: false);
  void toggleControls() =>
      state = state.copyWith(showControls: !state.showControls);

  Future<void> retry() async {
    if (state.currentChannel != null) {
      await playChannel(state.currentChannel!);
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}

final playerProvider =
    StateNotifierProvider<PlayerNotifier, PlayerState>((ref) {
  return PlayerNotifier();
});
