import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/channel.dart';
import '../models/playlist.dart';
import '../services/m3u_parser.dart';

// State classes
class PlaylistState {
  final List<Playlist> playlists;
  final List<Channel> channels;
  final List<String> categories;
  final Map<String, List<Channel>> groupedChannels;
  final String? selectedCategory;
  final Playlist? activePlaylist;
  final bool isLoading;
  final String? error;
  final double loadingProgress;
  final String loadingMessage;

  const PlaylistState({
    this.playlists = const [],
    this.channels = const [],
    this.categories = const [],
    this.groupedChannels = const {},
    this.selectedCategory,
    this.activePlaylist,
    this.isLoading = false,
    this.error,
    this.loadingProgress = 0.0,
    this.loadingMessage = '',
  });

  PlaylistState copyWith({
    List<Playlist>? playlists,
    List<Channel>? channels,
    List<String>? categories,
    Map<String, List<Channel>>? groupedChannels,
    String? selectedCategory,
    Playlist? activePlaylist,
    bool? isLoading,
    String? error,
    double? loadingProgress,
    String? loadingMessage,
    bool clearError = false,
    bool clearActivePlaylist = false,
    bool clearSelectedCategory = false,
  }) {
    return PlaylistState(
      playlists: playlists ?? this.playlists,
      channels: channels ?? this.channels,
      categories: categories ?? this.categories,
      groupedChannels: groupedChannels ?? this.groupedChannels,
      selectedCategory:
          clearSelectedCategory ? null : (selectedCategory ?? this.selectedCategory),
      activePlaylist:
          clearActivePlaylist ? null : (activePlaylist ?? this.activePlaylist),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      loadingProgress: loadingProgress ?? this.loadingProgress,
      loadingMessage: loadingMessage ?? this.loadingMessage,
    );
  }

  List<Channel> get currentCategoryChannels {
    if (selectedCategory == null) return channels;
    if (selectedCategory == '__favorites__') {
      return channels.where((c) => c.isFavorite).toList();
    }
    if (selectedCategory == '__recent__') {
      final recent = channels
          .where((c) => c.lastWatched != null)
          .toList()
        ..sort((a, b) => b.lastWatched!.compareTo(a.lastWatched!));
      return recent.take(50).toList();
    }
    return groupedChannels[selectedCategory] ?? [];
  }
}

class PlaylistNotifier extends StateNotifier<PlaylistState> {
  static const _uuid = Uuid();

  PlaylistNotifier() : super(const PlaylistState()) {
    _init();
  }

  Future<void> _init() async {
    await _loadPlaylists();
  }

  Future<void> _loadPlaylists() async {
    final box = Hive.box<Playlist>('playlists');
    final playlists = box.values.toList();
    state = state.copyWith(playlists: playlists);

    // Auto-load active playlist
    final active = playlists.firstWhere(
      (p) => p.isActive,
      orElse: () => playlists.isEmpty ? Playlist(id: '', name: '', url: '') : playlists.first,
    );
    if (active.id.isNotEmpty) {
      await loadPlaylist(active);
    }
  }

  Future<void> addPlaylist({
    required String name,
    required String url,
    String? username,
    String? password,
  }) async {
    final playlist = Playlist(
      id: _uuid.v4(),
      name: name,
      url: url,
      username: username,
      password: password,
    );

    final box = Hive.box<Playlist>('playlists');
    await box.put(playlist.id, playlist);

    final playlists = [...state.playlists, playlist];
    state = state.copyWith(playlists: playlists);

    // Load if it's the first playlist
    if (state.playlists.length == 1) {
      await loadPlaylist(playlist);
    }
  }

  Future<void> deletePlaylist(String id) async {
    final box = Hive.box<Playlist>('playlists');
    await box.delete(id);
    final playlists = state.playlists.where((p) => p.id != id).toList();
    state = state.copyWith(playlists: playlists);

    if (state.activePlaylist?.id == id) {
      state = state.copyWith(
        channels: [],
        categories: [],
        groupedChannels: {},
        clearActivePlaylist: true,
        clearSelectedCategory: true,
      );
    }
  }

