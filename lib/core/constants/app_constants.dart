class AppConstants {
  // App info
  static const String appName = 'Flutter IPTV';
  static const String appVersion = '1.0.0';

  // Hive box names
  static const String playlistBox = 'playlists';
  static const String favoritesBox = 'favorites';
  static const String settingsBox = 'settings';

  // Settings keys
  static const String keySelectedPlaylist = 'selected_playlist';
  static const String keyLastChannel = 'last_channel';
  static const String keyParentalPin = 'parental_pin';
  static const String keyAutoPlay = 'auto_play';
  static const String keyBufferSize = 'buffer_size';
  static const String keyUserAgent = 'user_agent';
  static const String keyEpgUrl = 'epg_url';

  // Default values
  static const String defaultUserAgent =
      'Mozilla/5.0 (Linux; Android 10; TV) AppleWebKit/537.36 Chrome/91.0.4472.164 Safari/537.36';
  static const int defaultBufferSize = 5; // seconds

  // UI constants - TV optimized
  static const double sidebarWidth = 220.0;
  static const double channelCardWidth = 200.0;
  static const double channelCardHeight = 130.0;
  static const double channelCardLogoSize = 64.0;
  static const double focusBorderWidth = 3.0;
  static const double borderRadius = 12.0;
  static const double cardSpacing = 16.0;
  static const double sectionSpacing = 32.0;

  // Animation durations
  static const Duration shortAnimation = Duration(milliseconds: 150);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);

  // Player
  static const Duration controlsHideDelay = Duration(seconds: 4);
  static const Duration seekDuration = Duration(seconds: 10);
  static const Duration skipDuration = Duration(seconds: 30);

  // Predefined sample playlists
  static const List<Map<String, String>> samplePlaylists = [
    {
      'name': 'Demo Playlist',
      'url':
          'https://iptv-org.github.io/iptv/languages/ind.m3u',
    },
    {
      'name': 'IPTV-Org Indonesia',
      'url': 'https://iptv-org.github.io/iptv/countries/id.m3u',
    },
  ];

  // Category icons mapping
  static const Map<String, String> categoryIcons = {
    'news': '📰',
    'sports': '⚽',
    'movies': '🎬',
    'entertainment': '🎭',
    'kids': '🧒',
    'music': '🎵',
    'documentary': '🎥',
    'series': '📺',
    'general': '📡',
    'comedy': '😄',
    'cooking': '👨‍🍳',
    'travel': '✈️',
    'nature': '🌿',
    'education': '📚',
    'lifestyle': '💅',
    'religious': '🕌',
    'business': '💼',
    'tech': '💻',
    'auto': '🚗',
    'fashion': '👗',
  };
}
