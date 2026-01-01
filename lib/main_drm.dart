import 'package:flutter/material.dart';
import 'data/videos.dart';
import 'drm/drm_module.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DRM Player',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: DrmPlayerScreen(
        videos: videos,
        otpEndpoint: const String.fromEnvironment(
          'VDOCIPHER_OTP_ENDPOINT',
          defaultValue: 'https://drm-backend-psi.vercel.app/vdocipher/otp',
        ),
        apiKey: const String.fromEnvironment('BACKEND_API_KEY'),
      ),
    );
  }
}
