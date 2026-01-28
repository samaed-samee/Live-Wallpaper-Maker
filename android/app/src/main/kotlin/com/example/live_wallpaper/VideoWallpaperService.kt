package com.example.live_wallpaper

import android.app.WallpaperManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.media.MediaPlayer
import android.service.wallpaper.WallpaperService
import android.view.SurfaceHolder
import android.util.Log
import java.io.File
import java.io.IOException

class VideoWallpaperService : WallpaperService() {

    override fun onCreateEngine(): Engine {
        return VideoEngine()
    }

    inner class VideoEngine : Engine() {
        private var mediaPlayer: MediaPlayer? = null
        private var videoPath: String? = null

        override fun onCreate(surfaceHolder: SurfaceHolder) {
            super.onCreate(surfaceHolder)
             // Allow touch events if needed in future
             setTouchEventsEnabled(false)
        }

        override fun onSurfaceCreated(holder: SurfaceHolder) {
            super.onSurfaceCreated(holder)
            loadVideoPath()
            initializePlayer(holder)
        }

        override fun onSurfaceDestroyed(holder: SurfaceHolder) {
            super.onSurfaceDestroyed(holder)
            releasePlayer()
        }

        override fun onVisibilityChanged(visible: Boolean) {
            if (visible) {
                 // Re-check path in case it changed while not visible
                 val prefs = getSharedPreferences("wallpaper_prefs", Context.MODE_PRIVATE)
                 val newPath = prefs.getString("video_path", null)
                 if (newPath != videoPath && newPath != null) {
                     loadVideoPath()
                     initializePlayer(surfaceHolder)
                 } else {
                     mediaPlayer?.start()
                 }
            } else {
                mediaPlayer?.pause()
            }
        }

        private fun loadVideoPath() {
            val prefs = getSharedPreferences("wallpaper_prefs", Context.MODE_PRIVATE)
            videoPath = prefs.getString("video_path", null)
            Log.d("VideoWallpaperService", "Loaded video path: $videoPath")
        }

        private fun initializePlayer(holder: SurfaceHolder) {
            if (videoPath == null) return

            releasePlayer()
            
            try {
                mediaPlayer = MediaPlayer().apply {
                    setSurface(holder.surface)
                    setDataSource(videoPath)
                    setLooping(true)
                    setVolume(0f, 0f) // Mute by default
                    prepare()
                    start()
                }
            } catch (e: IOException) {
                Log.e("VideoWallpaperService", "Error initializing player", e)
            } catch (e: Exception) {
                 Log.e("VideoWallpaperService", "General error initializing player", e)
            }
        }

        private fun releasePlayer() {
            mediaPlayer?.release()
            mediaPlayer = null
        }
    }
}
