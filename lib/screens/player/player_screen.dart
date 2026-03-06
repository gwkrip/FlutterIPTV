import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/player_provider.dart';
import '../../providers/playlist_provider.dart';
import '../../models/channel.dart';
import 'widgets/player_controls.dart';

class PlayerScreen extends ConsumerStatefulWidget {
  final String channelName;
  final String streamUrl;
  final String? channelLogo;
  final String? groupTitle;

  const PlayerScreen({
    super.key,
    required this.channelName,
    required this.streamUrl,
    this.channelLogo,
    this.groupTitle,
  });

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen> {
  late VideoController _videoController;
  bool _showControls = true;
  Timer? _hideTimer;
  int _currentChannelIndex = -1;
  List<Channel> _siblingChannels = [];

  @override
  void initState() {
    super.initState();
    _videoController = VideoController(
      ref.read(playerProvider.notifier).player,
      configuration: const VideoControllerConfiguration(
        enableHardwareAcceleration: true,
      ),
    );
    _initPlayer();
    _startHideTimer();
  }

  Future<void> _initPlayer() async {
    final state = ref.read(playlistProvider);

    // Find sibling channels in same group for up/down navigation
    _siblingChannels = state.channels
        .where((c) => c.groupTitle == widget.groupTitle)
        .toList();
    _currentChannelIndex = _siblingChannels
        .indexWhere((c) => c.streamUrl == widget.streamUrl);

    // Find full channel object (with DRM info) from playlist
    final fullChannel = state.channels.firstWhere(
      (c) => c.streamUrl == widget.streamUrl,
      orElse: () => Channel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: widget.channelName,
        streamUrl: widget.streamUrl,
        logoUrl: widget.channelLogo,
        groupTitle: widget.groupTitle ?? '',
      ),
    );

    await ref.read(playerProvider.notifier).playChannel(fullChannel);
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(AppConstants.controlsHideDelay, () {
      if (mounted) setState(() => _showControls = false);
    });
  }

  void _onUserInteraction() {
    setState(() => _showControls = true);
    _startHideTimer();
  }

  void _playNextChannel() {
    if (_siblingChannels.isEmpty) return;
    _currentChannelIndex =
        (_currentChannelIndex + 1) % _siblingChannels.length;
    _playChannelAt(_currentChannelIndex);
  }

  void _playPrevChannel() {
    if (_siblingChannels.isEmpty) return;
    _currentChannelIndex =
        (_currentChannelIndex - 1 + _siblingChannels.length) %
            _siblingChannels.length;
    _playChannelAt(_currentChannelIndex);
  }

