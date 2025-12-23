# DRM RND Project - Secure Video Player

This is a Flutter Research and Development (RND) project focused on implementing Digital Rights Management (DRM) best practices and content protection techniques for mobile video playback.

## 🚀 Features

### 1. Content Protection
- **Screenshot Prevention**: Blocks the system's ability to take screenshots of the application.
- **Screen Recording Blocking**: Automatically blacks out the video content when a screen recording is detected (Android) or shows a warning (iOS).
- **Background Blur**: Blurs the application preview in the task switcher (iOS) to prevent data leakage.

### 2. Dynamic Watermarking
- **Anti-Analog Countermeasure**: A bouncing watermark ("AIT") that moves randomly across the screen every 3 seconds.
- **Cross-Orientation Support**: The watermark is attached to the video player's overlay system, ensuring it persists in both **Portrait** and **Landscape/Fullscreen** modes.
- **Traceability**: Designed to identify users who might record the screen using an external camera (the "Analog Hole").

### 3. Lifecycle Security
- **Auto-Pause**: Playback is automatically paused when the app is minimized or loses focus.
- **Auto-Lock**: Re-verifies protection flags whenever the app returns to the foreground.

### 4. Experience
- **Custom Player**: Built on `chewie` for a premium, YouTube-like playback experience.
- **Playlist System**: Quick switching between protected video assets.

## 🛠 Tech Stack

- **Flutter**: Desktop-grade UI performance.
- **screen_protector**: Native-level window flags (FLAG_SECURE) for Android and transition observers for iOS.
- **video_player & chewie**: Industry-standard video playback and custom overlay management.

## 📦 Getting Started

### Prerequisites
- Flutter SDK (v3.10.4 or higher)
- Android Studio / Xcode

### Installation
1. Clone the repository.
2. Run `flutter pub get`.
3. Connect a physical device (Screen protection features often do not work correctly on emulators/simulators).
4. Execute `flutter run`.

## ⚠️ Known Limitations & Future RND
Currently, this project focuses on **UI/System level protection**. For production-grade security, the following should be considered:

1.  **Network Sniffing**: The current project uses direct MP4 links. In a production environment, use **Widevine (Android)** and **FairPlay (iOS)** encryption to prevent network-level stealing.
2.  **Analog Hole**: While watermarking identifies the leaker, it cannot physically prevent someone from filming the screen with another device.
3.  **App Cloning**: Rooted/Jailbroken devices can sometimes bypass window flags. Production apps should include Root/Jailbreak detection.

---
**Developed by AIT RND Team**
