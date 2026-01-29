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
  final Map<String, Uint8List?> _thumbnails = {};
  bool _isLoading = true;
  bool _showFabLabel = true;

  @override
  void initState() {
    super.initState();
    _loadRecentVideos();
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showFabLabel = false;
        });
      }
    });
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

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("How to use"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildStep(
                icon: Icons.search,
                color: Colors.redAccent,
                title: "1. Find Video",
                description:
                    "Search for 'Vertical Mobile Live Wallpaper' on Pinterest or Google.",
              ),
              const SizedBox(height: 16),
              _buildStep(
                icon: Icons.download_rounded,
                color: Colors.blueAccent,
                title: "2. Download",
                description: "Save the MP4 video to your device gallery.",
              ),
              const SizedBox(height: 16),
              _buildStep(
                icon: Icons.wallpaper,
                color: Colors.green,
                title: "3. Set Wallpaper",
                description: "Tap '+' in this app, pick the video, and Apply.",
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Got it"),
          ),
        ],
      ),
    );
  }

  Widget _buildStep({
    required IconData icon,
    required Color color,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          child: Icon(icon, color: color),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Wallpaper Maker'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () => _showHelpDialog(context),
            tooltip: 'How to use',
          ),
          IconButton(onPressed: _pickVideo, icon: const Icon(Icons.add)),
        ],
      ),
      floatingActionButton: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        width: _showFabLabel ? 160.0 : 56.0,
        height: 56.0,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(16.0),
          boxShadow: kElevationToShadow[6],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _pickVideo,
            borderRadius: BorderRadius.circular(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.video_library),
                AnimatedSize(
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                  child: Row(
                    children: [
                      if (_showFabLabel) ...[
                        const SizedBox(width: 12),
                        const Text(
                          "Select Video",
                          style: TextStyle(fontWeight: FontWeight.bold),
                          overflow: TextOverflow.clip,
                          softWrap: false,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
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