  void _playChannelAt(int index) {
    final channel = _siblingChannels[index];
    ref.read(playerProvider.notifier).playChannel(channel);
    ref.read(playlistProvider.notifier).updateChannelWatched(channel.id);
    setState(() {});
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    ref.read(playerProvider.notifier).stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final playerState = ref.watch(playerProvider);
    final channel = playerState.currentChannel;

    return Scaffold(
      backgroundColor: Colors.black,
      body: KeyboardListener(
        focusNode: FocusNode()..requestFocus(),
        onKeyEvent: (event) {
          if (event is KeyDownEvent) {
            _onUserInteraction();
            switch (event.logicalKey) {
              case LogicalKeyboardKey.select:
              case LogicalKeyboardKey.mediaPlayPause:
                ref.read(playerProvider.notifier).togglePlay();
                break;
              case LogicalKeyboardKey.arrowUp:
                _playPrevChannel();
                break;
              case LogicalKeyboardKey.arrowDown:
                _playNextChannel();
                break;
              case LogicalKeyboardKey.arrowLeft:
                ref.read(playerProvider.notifier)
                    .seekRelative(-AppConstants.seekDuration);
                break;
              case LogicalKeyboardKey.arrowRight:
                ref.read(playerProvider.notifier)
                    .seekRelative(AppConstants.seekDuration);
                break;
              case LogicalKeyboardKey.escape:
              case LogicalKeyboardKey.goBack:
                context.pop();
                break;
              case LogicalKeyboardKey.mediaFastForward:
                ref.read(playerProvider.notifier)
                    .seekRelative(AppConstants.skipDuration);
                break;
              case LogicalKeyboardKey.mediaRewind:
                ref.read(playerProvider.notifier)
                    .seekRelative(-AppConstants.skipDuration);
                break;
            }
          }
        },
        child: GestureDetector(
          onTap: _onUserInteraction,
          child: Stack(
            children: [
              // ── Video ─────────────────────────────────────────
              Positioned.fill(
                child: Video(
                  controller: _videoController,
                  controls: NoVideoControls,
                  fill: Colors.black,
                ),
              ),

              // ── Buffering spinner ──────────────────────────────
              if (playerState.isBuffering && !playerState.hasError)
                const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                          color: AppTheme.primary, strokeWidth: 3),
                      SizedBox(height: 16),
                      Text('Buffering...',
                          style: TextStyle(
                              color: Colors.white70, fontSize: 14)),
                    ],
                  ),
                ),

              // ── Error overlay ──────────────────────────────────
              if (playerState.hasError)
                _ErrorOverlay(
                  message: playerState.errorMessage,
                  channel: channel,
                  onRetry: () =>
                      ref.read(playerProvider.notifier).retry(),
                  onBack: () => context.pop(),
                ),

              // ── Controls overlay ───────────────────────────────
              if (_showControls && !playerState.hasError)
                Positioned.fill(
                  child: PlayerControls(
                    onClose: () => context.pop(),
                    onNextChannel: _playNextChannel,
                    onPrevChannel: _playPrevChannel,
                  ),
                ),

              // ── Mini channel info (controls hidden) ───────────
              if (!_showControls && !playerState.hasError && channel != null)
                Positioned(
                  top: 20,
                  left: 20,
                  child: _MiniChannelInfo(channel: channel),
                ),

              // ── DRM badge (top-right corner) ───────────────────
              if (!_showControls && channel != null && channel.hasDrm)
                Positioned(
                  top: 20,
                  right: 20,
                  child: _DrmBadge(licenseType: channel.licenseType!),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────
// Sub-widgets
// ────────────────────────────────────────────────────────────────────

class _ErrorOverlay extends StatelessWidget {
  final String? message;
  final Channel? channel;
  final VoidCallback onRetry;
  final VoidCallback onBack;

  const _ErrorOverlay({
    required this.message,
    required this.channel,
    required this.onRetry,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final isDrmError = message != null &&
        (message!.contains('DRM') ||
            message!.contains('decryption') ||
            message!.contains('license'));

    return Container(
      color: Colors.black.withOpacity(0.88),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isDrmError
                    ? Icons.lock_outline_rounded
                    : Icons.signal_wifi_bad_rounded,
                size: 72,
                color: isDrmError ? AppTheme.warning : AppTheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                isDrmError ? 'DRM Error' : 'Playback Error',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message ?? 'Cannot play this stream.',
                style: const TextStyle(
                    color: Colors.white70, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              // Extra hint for DRM issues
              if (isDrmError && channel != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppTheme.warning.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        '🔑 ClearKey Info',
                        style: TextStyle(
                            color: AppTheme.warning,
                            fontWeight: FontWeight.bold,
                            fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        channel!.rawLicenseKey ?? '—',
                        style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 11,
                            fontFamily: 'monospace'),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Retry'),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: onBack,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white30),
                    ),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniChannelInfo extends StatelessWidget {
  final Channel channel;
  const _MiniChannelInfo({required this.channel});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // LIVE dot
          Container(
            width: 8, height: 8,
            decoration: const BoxDecoration(
                color: AppTheme.error, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          const Text('LIVE  ',
              style: TextStyle(
                  color: AppTheme.error,
                  fontWeight: FontWeight.bold,
                  fontSize: 12)),
          Text(channel.name,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600)),
          // DRM indicator next to name
          if (channel.hasDrm) ...[
            const SizedBox(width: 8),
            const Icon(Icons.lock_rounded, size: 12, color: AppTheme.warning),
          ],
        ],
      ),
    );
  }
}

class _DrmBadge extends StatelessWidget {
  final String licenseType;
  const _DrmBadge({required this.licenseType});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.warning.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.lock_rounded,
              size: 12, color: AppTheme.warning),
          const SizedBox(width: 4),
          Text(
            licenseType.toUpperCase(),
            style: const TextStyle(
              color: AppTheme.warning,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
