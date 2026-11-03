package com.mplive.wallpaper

import android.content.Context
import android.media.MediaPlayer
import android.service.wallpaper.WallpaperService
import android.util.Log
import android.view.SurfaceHolder
import androidx.media3.common.MediaItem
import androidx.media3.common.Player
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.common.C
import androidx.media3.common.MediaItem.ClippingConfiguration
import java.io.File

class VideoWallpaperService : WallpaperService() {

    override fun onCreateEngine(): Engine {
        return VideoEngine()
    }

    inner class VideoEngine : Engine() {
        private var exoPlayer: ExoPlayer? = null
        private var videoPath: String? = null
        private var isVisible = false

        override fun onCreate(surfaceHolder: SurfaceHolder) {
            super.onCreate(surfaceHolder)
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
            this.isVisible = visible
            if (visible) {
                 // Re-check path in case it changed while not visible
                 val prefs = getSharedPreferences("wallpaper_prefs", Context.MODE_PRIVATE)
                 val newPath = prefs.getString("video_path", null)
                 if (newPath != videoPath && newPath != null) {
                     videoPath = newPath
                     initializePlayer(surfaceHolder)
                 } else {
                     exoPlayer?.play()
                 }
            } else {
                exoPlayer?.pause()
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
                exoPlayer = ExoPlayer.Builder(applicationContext).build().apply {
                    setVideoSurfaceHolder(holder)
                    repeatMode = Player.REPEAT_MODE_ONE
                    volume = 0f // Mute
                }

                // Create a MediaItem with ClippingConfiguration for 15s limit
                val trimmingConfig = ClippingConfiguration.Builder()
                    .setStartPositionMs(0)
                    .setEndPositionMs(15_000) // 15 seconds
                    .build()

                val mediaItem = MediaItem.Builder()
                    .setUri(File(videoPath!!).toURI().toString())
                    .setClippingConfiguration(trimmingConfig)
                    .build()

                exoPlayer?.setMediaItem(mediaItem)
                exoPlayer?.prepare()
                
                if (isVisible) {
                    exoPlayer?.play()
                }

            } catch (e: Exception) {
                 Log.e("VideoWallpaperService", "Error initializing ExoPlayer", e)
            }
        }

        private fun releasePlayer() {
            exoPlayer?.release()
            exoPlayer = null
        }
    }
}
