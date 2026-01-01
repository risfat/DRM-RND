# DRM Module (Widevine/FairPlay-ready)

This module (`lib/drm/`) provides a **reusable, industry-structured DRM player** for Flutter apps. It currently supports **VdoCipher Widevine DRM on Android** and is architected for easy extension to **FairPlay (iOS)**.

## Architecture Overview

```
lib/drm/
├─ models/
│  ├─ video_item.dart        # Video metadata + DRM type enum
│  └─ drm_auth.dart          # OTP/playbackInfo wrapper
├─ services/
│  ├─ drm_service.dart      # Abstract DRM service interface
│  └─ vdocipher_service.dart # VdoCipher implementation (Android)
├─ providers/
│  └─ drm_player_provider.dart # State management (loading/error/ready)
├─ widgets/
│  └─ watermark_overlay.dart # Anti-analog watermark
├─ drm_player_screen.dart   # DRM-only player UI
└─ drm_module.dart          # Barrel export for easy reuse
```

## Key Design Decisions

- **Dependency Inversion**: `DrmService` abstract interface; add FairPlay by implementing `DrmService` without touching UI.
- **State Management**: Simple `ChangeNotifier` provider; no heavy framework required.
- **Platform Guard**: `isPlatformSupported` ensures unsupported platforms show a clear error.
- **Security**: OTP secret never leaves backend; configurable endpoint via `--dart-define`.
- **Extensibility**: `DrmType` enum and `VideoItem` model support multiple DRM vendors.

## How to Use in Another Project

### 1) Copy the module
Copy `lib/drm/` into your target app’s `lib/`.

### 2) Add dependencies
```yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^1.2.2
  vdocipher_flutter: ^2.2.0
  safe_device: ^1.1.2
  screen_protector: ^1.3.0
```

### 3) Import and use
```dart
import 'package:your_app/drm/drm_module.dart';

MaterialApp(
  home: DrmPlayerScreen(
    videos: [
      VideoItem(
        title: 'My Protected Video',
        thumbnailUrl: '...',
        durationLabel: 'DRM',
        drmType: DrmType.vdocipher,
        videoId: 'YOUR_VDOCIPHER_VIDEO_ID',
      ),
    ],
    otpEndpoint: 'https://your-backend.com/vdocipher/otp',
    apiKey: 'optional-api-key',
  ),
);
```

### 4) Run with endpoint
```bash
flutter run --dart-define=VDOCIPHER_OTP_ENDPOINT=https://your-backend.com/vdocipher/otp
```

## Adding FairPlay (Future)

1. Add `DrmType.fairplay` to the enum.
2. Create `lib/drm/services/fairplay_service.dart` implementing `DrmService`.
3. In `DrmPlayerScreen`, instantiate the appropriate service based on `video.drmType`.
4. Add iOS-specific player widget (e.g., using `AVPlayer`/FairPlay plugin).

## Backend Requirement

Your backend must expose:

```
POST /vdocipher/otp
{ "videoId": "...", "ttl": 300 }
=> { "otp": "...", "playbackInfo": "..." }
```

See the included `drm_backend/` Node server for a reference implementation.

## Security Notes

- Never embed your VdoCipher API secret in the Flutter app.
- Use `--dart-define` to inject the backend URL per environment.
- The module validates placeholder video IDs and shows clear errors until configured.

## License/Extract

You may extract `lib/drm/` into a separate package or copy it into any Flutter project. Keep the module self-contained and avoid coupling to app-specific code.

---
