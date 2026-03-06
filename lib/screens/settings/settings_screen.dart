import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../models/playlist.dart';
import '../../providers/playlist_provider.dart';
import '../../widgets/common/tv_focus_widget.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  int _selectedSection = 0;
  String _appVersion = '';

  final sections = ['Playlists', 'Player', 'About'];

  @override
  void initState() {
    super.initState();
    _loadAppInfo();
  }

  Future<void> _loadAppInfo() async {
    try {
      final info = await PackageInfo.fromPlatform();
      setState(() => _appVersion = info.version);
    } catch (_) {
      _appVersion = AppConstants.appVersion;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Row(
        children: [
          // Left panel - sections
          _buildSectionNav(),

          // Right panel - content
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildSectionNav() {
    return Container(
      width: 240,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: const Border(right: BorderSide(color: AppTheme.divider)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                TVFocusWidget(
                  onSelect: () => context.pop(),
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    onTap: () => context.pop(),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceElevated,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.arrow_back_rounded,
                          color: Colors.white, size: 20),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Settings',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          // Section list
          ...sections.asMap().entries.map((e) => _buildSectionItem(
                e.key,
                e.value,
                _getSectionIcon(e.key),
              )),
        ],
      ),
    );
  }

  IconData _getSectionIcon(int index) {
    switch (index) {
      case 0:
        return Icons.playlist_play_rounded;
      case 1:
        return Icons.play_circle_outline_rounded;
      case 2:
        return Icons.info_outline_rounded;
      default:
        return Icons.settings;
    }
  }

  Widget _buildSectionItem(int index, String title, IconData icon) {
    final isSelected = _selectedSection == index;
    return TVFocusWidget(
      onSelect: () => setState(() => _selectedSection = index),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: () => setState(() => _selectedSection = index),
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.primary.withOpacity(0.2)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: isSelected
                ? Border.all(color: AppTheme.primary.withOpacity(0.4))
                : null,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? AppTheme.primary : AppTheme.onSurface,
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? Colors.white : AppTheme.onBackground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    switch (_selectedSection) {
      case 0:
        return _PlaylistsSection();
      case 1:
        return _PlayerSection();
      case 2:
        return _AboutSection(version: _appVersion);
      default:
        return const SizedBox();
    }
  }
}

class _PlaylistsSection extends ConsumerStatefulWidget {
  @override
  ConsumerState<_PlaylistsSection> createState() => _PlaylistsSectionState();
}

class _PlaylistsSectionState extends ConsumerState<_PlaylistsSection> {
  @override
  Widget build(BuildContext context) {
    final playlistState = ref.watch(playlistProvider);
    final playlists = playlistState.playlists;

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'My Playlists',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              TVFocusWidget(
                onSelect: () => _showAddPlaylistDialog(context),
                borderRadius: BorderRadius.circular(10),
                child: ElevatedButton.icon(
                  onPressed: () => _showAddPlaylistDialog(context),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add Playlist'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Add M3U playlists to access your channels',
            style: TextStyle(color: AppTheme.onSurface, fontSize: 14),
          ),
          const SizedBox(height: 24),

          // Sample playlists
          if (playlists.isEmpty) ...[
            const Text(
              'Quick Start — Sample Playlists',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.onBackground,
              ),
            ),
            const SizedBox(height: 12),
            ...AppConstants.samplePlaylists
                .map((sample) => _buildSamplePlaylistCard(sample)),
            const SizedBox(height: 24),
          ],

          // User playlists
          if (playlists.isNotEmpty) ...[
            Expanded(
              child: ListView.separated(
                itemCount: playlists.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) =>
                    _PlaylistCard(playlist: playlists[index]),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSamplePlaylistCard(Map<String, String> sample) {
    return TVFocusWidget(
      onSelect: () => ref.read(playlistProvider.notifier).addPlaylist(
            name: sample['name']!,
            url: sample['url']!,
          ),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => ref.read(playlistProvider.notifier).addPlaylist(
              name: sample['name']!,
              url: sample['url']!,
            ),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.cardBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.divider),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.playlist_add_rounded,
                    color: AppTheme.primary, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sample['name']!,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      sample['url']!,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.onSurface,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Text(
                'Add',
                style: TextStyle(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showAddPlaylistDialog(BuildContext context) async {
    final nameController = TextEditingController();
    final urlController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceElevated,
        title: const Text('Add Playlist',
            style: TextStyle(color: Colors.white)),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Playlist Name',
                  hintText: 'My IPTV',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: urlController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'M3U URL',
                  hintText: 'http://example.com/playlist.m3u',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(color: AppTheme.onSurface)),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty &&
                  urlController.text.isNotEmpty) {
                ref.read(playlistProvider.notifier).addPlaylist(
                      name: nameController.text,
                      url: urlController.text,
                    );
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

class _PlaylistCard extends ConsumerWidget {
  final Playlist playlist;
  const _PlaylistCard({required this.playlist});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isActive = ref.watch(playlistProvider).activePlaylist?.id == playlist.id;

    return TVFocusWidget(
      onSelect: () =>
          ref.read(playlistProvider.notifier).loadPlaylist(playlist),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isActive
              ? AppTheme.primary.withOpacity(0.1)
              : AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? AppTheme.primary.withOpacity(0.4) : AppTheme.divider,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isActive
                    ? AppTheme.primary.withOpacity(0.2)
                    : AppTheme.surfaceElevated,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isActive ? Icons.check_circle_rounded : Icons.playlist_play_rounded,
                color: isActive ? AppTheme.primary : AppTheme.onSurface,
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        playlist.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          fontSize: 15,
                        ),
                      ),
                      if (isActive) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.success,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'ACTIVE',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Text(
                    playlist.url,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (playlist.channelCount > 0)
                    Text(
                      '${playlist.channelCount} channels',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.onSurface,
                      ),
                    ),
                ],
              ),
            ),

            // Actions
            Row(
              children: [
                if (!isActive)
                  IconButton(
                    icon: const Icon(Icons.play_arrow_rounded,
                        color: AppTheme.primary),
                    onPressed: () =>
                        ref.read(playlistProvider.notifier).loadPlaylist(playlist),
                    tooltip: 'Load',
                  ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded,
                      color: AppTheme.error),
                  onPressed: () => ref
                      .read(playlistProvider.notifier)
                      .deletePlaylist(playlist.id),
                  tooltip: 'Delete',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PlayerSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Player Settings',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          _buildSettingItem(
            icon: Icons.speed_rounded,
            title: 'Hardware Acceleration',
            subtitle: 'Use GPU for video decoding',
            trailing: Switch(
              value: true,
              onChanged: (_) {},
              activeColor: AppTheme.primary,
            ),
          ),
          _buildSettingItem(
            icon: Icons.hourglass_bottom_rounded,
            title: 'Buffer Size',
            subtitle: 'Pre-load video data (5 seconds)',
            trailing: const Text('5s',
                style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
          ),
          _buildSettingItem(
            icon: Icons.hd_rounded,
            title: 'Default Quality',
            subtitle: 'Auto (Best available)',
            trailing: const Icon(Icons.chevron_right, color: AppTheme.onSurface),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primary, size: 22),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w600)),
                Text(subtitle,
                    style: const TextStyle(
                        color: AppTheme.onSurface, fontSize: 12)),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}

class _AboutSection extends StatelessWidget {
  final String version;
  const _AboutSection({required this.version});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'About',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 32),
          Center(
            child: Column(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.primary, AppTheme.accentSecondary],
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(Icons.live_tv_rounded,
                      size: 50, color: Colors.white),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Flutter IPTV',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Version $version',
                  style: const TextStyle(color: AppTheme.onSurface),
                ),
                const SizedBox(height: 32),
                const Text(
                  'A feature-rich IPTV player built with Flutter,\noptimized for Android TV.',
                  style: TextStyle(
                    color: AppTheme.onSurface,
                    fontSize: 14,
                    height: 1.6,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    _buildTag('Flutter'),
                    _buildTag('Riverpod'),
                    _buildTag('media_kit'),
                    _buildTag('Hive'),
                    _buildTag('Android TV'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.primary.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppTheme.primary,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
