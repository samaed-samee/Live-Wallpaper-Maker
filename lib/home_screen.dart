import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:live_wallpaper/preview_screen.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<String> _recentVideos = [];
  Map<String, Uint8List?> _thumbnails = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecentVideos();
  }

  Future<void> _loadRecentVideos() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> loaded = prefs.getStringList('recent_videos') ?? [];

    // Filter out files that no longer exist
    final existingFiles = loaded
        .where((path) => File(path).existsSync())
        .toList();

    // Update prefs if files were removed
    if (existingFiles.length != loaded.length) {
      await prefs.setStringList('recent_videos', existingFiles);
    }

    setState(() {
      _recentVideos = existingFiles;
      _isLoading = false;
    });

    // Generate thumbnails
    for (var path in existingFiles) {
      _generateThumbnail(path);
    }
  }

  Future<void> _savePathToHistory(String path) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> currentList = prefs.getStringList('recent_videos') ?? [];

    currentList.remove(path);
    currentList.insert(0, path); // Add to top
    if (currentList.length > 20) {
      currentList = currentList.sublist(0, 20);
    }

    await prefs.setStringList('recent_videos', currentList);
    setState(() {
      _recentVideos = currentList;
    });
    _generateThumbnail(path);
  }

  Future<void> _generateThumbnail(String path) async {
    if (_thumbnails.containsKey(path)) return;

    try {
      final uint8list = await VideoThumbnail.thumbnailData(
        video: path,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 256,
        quality: 75,
        timeMs: 1500, // Capture at 1.5s to avoid black start frames
      );
      if (mounted && uint8list != null) {
        setState(() {
          _thumbnails[path] = uint8list;
        });
      }
    } catch (e) {
      print("Error generating thumbnail for $path: $e");
    }
  }

  Future<void> _pickVideo() async {
    if (Platform.isAndroid) {
      var status = await Permission.storage.status;
      // For Android 13+ (SDK 33)
      var videoStatus = await Permission.videos.status;

      if (!status.isGranted && !videoStatus.isGranted) {
        await Permission.storage.request();
        await Permission.videos.request();
      }
    }

    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.video,
      allowMultiple: false,
    );

    if (result != null) {
      final path = result.files.single.path;
      if (path != null) {
        await _savePathToHistory(path);
        _navigateToPreview(path);
      }
    }
  }

  void _navigateToPreview(String path) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PreviewScreen(videoPath: path)),
    );
  }

  void _deleteVideo(String path) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> currentList = prefs.getStringList('recent_videos') ?? [];
    currentList.remove(path);
    await prefs.setStringList('recent_videos', currentList);
    setState(() {
      _recentVideos = currentList;
      _thumbnails.remove(path);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Wallpaper Maker'),
        centerTitle: true,
        actions: [
          IconButton(onPressed: _pickVideo, icon: const Icon(Icons.add)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _pickVideo,
        icon: const Icon(Icons.video_library),
        label: const Text("Select Video"),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _recentVideos.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.wallpaper, size: 80, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    "No videos selected yet.",
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _pickVideo,
                    child: const Text("Pick a Video"),
                  ),
                ],
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 16 / 9,
              ),
              itemCount: _recentVideos.length,
              itemBuilder: (context, index) {
                final path = _recentVideos[index];
                final thumb = _thumbnails[path];

                return GestureDetector(
                  onTap: () => _navigateToPreview(path),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Container(color: Colors.black26), // Placeholder
                        if (thumb != null)
                          Image.memory(thumb, fit: BoxFit.cover),

                        // Gradient Overlay
                        const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [Colors.black54, Colors.transparent],
                            ),
                          ),
                        ),

                        // Play Icon
                        const Center(
                          child: Icon(
                            Icons.play_circle_outline,
                            color: Colors.white70,
                            size: 40,
                          ),
                        ),

                        // Delete Button
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () => _deleteVideo(path),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
