import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/channel.dart';
import '../../../widgets/common/tv_focus_widget.dart';

class ChannelCard extends StatefulWidget {
  final Channel channel;
  final VoidCallback onSelect;
  final VoidCallback? onFavoriteToggle;
  final bool autofocus;
  final FocusNode? focusNode;

  const ChannelCard({
    super.key,
    required this.channel,
    required this.onSelect,
    this.onFavoriteToggle,
    this.autofocus = false,
    this.focusNode,
  });

  @override
  State<ChannelCard> createState() => _ChannelCardState();
}

class _ChannelCardState extends State<ChannelCard> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return TVFocusWidget(
      autofocus: widget.autofocus,
      focusNode: widget.focusNode,
      onSelect: widget.onSelect,
      onFocusGained: () => setState(() => _isFocused = true),
      onFocusLost: () => setState(() => _isFocused = false),
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 190,
        height: 140,
        decoration: BoxDecoration(
          color: _isFocused
              ? AppTheme.surfaceElevated
              : AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(14),
          gradient: _isFocused
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.primary.withOpacity(0.15),
                    AppTheme.surfaceElevated,
                  ],
                )
              : null,
        ),
        child: Stack(
          children: [
            // ── Main content ───────────────────────────────────
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: _buildLogo(),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                  child: Text(
                    widget.channel.name,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color:
                          _isFocused ? Colors.white : AppTheme.onBackground,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),

            // ── Top-left: DRM badge ────────────────────────────
            if (widget.channel.hasDrm)
              Positioned(
                top: 7,
                left: 7,
                child: _DrmBadge(
                    licenseType: widget.channel.licenseType!),
              ),

            // ── Top-right: Favorite heart ──────────────────────
            if (widget.channel.isFavorite)
              Positioned(
                top: 7,
                right: 7,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppTheme.accent.withOpacity(0.9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.favorite,
                      size: 11, color: Colors.white),
                ),
              ),

            // ── Focused: favorite toggle (top-left when no DRM) ─
            if (_isFocused &&
                !widget.channel.hasDrm &&
                widget.onFavoriteToggle != null)
              Positioned(
                top: 7,
                left: 7,
                child: GestureDetector(
                  onTap: widget.onFavoriteToggle,
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      widget.channel.isFavorite
                          ? Icons.favorite
                          : Icons.favorite_border,
                      size: 14,
                      color: widget.channel.isFavorite
                          ? AppTheme.accent
                          : Colors.white,
                    ),
                  ),
                ),
              ),

            // ── Focused: Play label ────────────────────────────
            if (_isFocused)
              Positioned(
                bottom: 34,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.play_arrow_rounded,
                          size: 11, color: Colors.white),
                      SizedBox(width: 2),
                      Text('Play',
                          style: TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),

            // ── Stream type badge (bottom-left) ────────────────
            Positioned(
              bottom: 34,
              left: 8,
              child: _StreamTypeBadge(url: widget.channel.streamUrl),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo() {
    if (widget.channel.logoUrl != null &&
        widget.channel.logoUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: widget.channel.logoUrl!,
        fit: BoxFit.contain,
        placeholder: (context, url) => _buildPlaceholder(),
        errorWidget: (context, url, error) => _buildPlaceholder(),
      );
    }
    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    final name = widget.channel.name;
    final initials = name.length >= 2
        ? name.substring(0, 2).toUpperCase()
        : name.toUpperCase();

    final colors = [
      AppTheme.primary,
      AppTheme.accent,
      AppTheme.accentSecondary,
      const Color(0xFF059669),
      const Color(0xFFD97706),
    ];
    final idx =
        name.codeUnits.fold(0, (a, b) => a + b) % colors.length;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors[idx], colors[idx].withOpacity(0.6)],
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Text(initials,
            style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────
// DRM badge (lock icon + type label)
// ────────────────────────────────────────────────────────────────────
class _DrmBadge extends StatelessWidget {
  final String licenseType;
  const _DrmBadge({required this.licenseType});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(5),
        border:
            Border.all(color: AppTheme.warning.withOpacity(0.6), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.lock_rounded,
              size: 9, color: AppTheme.warning),
          const SizedBox(width: 3),
          Text(
            licenseType.toUpperCase(),
            style: const TextStyle(
              fontSize: 8,
              color: AppTheme.warning,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────
// Stream type badge  (HLS / DASH / RTMP …)
// ────────────────────────────────────────────────────────────────────
class _StreamTypeBadge extends StatelessWidget {
  final String url;
  const _StreamTypeBadge({required this.url});

  String? _label() {
    final lower = url.toLowerCase();
    if (lower.contains('.mpd')) return 'DASH';
    if (lower.contains('.m3u8')) return 'HLS';
    if (lower.startsWith('rtmp')) return 'RTMP';
    if (lower.startsWith('rtsp')) return 'RTSP';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final label = _label();
    if (label == null) return const SizedBox.shrink();

    final isDash = label == 'DASH';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: (isDash ? AppTheme.accentSecondary : AppTheme.primary)
            .withOpacity(0.85),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 8,
          color: Colors.white,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────
// Compact list tile
// ────────────────────────────────────────────────────────────────────
class ChannelListTile extends StatefulWidget {
  final Channel channel;
  final VoidCallback onSelect;
  final VoidCallback? onFavoriteToggle;
  final bool autofocus;
  final bool isCurrentlyPlaying;

  const ChannelListTile({
    super.key,
    required this.channel,
    required this.onSelect,
    this.onFavoriteToggle,
    this.autofocus = false,
    this.isCurrentlyPlaying = false,
  });

  @override
  State<ChannelListTile> createState() => _ChannelListTileState();
}

class _ChannelListTileState extends State<ChannelListTile> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return TVFocusWidget(
      autofocus: widget.autofocus,
      onSelect: widget.onSelect,
      onFocusGained: () => setState(() => _isFocused = true),
      onFocusLost: () => setState(() => _isFocused = false),
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: _isFocused
              ? AppTheme.primary.withOpacity(0.15)
              : widget.isCurrentlyPlaying
                  ? AppTheme.surfaceElevated
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            if (widget.isCurrentlyPlaying)
              Container(
                width: 6,
                height: 6,
                margin: const EdgeInsets.only(right: 10),
                decoration: const BoxDecoration(
                    color: AppTheme.success, shape: BoxShape.circle),
              ),
            // Logo
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                width: 40,
                height: 30,
                child: widget.channel.logoUrl != null
                    ? CachedNetworkImage(
                        imageUrl: widget.channel.logoUrl!,
                        fit: BoxFit.contain,
                        errorWidget: (_, __, ___) =>
                            _buildMiniLogo(),
                      )
                    : _buildMiniLogo(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.channel.name,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: _isFocused
                      ? Colors.white
                      : AppTheme.onBackground,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // DRM icon in list
            if (widget.channel.hasDrm)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Icon(Icons.lock_rounded,
                    size: 13, color: AppTheme.warning.withOpacity(0.8)),
              ),
            if (widget.channel.isFavorite)
              const Icon(Icons.favorite,
                  size: 14, color: AppTheme.accent),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniLogo() {
    return Container(
      color: AppTheme.surfaceElevated,
      child: Center(
        child: Text(
          widget.channel.name.substring(0, 1),
          style: const TextStyle(
              color: AppTheme.primary,
              fontWeight: FontWeight.bold,
              fontSize: 12),
        ),
      ),
    );
  }
}
