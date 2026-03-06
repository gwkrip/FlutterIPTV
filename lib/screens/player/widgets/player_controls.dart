import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/player_provider.dart';
import '../../../widgets/common/tv_focus_widget.dart';

class PlayerControls extends ConsumerStatefulWidget {
  final VoidCallback onClose;
  final VoidCallback onNextChannel;
  final VoidCallback onPrevChannel;

  const PlayerControls({
    super.key,
    required this.onClose,
    required this.onNextChannel,
    required this.onPrevChannel,
  });

  @override
  ConsumerState<PlayerControls> createState() => _PlayerControlsState();
}

class _PlayerControlsState extends ConsumerState<PlayerControls>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final playerState = ref.watch(playerProvider);
    final channel = playerState.currentChannel;
    final isLive = playerState.duration == Duration.zero;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withOpacity(0.3),
                Colors.black.withOpacity(0.85),
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Channel info row
                  _buildChannelInfo(channel?.name ?? '', channel?.groupTitle ?? '', isLive),
                  const SizedBox(height: 20),

                  // Progress bar (for VOD)
                  if (!isLive)
                    _buildProgressBar(playerState),
                  if (!isLive) const SizedBox(height: 16),

                  // Controls row
                  _buildMainControls(playerState, isLive),
                  const SizedBox(height: 12),

                  // Secondary controls
                  _buildSecondaryControls(playerState),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChannelInfo(String name, String group, bool isLive) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (isLive) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.error,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.circle, size: 8, color: Colors.white),
                          SizedBox(width: 4),
                          Text(
                            'LIVE',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: Text(
                      name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [Shadow(blurRadius: 8)],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (group.isNotEmpty)
                Text(
                  group,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.white70,
                  ),
                ),
            ],
          ),
        ),
        // Close button
        TVFocusWidget(
          onSelect: widget.onClose,
          borderRadius: BorderRadius.circular(50),
          child: InkWell(
            onTap: widget.onClose,
            borderRadius: BorderRadius.circular(50),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close_rounded,
                  color: Colors.white, size: 22),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBar(PlayerState playerState) {
    final duration = playerState.duration.inMilliseconds.toDouble();
    final position = playerState.position.inMilliseconds.toDouble();
    final progress = duration > 0 ? position / duration : 0.0;

    return Column(
      children: [
        Row(
          children: [
            Text(
              _formatDuration(playerState.position),
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const Spacer(),
            Text(
              _formatDuration(playerState.duration),
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 4,
            thumbColor: AppTheme.primary,
            activeTrackColor: AppTheme.primary,
            inactiveTrackColor: Colors.white30,
            overlayColor: AppTheme.primary.withOpacity(0.3),
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
          ),
          child: Slider(
            value: progress.clamp(0.0, 1.0),
            onChanged: (value) {
              final seekTo = Duration(
                  milliseconds: (value * duration).round());
              ref.read(playerProvider.notifier).seek(seekTo);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMainControls(PlayerState playerState, bool isLive) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Previous channel
        _ControlButton(
          icon: Icons.skip_previous_rounded,
          onTap: widget.onPrevChannel,
          size: 28,
        ),
        const SizedBox(width: 12),

        // Seek backward (for VOD)
        if (!isLive) ...[
          _ControlButton(
            icon: Icons.replay_10_rounded,
            onTap: () => ref
                .read(playerProvider.notifier)
                .seekRelative(-const Duration(seconds: 10)),
            size: 26,
          ),
          const SizedBox(width: 12),
        ],

        // Play/Pause
        _ControlButton(
          icon: playerState.isBuffering
              ? Icons.hourglass_empty_rounded
              : playerState.isPlaying
                  ? Icons.pause_circle_filled_rounded
                  : Icons.play_circle_filled_rounded,
          onTap: () => ref.read(playerProvider.notifier).togglePlay(),
          size: 52,
          isPrimary: true,
          autofocus: true,
        ),

        // Seek forward (for VOD)
        if (!isLive) ...[
          const SizedBox(width: 12),
          _ControlButton(
            icon: Icons.forward_10_rounded,
            onTap: () => ref
                .read(playerProvider.notifier)
                .seekRelative(const Duration(seconds: 10)),
            size: 26,
          ),
        ],

        const SizedBox(width: 12),
        // Next channel
        _ControlButton(
          icon: Icons.skip_next_rounded,
          onTap: widget.onNextChannel,
          size: 28,
        ),
      ],
    );
  }

  Widget _buildSecondaryControls(PlayerState playerState) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Volume
        Row(
          children: [
            _ControlButton(
              icon: playerState.isMuted
                  ? Icons.volume_off_rounded
                  : Icons.volume_up_rounded,
              onTap: () => ref.read(playerProvider.notifier).toggleMute(),
              size: 22,
              isSecondary: true,
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 120,
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 3,
                  thumbColor: Colors.white,
                  activeTrackColor: Colors.white,
                  inactiveTrackColor: Colors.white30,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                ),
                child: Slider(
                  value: playerState.isMuted ? 0 : playerState.volume,
                  onChanged: (v) =>
                      ref.read(playerProvider.notifier).setVolume(v),
                ),
              ),
            ),
          ],
        ),

        // Playback speed (VOD only)
        Row(
          children: [
            _ControlButton(
              icon: Icons.speed_rounded,
              onTap: () => _showSpeedDialog(context),
              size: 20,
              isSecondary: true,
              label: playerState.speed.label,
            ),
            const SizedBox(width: 16),
            _ControlButton(
              icon: Icons.fullscreen_rounded,
              onTap: () {},
              size: 20,
              isSecondary: true,
            ),
          ],
        ),
      ],
    );
  }

  void _showSpeedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceElevated,
        title: const Text('Playback Speed',
            style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: PlaybackSpeed.values
              .map((speed) => ListTile(
                    title: Text(speed.label,
                        style: const TextStyle(color: Colors.white)),
                    onTap: () {
                      ref.read(playerProvider.notifier).setSpeed(speed);
                      Navigator.pop(context);
                    },
                    selected:
                        ref.read(playerProvider).speed == speed,
                    selectedTileColor: AppTheme.primary.withOpacity(0.2),
                  ))
              .toList(),
        ),
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double size;
  final bool isPrimary;
  final bool isSecondary;
  final bool autofocus;
  final String? label;

  const _ControlButton({
    required this.icon,
    required this.onTap,
    required this.size,
    this.isPrimary = false,
    this.isSecondary = false,
    this.autofocus = false,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    if (isPrimary) {
      return TVFocusWidget(
        autofocus: autofocus,
        onSelect: onTap,
        borderRadius: BorderRadius.circular(50),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(50),
          child: Icon(icon, color: Colors.white, size: size),
        ),
      );
    }

    return TVFocusWidget(
      onSelect: onTap,
      borderRadius: BorderRadius.circular(50),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(50),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: label != null
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon,
                        color: Colors.white70, size: size),
                    const SizedBox(width: 4),
                    Text(label!,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12)),
                  ],
                )
              : Icon(icon, color: Colors.white70, size: size),
        ),
      ),
    );
  }
}
