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
      title: 'DRM Module',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('DRM Samples')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildCard(
            context,
            title: 'Video DRM',
            subtitle: 'Secure VdoCipher Playback',
            icon: Icons.video_library,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DrmPlayerScreen(
                  videos: videos,
                  otpEndpoint: const String.fromEnvironment(
                    'VDOCIPHER_OTP_ENDPOINT',
                    defaultValue:
                        'https://drm-backend-psi.vercel.app/vdocipher/otp',
                  ),
                  apiKey: const String.fromEnvironment('BACKEND_API_KEY'),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildCard(
            context,
            title: 'Document DRM',
            subtitle: 'Secure PDF Viewer (No Copy/Download)',
            icon: Icons.picture_as_pdf,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const DrmDocumentScreen(
                  title: 'Secure Document',
                  url:
                      'https://cdn.syncfusion.com/content/PDFViewer/encrypted.pdf',
                  password: 'syncfusion',
                  userIdentifier: 'user_123@ait.inc',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      color: Colors.grey[900],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: Colors.blueAccent.withValues(alpha: 0.2),
          child: Icon(icon, color: Colors.blueAccent),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
