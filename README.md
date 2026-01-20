# Flutter DRM Module - AIT RND

A robust, enterprise-grade DRM (Digital Rights Management) module for Flutter, providing secure video playback and document viewing with high-level content protection.

## 🚀 Key Features

- **Widevine Video DRM**: Seamless integration with VdoCipher for secure, licensed video streams.
- **Secure Document Viewer**: Anti-copy, anti-selection PDF viewer with dynamic watermarking.
- **Advanced Screen Protection**:
  - **Screenshot Blocking**: OS-level prevention of screenshots (FLAG_SECURE/Native observers).
  - **Screen Recording Detection**: Auto-pauses video and alerts users when recording is active.
- **Device Safety Guard**: Blocks access on rooted/jailbroken devices and emulators.
- **Dynamic Watermarking**: Floating user-identifiable overlays to deter "Analog Hole" recording.
- **Lifecycle Security**: Automatically re-activates protection when the app returns from the background.

## 🏗️ Project Structure

The module is organized for easy "drop-in" integration:

```text
lib/drm/
├── drm.dart                 # Unified Entry Point (The only class you need to call)
├── drm_player_screen.dart   # Secure Video Player UI
├── drm_document_screen.dart # Secure Document Viewer UI
├── models/                  # Configuration & Data Models (DrmConfig, VideoItem)
├── services/                # Backend API & Security logic (DrmSecurityService)
├── widgets/                 # Reusable UI components (WatermarkOverlay)
└── providers/               # State management for DRM playback status
```

## 📦 Integration Guide

### 1. Initialize the Module
In your `main.dart`, initialize the DRM configuration. This sets up your global API keys and endpoints.

```dart
import 'package:your_app/drm/drm_module.dart';

void main() {
  Drm.init(
    config: const DrmConfig(
      otpEndpoint: 'https://api.yourbackend.com/vdocipher/otp',
      apiKey: 'optional-backend-api-key',
      defaultUserIdentifier: 'user_123@ait.inc', // Used for Watermarks
    ),
  );
  runApp(const MyApp());
}
```

### 2. Launching Secure Video Player
Call `Drm.openPlayer()` with a list of `VideoItem` objects.

```dart
Drm.openPlayer(
  context, 
  videos: [
    const VideoItem(
      title: 'Secure Lesson 01',
      videoId: 'vdocipher_id_here',
      thumbnailUrl: 'https://...',
      durationLabel: '10:00',
      drmType: DrmType.vdocipher,
    ),
  ],
);
```

### 3. Launching Secure Document Viewer
Call `Drm.openDocument()` to view protected PDFs.

```dart
Drm.openDocument(
  context,
  title: 'Confidential Report',
  url: 'https://example.com/secure.pdf',
  password: 'pdf-password-if-any',
);
```

## 🛡️ Security Implementation Details

### Screen Protection
We use industry-standard flags and observers to protect content:
- **Android**: Utilizes `WindowManager.LayoutParams.FLAG_SECURE` to prevent screenshots and screen/mirroring.
- **iOS**: Uses `UIScreen.capturedDidChangeNotification` and `UITextField` secure entry hacks to hide content from recordings and AirPlay.

### Device Check
The module verifies the following before granting access:
- `SafeDevice.isRealDevice`: Blocks emulators which are prone to sniffing.
- `SafeDevice.isJailBroken`: Blocks rooted devices where system-level protection can be bypassed.

### Watermark System
The `WatermarkOverlay` creates a randomly moving text layer over the content. This text should ideally be the user's email or unique ID, ensuring that any external filming can be traced back to the specific account.

## 🛠 Tech Stack

- **Flutter SDK**: ^3.10.4
- **vdocipher_flutter**: Native Widevine DRM implementation.
- **screen_protector**: Screenshot/Recording protection.
- **safe_device**: Root/Jailbreak detection.
- **syncfusion_flutter_pdfviewer**: High-performance PDF engine with anti-selection support.

---
Developed by **AIT RND Team**
