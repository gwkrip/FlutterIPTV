import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../providers/playlist_provider.dart';
import '../../../widgets/common/tv_focus_widget.dart';

class TVSidebar extends ConsumerStatefulWidget {
  final String? selectedCategory;
  final Function(String) onCategorySelected;
  final VoidCallback onSearchPressed;
  final VoidCallback onSettingsPressed;

  const TVSidebar({
    super.key,
    this.selectedCategory,
    required this.onCategorySelected,
    required this.onSearchPressed,
    required this.onSettingsPressed,
  });

  @override
  ConsumerState<TVSidebar> createState() => _TVSidebarState();
}

class _TVSidebarState extends ConsumerState<TVSidebar>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _widthAnimation;
  bool _isExpanded = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _widthAnimation = Tween<double>(begin: 72, end: 220).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _toggleExpand() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animController.forward();
      } else {
        _animController.reverse();
      }
    });
  }

  String _getCategoryIcon(String category) {
    final lower = category.toLowerCase();
    for (final entry in AppConstants.categoryIcons.entries) {
      if (lower.contains(entry.key)) {
        return entry.value;
      }
    }
    return '📺';
  }

  @override
  Widget build(BuildContext context) {
    final playlistState = ref.watch(playlistProvider);
    final categories = playlistState.categories;
    final favorites =
        playlistState.channels.where((c) => c.isFavorite).toList();

    return AnimatedBuilder(
      animation: _widthAnimation,
      builder: (context, child) {
        return Container(
          width: _widthAnimation.value,
          decoration: BoxDecoration(
            color: AppTheme.surface,
            border: Border(
              right: BorderSide(color: AppTheme.divider, width: 1),
            ),
          ),
          child: Column(
            children: [
              // App logo / toggle button
              _buildHeader(),

              // Navigation items
              Expanded(
                child: ListView(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: [
                    // Special categories
                    _buildSidebarItem(
                      icon: Icons.home_rounded,
                      label: 'All Channels',
                      category: categories.isNotEmpty ? categories.first : '',
                      isSelected: widget.selectedCategory == categories.firstOrNull,
                      onTap: () {
                        if (categories.isNotEmpty) {
                          widget.onCategorySelected(categories.first);
                        }
                      },
                    ),
                    if (favorites.isNotEmpty)
                      _buildSidebarItem(
                        icon: Icons.favorite_rounded,
                        label: 'Favorites',
                        category: '__favorites__',
                        isSelected: widget.selectedCategory == '__favorites__',
                        onTap: () => widget.onCategorySelected('__favorites__'),
                        badgeCount: favorites.length,
                      ),
                    _buildSidebarItem(
                      icon: Icons.history_rounded,
                      label: 'Recent',
                      category: '__recent__',
                      isSelected: widget.selectedCategory == '__recent__',
                      onTap: () => widget.onCategorySelected('__recent__'),
                    ),

                    // Divider
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Divider(
                          color: AppTheme.divider, height: 1),
                    ),

                    // Dynamic categories
                    if (_isExpanded)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                        child: Text(
                          'CATEGORIES',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.onSurface,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),

                    ...categories.map((category) => _buildSidebarItem(
                          icon: null,
                          emoji: _getCategoryIcon(category),
                          label: category,
                          category: category,
                          isSelected: widget.selectedCategory == category,
                          onTap: () => widget.onCategorySelected(category),
                          channelCount: playlistState
                                  .groupedChannels[category]?.length ??
                              0,
                        )),
                  ],
                ),
              ),

              // Bottom actions
              _buildBottomActions(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return TVFocusWidget(
      onSelect: _toggleExpand,
      borderRadius: BorderRadius.zero,
      showFocusScale: false,
      child: InkWell(
        onTap: _toggleExpand,
        child: Container(
          height: 72,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primary, AppTheme.accentSecondary],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.live_tv_rounded,
                    color: Colors.white, size: 22),
              ),
              if (_isExpanded) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: const Text(
                    'Flutter IPTV',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  _isExpanded ? Icons.chevron_left : Icons.chevron_right,
                  color: AppTheme.onSurface,
                  size: 20,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSidebarItem({
    IconData? icon,
    String? emoji,
    required String label,
    required String category,
    required bool isSelected,
    required VoidCallback onTap,
    int? badgeCount,
    int? channelCount,
  }) {
    return TVFocusWidget(
      onSelect: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primary.withOpacity(0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: isSelected
              ? Border.all(
                  color: AppTheme.primary.withOpacity(0.4),
                  width: 1,
                )
              : null,
        ),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              child: Center(
                child: emoji != null
                    ? Text(emoji, style: const TextStyle(fontSize: 16))
                    : Icon(
                        icon,
                        size: 20,
                        color: isSelected
                            ? AppTheme.primary
                            : AppTheme.onSurface,
                      ),
              ),
            ),
            if (_isExpanded) ...[
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected ? Colors.white : AppTheme.onBackground,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (badgeCount != null && badgeCount > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.accent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$badgeCount',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              else if (channelCount != null && channelCount > 0)
                Text(
                  '$channelCount',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.onSurface,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: AppTheme.divider)),
      ),
      child: Column(
        children: [
          _buildActionButton(
            icon: Icons.search_rounded,
            label: 'Search',
            onTap: widget.onSearchPressed,
          ),
          _buildActionButton(
            icon: Icons.settings_rounded,
            label: 'Settings',
            onTap: widget.onSettingsPressed,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return TVFocusWidget(
      onSelect: onTap,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              SizedBox(
                width: 24,
                child: Icon(icon, size: 20, color: AppTheme.onSurface),
              ),
              if (_isExpanded) ...[
                const SizedBox(width: 12),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.onBackground,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
