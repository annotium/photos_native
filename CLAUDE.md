# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

`photos_native` — Flutter plugin exposing native photo library access (albums, thumbnails, full pixels, save, delete, share, texture experiment) on Android (Kotlin) and iOS (Objective-C). Published on pub.dev. Depends on `permission_handler` for runtime permission requests.

## Commands

Run all commands from repo root unless noted.

```sh
flutter pub get                 # fetch deps
flutter test                    # run dart tests (test/*.dart)
flutter test test/photos_native_test.dart   # single test file
flutter analyze                 # lint (uses flutter_lints via analysis_options.yaml)
```

Example app (for manual verification on device/simulator):
```sh
cd example
flutter pub get
flutter run
```

Android native code lives under `android/src/main/kotlin/...`; open `example/android` in Android Studio to build/debug it directly. iOS native code lives under `ios/Classes`; open `example/ios/Runner.xcworkspace` in Xcode (run `pod install` in `example/ios` first if needed).

There is no dedicated native (Kotlin/XCTest) test suite — native logic is verified through the example app.

## Architecture

Three-layer plugin structure, standard for Flutter federated-style plugins but implemented as a single package with two platform folders:

1. **Dart API surface** (`lib/`)
   - `photos_native.dart` — `FlutterPhotoNative`, the public static API surface apps call.
   - `photos_native_platform_interface.dart` — abstract `PhotosNativePlatform` (the platform interface contract); default instance is `MethodChannelPhotosNative`.
   - `photos_native_method_channel.dart` — concrete implementation that serializes calls over a single `MethodChannel('photos_native')`, handles permission requests (via `permission_handler`) before gallery/photo access, and deserializes codec messages back into typed models.
   - `ph_types.dart` — data models (`PHGallery`, `PHAlbum`, `PHItem`, `PHImageDescriptor`, etc.) with `fromCodecMessage`/`toMessageCodec` (de)serialization matching the native side's `StandardMessageCodec` maps.
   - `ph_version.dart` — `PHVersion` model (app version, build number, `sdkInt` on Android).
   - `constants.dart` — `Functions` (method channel method names), `Arguments` (method channel argument keys), `Keys` (result map keys). **This file is the contract between Dart and both native platforms** — method/argument names here must exactly match the strings used in `MethodCallHandlerImpl.kt`/`PhotosNativePlugin.kt` and `PhotosNativePlugin.m`/`PHManager.m`. When adding a new native call, add the name here first, then wire it on both platforms.
   - `raw_image_provider.dart` — `ImageProvider` that renders a `PHImageDescriptor`'s raw pixel bytes directly (bypasses codec re-encoding).

2. **Android implementation** (`android/src/main/kotlin/dev/annotium/photos_native/`)
   - `PhotosNativePlugin.kt` — `FlutterPlugin`/`ActivityAware` entry point; registers the method channel and dispatches to `MethodCallHandlerImpl`.
   - `MethodCallHandlerImpl.kt` — one function per channel method (`queryAlbums`, `getThumbnail`, `getPixels`, `getBytes`, `save`, `saveFile`, `encode`, `share`, `acquireTexture`, `releaseTexture`), runs work on a coroutine `mainScope` + a bounded `poolDispatcher` thread pool for CPU work, returns results/errors through `ResultHandler`.
   - `PhotoManager.kt` — core native logic: `MediaStore` queries, image decode/encode/resize, save/delete/share. Uses Glide for thumbnail/pixel loading (see `CustomAppGlideModule.kt`).
   - `ContentHelper.kt` — `MediaStore` URI helpers (id ↔ content URI).
   - `PermissionHandler.kt` — Android permission group selection (`READ_MEDIA_IMAGES` on API 33+/Tiramisu vs legacy `READ_EXTERNAL_STORAGE`).
   - `ImageTexture.kt` — backend-texture experiment (GPU-backed `Texture` widget support), tracked by ID in `MethodCallHandlerImpl`'s `textureMap`.
   - `IntentHelper.kt` / `UrlLauncher.kt` — share-sheet intent and URL launching.
   - `PhotosNativeFileProvider.kt` + `res/xml/fileprovider.xml` — FileProvider for sharing files outside the app sandbox.

3. **iOS implementation** (`ios/Classes/`)
   - `PhotosNativePlugin.m` — `FlutterPlugin` entry point, method channel dispatch.
   - `PHManager.m` (+ `PHManagerImpl.m`) — core native logic mirroring `PhotoManager.kt`: `PHAsset`/`PHAssetCollection` queries via Photos framework, image load/encode/resize, save/delete/share.
   - `PHAlbum.m`, `PHImageDescription.m`, `QueryOptions.m` — native model/query-option objects serialized to the method channel codec.
   - `ImageConverter.m` — pixel/format conversion (resize, encode to JPEG/PNG, orientation handling).
   - `ImageTexture.m` — iOS counterpart of the texture experiment (`FlutterTexture`).
   - `ResultHandler.m`, `UrlLauncher.m` — result callback plumbing and URL launching, mirroring the Android classes of the same name.

### Cross-platform contract

Both native sides implement the exact same method-channel surface defined by `lib/constants.dart`. When changing behavior or adding a method:
1. Add/adjust the method name and argument/key constants in `constants.dart`.
2. Add the Dart-facing method to `photos_native_platform_interface.dart` and `photos_native_method_channel.dart`, then expose it as a static method on `FlutterPhotoNative` in `photos_native.dart`.
3. Implement on Android (`MethodCallHandlerImpl.kt` + `PhotoManager.kt`) and iOS (`PhotosNativePlugin.m` + `PHManager.m`) so both platforms agree on argument shape and result map keys.
4. Exercise the change through `example/lib/` (`main.dart`, `gallery.dart`, `photo_grid.dart`, `ph_thumbnail_widget.dart`) since there is no native unit-test harness.

### Permission flow

`requestPermissions()` / any gallery-access call first resolves the platform version (`getVersion()`, cached) to decide the correct `permission_handler` group (Android 13+/Tiramisu uses `Permission.photos`, older Android uses `Permission.storage`, iOS always `Permission.photos`), then requests it. Access is gated by the `allowed` flag on `MethodChannelPhotosNative` — permission is only requested once per session.