  Future<void> loadPlaylist(Playlist playlist) async {
    state = state.copyWith(
      isLoading: true,
      loadingMessage: 'Connecting to server...',
      loadingProgress: 0.0,
      clearError: true,
    );

    try {
      state = state.copyWith(
        loadingMessage: 'Downloading playlist...',
        loadingProgress: 0.2,
      );

      final channels = await M3UParser.parseFromUrl(playlist.url);

      state = state.copyWith(
        loadingMessage: 'Organizing channels...',
        loadingProgress: 0.7,
      );

      final categories = M3UParser.extractCategories(channels);
      final grouped = M3UParser.groupByCategory(channels);

      // Restore favorites from Hive
      final favBox = Hive.box<Channel>('favorites');
      final favoriteIds = favBox.values.map((c) => c.id).toSet();
      final channelsWithFavorites = channels.map((c) {
        return favoriteIds.contains(c.id) ? c.copyWith(isFavorite: true) : c;
      }).toList();

      // Update playlist metadata
      final box = Hive.box<Playlist>('playlists');
      playlist.channelCount = channels.length;
      playlist.lastUpdated = DateTime.now();
      playlist.isActive = true;
      await box.put(playlist.id, playlist);

      // Deactivate other playlists
      for (final p in state.playlists) {
        if (p.id != playlist.id && p.isActive) {
          p.isActive = false;
          await box.put(p.id, p);
        }
      }

      state = state.copyWith(
        channels: channelsWithFavorites,
        categories: categories,
        groupedChannels: grouped,
        activePlaylist: playlist,
        selectedCategory: categories.isNotEmpty ? categories.first : null,
        isLoading: false,
        loadingProgress: 1.0,
        loadingMessage: 'Done!',
        playlists: box.values.toList(),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
        loadingProgress: 0.0,
      );
    }
  }

  void selectCategory(String category) {
    state = state.copyWith(selectedCategory: category);
  }

  Future<void> toggleFavorite(Channel channel) async {
    final favBox = Hive.box<Channel>('favorites');
    final newFavoriteState = !channel.isFavorite;

    if (newFavoriteState) {
      await favBox.put(channel.id, channel.copyWith(isFavorite: true));
    } else {
      await favBox.delete(channel.id);
    }

    final updatedChannels = state.channels.map((c) {
      if (c.id == channel.id) {
        return c.copyWith(isFavorite: newFavoriteState);
      }
      return c;
    }).toList();

    final updatedGrouped = <String, List<Channel>>{};
    for (final entry in state.groupedChannels.entries) {
      updatedGrouped[entry.key] = entry.value.map((c) {
        if (c.id == channel.id) {
          return c.copyWith(isFavorite: newFavoriteState);
        }
        return c;
      }).toList();
    }

    state = state.copyWith(
      channels: updatedChannels,
      groupedChannels: updatedGrouped,
    );
  }

  void updateChannelWatched(String channelId) {
    final updatedChannels = state.channels.map((c) {
      if (c.id == channelId) {
        return c.copyWith(
          watchCount: c.watchCount + 1,
          lastWatched: DateTime.now(),
        );
      }
      return c;
    }).toList();
    state = state.copyWith(channels: updatedChannels);
  }

  Future<void> refreshPlaylist() async {
    if (state.activePlaylist != null) {
      await loadPlaylist(state.activePlaylist!);
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

// Providers
final playlistProvider =
    StateNotifierProvider<PlaylistNotifier, PlaylistState>((ref) {
  return PlaylistNotifier();
});

final currentChannelsProvider = Provider<List<Channel>>((ref) {
  return ref.watch(playlistProvider).currentCategoryChannels;
});

final categoriesProvider = Provider<List<String>>((ref) {
  return ref.watch(playlistProvider).categories;
});

final favoritesProvider = Provider<List<Channel>>((ref) {
  return ref.watch(playlistProvider).channels.where((c) => c.isFavorite).toList();
});
