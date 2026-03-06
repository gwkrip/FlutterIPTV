import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/playlist_provider.dart';
import 'widgets/sidebar.dart';
import 'widgets/channel_grid.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    final state = ref.read(playlistProvider);
    if (state.categories.isNotEmpty) {
      _selectedCategory = state.categories.first;
    }
  }

  void _onCategorySelected(String category) {
    setState(() => _selectedCategory = category);
    ref.read(playlistProvider.notifier).selectCategory(category);
  }

  String _getCategoryDisplayName(String? category) {
    if (category == '__favorites__') return '❤️ Favorites';
    if (category == '__recent__') return '🕐 Recently Watched';
    return category ?? 'All Channels';
  }

  @override
  Widget build(BuildContext context) {
    final playlistState = ref.watch(playlistProvider);
    final currentChannels = playlistState.currentCategoryChannels;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: FocusScope(
        child: Row(
          children: [
            // Sidebar
            TVSidebar(
              selectedCategory: _selectedCategory,
              onCategorySelected: _onCategorySelected,
              onSearchPressed: () => context.push('/search'),
              onSettingsPressed: () => context.push('/settings'),
            ),

            // Main content area
            Expanded(
              child: _buildContent(playlistState, currentChannels),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(PlaylistState state, List<dynamic> channels) {
    // Error state
    if (state.error != null && state.channels.isEmpty) {
      return _buildErrorState(state.error!);
    }

    // No playlists
    if (state.playlists.isEmpty && !state.isLoading) {
      return _buildNoPlaylistState();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top bar
        _buildTopBar(state),

        // Channel grid
        Expanded(
          child: ChannelGrid(
            channels: channels.cast(),
            onChannelSelected: (channel) {
              ref.read(playlistProvider.notifier).updateChannelWatched(channel.id);
              context.push('/player', extra: {
                'channelName': channel.name,
                'streamUrl': channel.streamUrl,
                'channelLogo': channel.logoUrl,
                'groupTitle': channel.groupTitle,
              });
            },
            isLoading: state.isLoading,
            categoryTitle: _getCategoryDisplayName(_selectedCategory),
          ),
        ),
      ],
    );
  }

  Widget _buildTopBar(PlaylistState state) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border(
          bottom: BorderSide(color: AppTheme.divider),
        ),
      ),
      child: Row(
        children: [
          // Playlist name
          if (state.activePlaylist != null)
            Expanded(
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppTheme.success,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    state.activePlaylist!.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.onBackground,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    '${state.channels.length} channels',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.onSurface,
                    ),
                  ),
                ],
              ),
            )
          else
            const Spacer(),

          // Actions
          Row(
            children: [
              if (state.isLoading)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppTheme.primary,
                  ),
                )
              else
                _buildTopBarButton(
                  icon: Icons.refresh_rounded,
                  tooltip: 'Refresh',
                  onTap: () =>
                      ref.read(playlistProvider.notifier).refreshPlaylist(),
                ),
              const SizedBox(width: 8),
              _buildTopBarButton(
                icon: Icons.search_rounded,
                tooltip: 'Search',
                onTap: () => context.push('/search'),
              ),
              const SizedBox(width: 8),
              _buildTopBarButton(
                icon: Icons.settings_rounded,
                tooltip: 'Settings',
                onTap: () => context.push('/settings'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTopBarButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppTheme.surfaceElevated,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: AppTheme.onSurface),
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.error.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.error_outline_rounded,
              size: 60,
              color: AppTheme.error,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Failed to load playlist',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: () =>
                    ref.read(playlistProvider.notifier).refreshPlaylist(),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () => context.push('/settings'),
                icon: const Icon(Icons.settings),
                label: const Text('Settings'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.onBackground,
                  side: const BorderSide(color: AppTheme.divider),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNoPlaylistState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated TV icon
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primary.withOpacity(0.2),
                  AppTheme.accentSecondary.withOpacity(0.2),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.tv_rounded,
              size: 60,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Welcome to Flutter IPTV',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Add your M3U playlist to start watching',
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.onSurface,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => context.push('/settings'),
            icon: const Icon(Icons.add_circle_outline),
            label: const Text('Add Playlist'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              textStyle: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
