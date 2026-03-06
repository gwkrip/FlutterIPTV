# 📺 Flutter IPTV

[![Build Status](https://github.com/YOUR_USERNAME/flutter-iptv/actions/workflows/build_release.yml/badge.svg)](https://github.com/YOUR_USERNAME/flutter-iptv/actions)
[![Flutter](https://img.shields.io/badge/Flutter-3.19+-blue.svg)](https://flutter.dev)
[![Android TV](https://img.shields.io/badge/Android%20TV-Optimized-green.svg)](https://developer.android.com/tv)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

A full-featured IPTV player built with Flutter, **optimized for Android TV** with D-pad navigation, cinematic dark UI, and hardware-accelerated video playback.

<p align="center">
  <img src="assets/images/screenshot_home.png" width="600" alt="Home Screen" />
</p>

---

## ✨ Features

- 📋 **M3U/M3U8 Playlist Support** — Load any M3U playlist from URL
- 📺 **Android TV Optimized** — Full D-pad navigation, TV remote support
- 🎬 **Hardware-Accelerated Playback** — Powered by `media_kit` (libmpv)
- 📁 **Category Organization** — Auto-groups channels by category
- 🔍 **Smart Search** — Search channels with highlighted results
- ❤️ **Favorites** — Save and quickly access your favorite channels
- 🕐 **Watch History** — Recently watched channels
- ⚡ **Multiple Playlists** — Manage multiple M3U sources
- 🎨 **Cinematic Dark UI** — Beautiful TV-optimized dark theme
- 🔄 **Auto-Refresh** — Reload playlist to get latest channels
- 📡 **LIVE & VOD** — Supports both live streams and video-on-demand
- ⏯️ **Player Controls** — Play/pause, seek, volume, speed, channel switching
- 🖥️ **Full-screen Immersive** — True full-screen TV experience

---

## 🚀 Quick Start

### Prerequisites

- Flutter SDK `>=3.19.0`
- Android SDK with API 21+
- Java 17
- For Android TV testing: Android TV emulator or physical device

### Setup

```bash
# Clone the repo
git clone https://github.com/YOUR_USERNAME/flutter-iptv.git
cd flutter-iptv

# Install dependencies
flutter pub get

# Run on Android TV emulator/device
flutter run

# Build release APK
flutter build apk --release
```

---

## 📱 Android TV Navigation

| Remote Key | Action |
|-----------|--------|
| **D-pad Up/Down** | Switch channels |
| **D-pad Left/Right** | Seek (VOD) |
| **OK / Select** | Play channel / Confirm |
| **Back** | Go back / Close player |
| **Menu** | Show controls |
| **Play/Pause** | Toggle playback |
| **Fast Forward** | Skip forward 30s |
| **Rewind** | Skip back 30s |

---

## 🏗️ Project Structure

```
lib/
├── core/
│   ├── theme/          # Dark TV theme + typography
│   └── constants/      # App-wide constants
├── models/             # Hive data models
│   ├── channel.dart
│   └── playlist.dart
├── services/
│   └── m3u_parser.dart # M3U/M3U8 parsing engine
├── providers/          # Riverpod state management
│   ├── playlist_provider.dart
│   └── player_provider.dart
├── screens/
│   ├── splash/         # App loading screen
│   ├── home/           # Main TV interface
│   ├── player/         # Full-screen video player
│   ├── search/         # Channel search
│   └── settings/       # Playlist & app settings
└── widgets/
    └── common/
        └── tv_focus_widget.dart  # D-pad focus system
```

---

## 🔧 Adding a Playlist

1. Open the app → **Settings** → **Playlists**
2. Click **Add Playlist**
3. Enter a name and your M3U URL
4. The playlist loads automatically

### M3U Format Support

```
#EXTM3U
#EXTINF:-1 tvg-id="CNN" tvg-name="CNN" tvg-logo="https://..." group-title="News",CNN
http://stream.example.com/cnn
```

---

## 🔄 GitHub Actions CI/CD

### Automatic Release

Create a tag to trigger an automatic build and release:

```bash
git tag v1.0.0
git push origin v1.0.0
```

### Manual Release (via GitHub UI)

1. Go to **Actions** tab in GitHub
2. Select **Build & Release Android TV APK**
3. Click **Run workflow**
4. Choose release type: `patch`, `minor`, or `major`

### Setting Up Signing (Optional)

For signed APKs, add these **Repository Secrets** in GitHub Settings:

| Secret | Description |
|--------|-------------|
| `KEY_STORE_BASE64` | Base64-encoded keystore file |
| `KEY_STORE_PASSWORD` | Keystore password |
| `KEY_ALIAS` | Key alias |
| `KEY_PASSWORD` | Key password |

**Generate keystore:**
```bash
keytool -genkey -v -keystore release.jks \
  -alias mykey -keyalg RSA -keysize 2048 \
  -validity 10000

# Encode to base64
base64 -i release.jks | tr -d '\n'
```

---

## 📦 Tech Stack

| Package | Purpose |
|---------|---------|
| `flutter_riverpod` | State management |
| `media_kit` | Video playback (libmpv) |
| `go_router` | Navigation |
| `hive_flutter` | Local persistence |
| `http` | Network requests |
| `cached_network_image` | Image caching |
| `shimmer` | Loading placeholders |
| `google_fonts` | Typography |

---

## 🤝 Contributing

1. Fork the project
2. Create your branch: `git checkout -b feature/amazing-feature`
3. Commit: `git commit -m 'feat: add amazing feature'`
4. Push: `git push origin feature/amazing-feature`
5. Open a Pull Request

---

## 📄 License

MIT License — see [LICENSE](LICENSE) file for details.
