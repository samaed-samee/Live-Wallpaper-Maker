# Live Wallpaper Maker

A powerful Android application that allows users to set their favorite MP4 videos as live wallpapers. Built with a **Flutter UI** for easy configuration and a **Native Kotlin WallpaperService** for high-performance, battery-efficient rendering.

## Features

- 🎥 **Video Support**: Pick any MP4 video from your device storage.
- 👁️ **Preview System**: Preview your video loop before applying it.
- ⚡ **Performance Optimized**: Uses Android's native `MediaPlayer` and `SurfaceHolder` for hardware-accelerated rendering.
- 🔋 **Battery Smart**: Automatically pauses rendering when the screen is off or the wallpaper is hidden behind other apps.
- 🛠️ **Native Implementation**: Leveraging `MethodChannel` to communicate between Flutter and Android Native layers.

## Architecture

This project uses a hybrid architecture:

1.  **Flutter (UI Layer)**:
    -   Handles User Interaction (Video Picking, Settings).
    -   Manages Permissions.
    -   Communicates with Native Android via `MethodChannel`.

2.  **Kotlin (Native Layer)**:
    -   `VideoWallpaperService`: Extends Android's `WallpaperService`.
    -   Renders video directly to the Wallpaper Surface.
    -   Manages Lifecycle events to save battery.

## Getting Started

### Prerequisites

-   Flutter SDK installed.
-   Android SDK (API 26+).
-   Android Device or Emulator (Note: Some emulators struggle with Live Wallpapers).

### Installation

1.  Clone the repository:
    ```bash
    git clone https://github.com/yourusername/live_wallpaper.git
    ```
2.  Install dependencies:
    ```bash
    flutter pub get
    ```
3.  Run the app:
    ```bash
    flutter run
    ```

## Usage

1.  Open the app.
2.  Grant **Storage/Video** permissions when prompted.
3.  Tap **"Pick Video"** to select an MP4 file.
4.  Verify the video in the **Preview Screen**.
5.  Tap **"Set as Wallpaper"**.
6.  In the System Wallpaper Picker, tap **"Set Wallpaper"** and choose "Home Screen" or "Home and Lock Screen".

## Permissions

The app requires the following permissions in `AndroidManifest.xml`:
-   `READ_MEDIA_VIDEO` / `READ_EXTERNAL_STORAGE`: To access video files.
-   `BIND_WALLPAPER`: To act as a live wallpaper service.
