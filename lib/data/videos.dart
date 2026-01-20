import '../drm/models/video_item.dart';

// Videos to upload to VdoCipher (raw URLs)
// 1. Big Buck Bunny
//    - Raw URL: https://storage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4
//    - Thumbnail: https://storage.googleapis.com/gtv-videos-bucket/sample/images/BigBuckBunny.jpg
//    - VdoCipher videoId: c5d0d27026fa79a49c1c94655e587f8a

// 2. Elephants Dream
//    - Raw URL: https://storage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4
//    - Thumbnail: https://storage.googleapis.com/gtv-videos-bucket/sample/images/ElephantsDream.jpg
//    - VdoCipher videoId: YOUR_VDOCIPHER_VIDEO_ID_2

// 3. For Bigger Blazes
//    - Raw URL: https://storage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4
//    - Thumbnail: https://storage.googleapis.com/gtv-videos-bucket/sample/images/ForBiggerBlazes.jpg
//    - VdoCipher videoId: YOUR_VDOCIPHER_VIDEO_ID_3

// 4. For Bigger Escape
//    - Raw URL: https://storage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4
//    - Thumbnail: https://storage.googleapis.com/gtv-videos-bucket/sample/images/ForBiggerEscapes.jpg
//    - VdoCipher videoId: YOUR_VDOCIPHER_VIDEO_ID_4

// 5. Sintel
//    - Raw URL: https://storage.googleapis.com/gtv-videos-bucket/sample/Sintel.mp4
//    - Thumbnail: https://storage.googleapis.com/gtv-videos-bucket/sample/images/Sintel.jpg
//    - VdoCipher videoId: YOUR_VDOCIPHER_VIDEO_ID_5

final videos = [
  VideoItem(
    title: 'Tears of Steel',
    thumbnailUrl:
        'https://storage.googleapis.com/gtv-videos-bucket/sample/images/TearsOfSteel.jpg',
    durationLabel: 'DRM',
    drmType: DrmType.vdocipher,
    videoId: 'c5d0d27026fa79a49c1c94655e587f8a',
  ),
  VideoItem(
    title: 'Big Buck Bunny',
    thumbnailUrl:
        'https://storage.googleapis.com/gtv-videos-bucket/sample/images/BigBuckBunny.jpg',
    durationLabel: 'DRM',
    drmType: DrmType.vdocipher,
    videoId: 'ab9fef9cfe9640799876e199ba3055e6',
  ),
  VideoItem(
    title: 'Elephants Dream',
    thumbnailUrl:
        'https://storage.googleapis.com/gtv-videos-bucket/sample/images/ElephantsDream.jpg',
    durationLabel: 'DRM',
    drmType: DrmType.vdocipher,
    videoId: 'f68cd66b9dfe4588ad627fa7fa7784df',
  ),
  VideoItem(
    title: 'For Bigger Blazes',
    thumbnailUrl:
        'https://storage.googleapis.com/gtv-videos-bucket/sample/images/ForBiggerBlazes.jpg',
    durationLabel: 'DRM',
    drmType: DrmType.vdocipher,
    videoId: 'df4c818d44a04b53a226778f08afca47',
  ),
  // VideoItem(
  //   title: 'For Bigger Escape',
  //   thumbnailUrl:
  //       'https://storage.googleapis.com/gtv-videos-bucket/sample/images/ForBiggerEscapes.jpg',
  //   durationLabel: 'DRM',
  //   drmType: DrmType.vdocipher,
  //   videoId: 'YOUR_VDOCIPHER_VIDEO_ID_4',
  // ),
  // VideoItem(
  //   title: 'Sintel',
  //   thumbnailUrl:
  //       'https://storage.googleapis.com/gtv-videos-bucket/sample/images/Sintel.jpg',
  //   durationLabel: 'DRM',
  //   drmType: DrmType.vdocipher,
  //   videoId: 'YOUR_VDOCIPHER_VIDEO_ID_5',
  // ),
];
