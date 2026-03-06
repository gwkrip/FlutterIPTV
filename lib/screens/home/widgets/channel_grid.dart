import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/channel.dart';
import '../../../providers/playlist_provider.dart';
import 'channel_card.dart';

class ChannelGrid extends ConsumerStatefulWidget {
  final List<Channel> channels;
  final Function(Channel) onChannelSelected;
  final bool isLoading;
  final String categoryTitle;

  const ChannelGrid({
    super.key,
    required this.channels,
    required this.onChannelSelected,
    this.isLoading = false,
    required this.categoryTitle,
  });

  @override
  ConsumerState<ChannelGrid> createState() => _ChannelGridState();
}

class _ChannelGridState extends ConsumerState<ChannelGrid> {
  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return _buildShimmer();
    }

    if (widget.channels.isEmpty) {
      return _buildEmpty();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.categoryTitle,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '${widget.channels.length} channels',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              // View toggle (grid/list)
              _ViewToggle(),
            ],
          ),
        ),

        // Channels
        Expanded(
          child: _buildGrid(),
        ),
      ],
    );
  }

  Widget _buildGrid() {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _getCrossAxisCount(context),
        childAspectRatio: 190 / 140,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: widget.channels.length,
      itemBuilder: (context, index) {
        final channel = widget.channels[index];
        return ChannelCard(
          key: ValueKey(channel.id),
          channel: channel,
          autofocus: index == 0,
          onSelect: () => widget.onChannelSelected(channel),
          onFavoriteToggle: () {
            ref.read(playlistProvider.notifier).toggleFavorite(channel);
          },
        );
      },
    );
  }

  int _getCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 1920) return 10;
    if (width > 1280) return 7;
    if (width > 960) return 5;
    return 4;
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: AppTheme.shimmerBase,
      highlightColor: AppTheme.shimmerHighlight,
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: _getCrossAxisCount(context),
          childAspectRatio: 190 / 140,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: 20,
        itemBuilder: (context, index) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.tv_off_rounded,
            size: 80,
            color: AppTheme.onSurface,
          ),
          SizedBox(height: 16),
          Text(
            'No channels found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.onBackground,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Add a playlist in Settings to get started',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _ViewToggle extends StatefulWidget {
  @override
  State<_ViewToggle> createState() => _ViewToggleState();
}

class _ViewToggleState extends State<_ViewToggle> {
  bool _isGrid = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: () => setState(() => _isGrid = true),
            icon: Icon(
              Icons.grid_view_rounded,
              color: _isGrid ? AppTheme.primary : AppTheme.onSurface,
              size: 20,
            ),
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            padding: const EdgeInsets.all(8),
          ),
          IconButton(
            onPressed: () => setState(() => _isGrid = false),
            icon: Icon(
              Icons.view_list_rounded,
              color: !_isGrid ? AppTheme.primary : AppTheme.onSurface,
              size: 20,
            ),
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            padding: const EdgeInsets.all(8),
          ),
        ],
      ),
    );
  }
}
