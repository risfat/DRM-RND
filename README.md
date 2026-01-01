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

## Widevine DRM MVP (VdoCipher)

This repository now includes an MVP integration of **Widevine DRM on Android** using **VdoCipher**, which provides both the **protected stream** and the **license infrastructure**.

### What you get in this MVP

- **Android Widevine DRM playback** using `vdocipher_flutter`
- **OTP-based authorization** (OTP is generated on your backend)
- A DRM-only playlist model (each item maps to a VdoCipher `videoId`)

### What you must provide

- A **VdoCipher account**
- At least 1 uploaded video with **DRM enabled** in VdoCipher dashboard
- A small **backend endpoint** that calls VdoCipher OTP API and returns:

```json
{ "otp": "...", "playbackInfo": "..." }
```

### 1) VdoCipher dashboard setup

1. Sign up / login to VdoCipher.
2. Upload a video (or ingest via API).
3. Enable DRM (Widevine) for the video (VdoCipher supports DRM-enabled playback via their SDK).
4. Copy the **Video ID** from VdoCipher dashboard.

### 2) Backend: Generate OTP (required)

OTP **must** be generated on a backend server. Do not ship your VdoCipher API Secret key inside the Flutter app.

VdoCipher OTP API (as per VdoCipher docs):

```text
POST https://dev.vdocipher.com/api/videos/{VIDEO_ID}/otp
Authorization: Apisecret <YOUR_VDOCIPHER_API_SECRET>
Content-Type: application/json

{ "ttl": 300 }
```

Your backend should proxy that into a simpler app-facing endpoint.

#### App-facing endpoint contract used by this Flutter app

- Method: `POST`
- URL: `https://YOUR_BACKEND.example.com/vdocipher/otp`
- Body:

```json
{ "videoId": "<vdocipherVideoId>", "ttl": 300 }
```

- Response:

```json
{ "otp": "<otp>", "playbackInfo": "<playbackInfo>" }
```

#### Sample backend (Node.js + Express)

This repository includes a ready-to-run Node backend in `backend/` with the endpoint:

- `POST /vdocipher/otp`

To run it:

```bash
# from repo root
cd backend
npm install
copy .env.example .env
npm run dev
```

Set `VDOCIPHER_API_SECRET` inside `backend/.env`.

Update the Flutter app endpoint in `lib/video_player_screen.dart`:

- Android emulator: `http://10.0.2.2:3000/vdocipher/otp`
- Physical device: `http://<YOUR_PC_LAN_IP>:3000/vdocipher/otp`

If you set `APP_API_KEY` in the backend `.env`, the backend will require the header `x-api-key`.
For the MVP, leave it empty.

1. Create a new Node project.
2. Install deps: `express`, `node-fetch` (or native fetch on Node 18+).
3. Implement:

```js
import express from 'express';

const app = express();
app.use(express.json());

const VDOCIPHER_API_SECRET = process.env.VDOCIPHER_API_SECRET;

app.post('/vdocipher/otp', async (req, res) => {
  try {
    const { videoId, ttl } = req.body;
    if (!videoId) return res.status(400).json({ error: 'videoId required' });

    const r = await fetch(`https://dev.vdocipher.com/api/videos/${videoId}/otp`, {
      method: 'POST',
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': `Apisecret ${VDOCIPHER_API_SECRET}`,
      },
      body: JSON.stringify({ ttl: ttl ?? 300 }),
    });

    const body = await r.text();
    if (!r.ok) return res.status(r.status).send(body);

    // VdoCipher returns JSON containing otp + playbackInfo among other fields
    const json = JSON.parse(body);
    return res.json({ otp: json.otp, playbackInfo: json.playbackInfo });
  } catch (e) {
    return res.status(500).json({ error: String(e) });
  }
});

app.listen(3000, () => console.log('OTP server on :3000'));
```

Set env var:

```bash
VDOCIPHER_API_SECRET=your_api_secret_here
```

### 3) App configuration

In `lib/video_player_screen.dart` update:

- `_vdoCipherOtpEndpoint` to your backend URL
- All playlist item `videoId` values (`YOUR_VDOCIPHER_VIDEO_ID_*`) to your real VdoCipher Video IDs

Then run:

1. `flutter pub get`
2. `flutter run` (use a real Android device; emulators often fail DRM)

### Notes / Limitations

- This MVP focuses on **Widevine on Android**. iOS FairPlay is not wired in this implementation.
- DRM requires a real device and a supported Widevine security level.
- Screen capture prevention is best-effort (OS-level constraints apply).

---
Developed by AIT RND Team
