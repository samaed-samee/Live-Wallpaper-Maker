package com.example.live_wallpaper

import android.app.WallpaperManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.os.Build
import android.widget.Toast
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.live_wallpaper/channels"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "setWallpaper") {
                val path = call.argument<String>("path")
                if (path != null) {
                    saveVideoPath(path)
                    openWallpaperPicker()
                    result.success(true)
                } else {
                    result.error("INVALID_PATH", "Video path is null", null)
                }
            } else if (call.method == "checkCapability") {
                 result.success(true)
            } else {
                result.notImplemented()
            }
        }
    }

    private fun saveVideoPath(path: String) {
        val prefs = getSharedPreferences("wallpaper_prefs", Context.MODE_PRIVATE)
        prefs.edit().putString("video_path", path).apply()
    }

    private fun openWallpaperPicker() {
        val intent = Intent(WallpaperManager.ACTION_CHANGE_LIVE_WALLPAPER)
        intent.putExtra(WallpaperManager.EXTRA_LIVE_WALLPAPER_COMPONENT,
            ComponentName(this, VideoWallpaperService::class.java))
        startActivity(intent)
    }
}
