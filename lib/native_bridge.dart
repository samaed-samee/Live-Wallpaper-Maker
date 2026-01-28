import 'package:flutter/services.dart';

class NativeBridge {
  static const MethodChannel _channel = MethodChannel(
    'com.example.live_wallpaper/channels',
  );

  /// Requests the native side to set the wallpaper using the video at [path].
  static Future<bool> setWallpaper(String path) async {
    try {
      final result = await _channel.invokeMethod('setWallpaper', {
        'path': path,
      });
      return result == true;
    } on PlatformException catch (e) {
      print("Failed to set wallpaper: '${e.message}'.");
      return false;
    }
  }

  /// Checks if the device supports live wallpapers (basic check).
  static Future<bool> checkCapability() async {
    try {
      final result = await _channel.invokeMethod('checkCapability');
      return result == true;
    } on PlatformException catch (e) {
      print("Failed to check capability: '${e.message}'.");
      return false;
    }
  }
}
