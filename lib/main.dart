import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:media_kit/media_kit.dart';

import 'app.dart';
import 'models/channel.dart';
import 'models/playlist.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize MediaKit
  MediaKit.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();
  Hive.registerAdapter(ChannelAdapter());
  Hive.registerAdapter(PlaylistAdapter());
  Hive.registerAdapter(CategoryModelAdapter());
  await Hive.openBox<Playlist>('playlists');
  await Hive.openBox<Channel>('favorites');
  await Hive.openBox('settings');

  // Force landscape for TV
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Hide system UI for TV immersive experience
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  runApp(
    const ProviderScope(
      child: IPTVApp(),
    ),
  );
}
