import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../models/channel.dart';
import '../../providers/playlist_provider.dart';
import '../../widgets/common/tv_focus_widget.dart';
import 'package:cached_network_image/cached_network_image.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<Channel> _results = [];
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    setState(() {
      _query = query;
      if (query.isEmpty) {
        _results = [];
        return;
      }
      final channels = ref.read(playlistProvider).channels;
      _results = channels.where((c) {
        final nameLower = c.name.toLowerCase();
        final groupLower = c.groupTitle.toLowerCase();
        final queryLower = query.toLowerCase();
        return nameLower.contains(queryLower) || groupLower.contains(queryLower);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(
        children: [
          // Header
          _buildHeader(),

          // Results
          Expanded(
            child: _query.isEmpty
                ? _buildEmptyState()
                : _results.isEmpty
                    ? _buildNoResults()
                    : _buildResults(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(bottom: BorderSide(color: AppTheme.divider)),
      ),
      child: Row(
        children: [
          // Back button
          TVFocusWidget(
            onSelect: () => context.pop(),
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              onTap: () => context.pop(),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceElevated,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.arrow_back_rounded,
                    color: Colors.white, size: 22),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Search field
          Expanded(
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              onChanged: _onSearch,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              decoration: InputDecoration(
                hintText: 'Search channels, categories...',
                prefixIcon: const Icon(Icons.search_rounded,
                    color: AppTheme.onSurface),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded,
                            color: AppTheme.onSurface),
                        onPressed: () {
                          _searchController.clear();
                          _onSearch('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppTheme.surfaceElevated,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                      color: AppTheme.focusedBorder, width: 2),
                ),
              ),
              autofocus: true,
            ),
          ),

          // Results count
          if (_results.isNotEmpty) ...[
            const SizedBox(width: 16),
            Text(
              '${_results.length} results',
              style: const TextStyle(color: AppTheme.onSurface, fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildResults() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final channel = _results[index];
        return _SearchResultItem(
          channel: channel,
          query: _query,
          onTap: () {
            ref.read(playlistProvider.notifier).updateChannelWatched(channel.id);
            context.push('/player', extra: {
              'channelName': channel.name,
              'streamUrl': channel.streamUrl,
              'channelLogo': channel.logoUrl,
              'groupTitle': channel.groupTitle,
            });
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_rounded, size: 80, color: AppTheme.onSurface),
          SizedBox(height: 16),
          Text(
            'Search for channels',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.onBackground,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Type a channel name or category',
            style: TextStyle(color: AppTheme.onSurface),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off_rounded,
              size: 80, color: AppTheme.onSurface),
          const SizedBox(height: 16),
          Text(
            'No results for "$_query"',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.onBackground,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Try a different search term',
            style: TextStyle(color: AppTheme.onSurface),
          ),
        ],
      ),
    );
  }
}

class _SearchResultItem extends StatefulWidget {
  final Channel channel;
  final String query;
  final VoidCallback onTap;

  const _SearchResultItem({
    required this.channel,
    required this.query,
    required this.onTap,
  });

  @override
  State<_SearchResultItem> createState() => _SearchResultItemState();
}

class _SearchResultItemState extends State<_SearchResultItem> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return TVFocusWidget(
      onSelect: widget.onTap,
      onFocusGained: () => setState(() => _isFocused = true),
      onFocusLost: () => setState(() => _isFocused = false),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color:
              _isFocused ? AppTheme.surfaceElevated : AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(12),
          child: Row(
            children: [
              // Logo
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 52,
                  height: 40,
                  child: widget.channel.logoUrl != null
                      ? CachedNetworkImage(
                          imageUrl: widget.channel.logoUrl!,
                          fit: BoxFit.contain,
                          errorWidget: (_, __, ___) =>
                              _buildLogoPlaceholder(),
                        )
                      : _buildLogoPlaceholder(),
                ),
              ),
              const SizedBox(width: 16),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHighlightedText(
                      widget.channel.name,
                      widget.query,
                      const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.channel.groupTitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),

              // Play icon
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _isFocused
                      ? AppTheme.primary
                      : AppTheme.surfaceElevated,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.play_arrow_rounded,
                  color: _isFocused ? Colors.white : AppTheme.onSurface,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHighlightedText(String text, String query, TextStyle style) {
    if (query.isEmpty) return Text(text, style: style);
    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final index = lowerText.indexOf(lowerQuery);
    if (index == -1) return Text(text, style: style);

    return RichText(
      text: TextSpan(
        children: [
          if (index > 0)
            TextSpan(text: text.substring(0, index), style: style),
          TextSpan(
            text: text.substring(index, index + query.length),
            style: style.copyWith(
              color: AppTheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (index + query.length < text.length)
            TextSpan(
              text: text.substring(index + query.length),
              style: style,
            ),
        ],
      ),
    );
  }

  Widget _buildLogoPlaceholder() {
    return Container(
      color: AppTheme.surfaceElevated,
      child: Center(
        child: Text(
          widget.channel.name.substring(0, 1).toUpperCase(),
          style: const TextStyle(
            color: AppTheme.primary,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
