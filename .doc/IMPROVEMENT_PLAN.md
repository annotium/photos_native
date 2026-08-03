# photos_native — Code Quality, Dependency & Improvement Plan

Audit date: 2026-07-27. Scope: `lib/` (Dart API), `android/src/main/kotlin/dev/annotium/photos_native/` (Android), `ios/Classes/` (iOS). Produced via `flutter analyze`, `flutter pub outdated`, and manual + agent-assisted source review.

## 1. Dependency updates

`flutter pub outdated`:

| Package | Current | Latest | Notes |
|---|---|---|---|
| `crypto` | 3.0.6 | 3.0.7 | patch |
| `equatable` | 2.0.7 | 2.1.0 | minor |
| `permission_handler` | 12.0.0+1 | 12.0.3 | patch |
| `flutter_lints` (dev) | 2.0.2 | 6.0.0 | major — will surface new lint violations, budget separate PR |

Other:
- `flutter analyze` reports 1 warning: `lib/raw_image_provider.dart:56` — `override_on_non_overriding_member`. Root cause (corrected after checking the Flutter SDK source directly): the current `ImageProvider` base class declares `loadImage(T key, ImageDecoderCallback decode)` (and a deprecated `loadBuffer`), but has **no** `load` method at all. `loadImage` was the valid override (the `ignore_for_file` masking its warning was stale, likely left over from an older SDK where `loadImage` didn't yet exist); `load` was the dead/non-overriding one. **Fixed**: removed `load`, kept `loadImage`, dropped the ignore comment — `flutter analyze` is now clean.
- Android: `android/build.gradle` pins `compileSdkVersion 35`, AGP 8.7.3, Kotlin 2.0.21. **Target: bump to AGP 9.** `minSdkVersion 16` is a very old floor; confirm intentional since it constrains which APIs can be called unconditionally elsewhere.
- iOS: podspec platform floor is iOS 9.0, but code already branches on `@available(iOS 10.0, *)` and uses modern Photos-framework APIs — floor should be raised (see Action Plan P1).
- Android: Glide is pinned at `4.16.0` in `android/build.gradle:6`. Glide 5.0 is available — researched separately, low risk overall (near-identical API to 4.16, just recompiled against Java 8/Kotlin 1.8; no `RequestListener` usage in this plugin so the 4.16-era nullability annotation change doesn't affect it; `kapt` still supported in Glide 5 via the `com.github.bumptech.glide:compiler` artifact, no forced KSP migration). **One real blocker**: Glide 5 bumped its own floor to API 23 (was 14 in Glide 4) to match AndroidX, which conflicts with this plugin's declared `minSdkVersion 16` — bumping Glide to v5 requires bumping `minSdkVersion` to 23 too, which would break any consumer app still targeting API 16–22.

### AGP 9 migration requirements

Researched against AGP 9.0.1 release notes:

| Requirement | Current | Needed for AGP 9 |
|---|---|---|
| Gradle | (check `example/android/gradle/wrapper/gradle-wrapper.properties`) | ≥ 9.1.0 |
| JDK | 17 (`compileOptions`/`kotlinOptions` already VERSION_17) | ≥ 17 — already satisfied |
| SDK Build Tools | unset/default | ≥ 36.0.0 |
| Kotlin Gradle Plugin | 2.0.21 | ≥ 2.2.10 (auto-upgraded if lower, but bump explicitly) |
| compileSdk | 35 | can stay or raise to 36/36.1 (max supported) |

Breaking changes that hit this plugin directly:
- **Built-in Kotlin is default in AGP 9**; the `apply plugin: 'kotlin-android'` line in `android/build.gradle:24` is no longer compatible with AGP 9's new DSL as-is. Either migrate to AGP's built-in Kotlin support, or set `android.builtInKotlin=false` in `gradle.properties` as a temporary opt-out — **but opt-out is removed in AGP 10 (mid-2026)**, so opt-out only buys a short runway.
- **`kapt` conflicts with built-in Kotlin.** This plugin applies `apply plugin: 'kotlin-kapt'` and uses `kapt "com.github.bumptech.glide:compiler:$glide_version"` (`android/build.gradle:26,50`) for Glide's annotation processor. This must be migrated to **KSP** (Kotlin Symbol Processing) — Glide supports a KSP compiler artifact — since kapt is the piece most likely to break the build under AGP 9's built-in Kotlin.
- **Namespace must be declared directly on the library.** `android/build.gradle` currently has no `namespace` block — namespace is only injected indirectly via `example/android/build.gradle`'s `subprojects { afterEvaluate { ... if (namespace == null) namespace project.group } }` hack, which reads the plugin's `group 'dev.annotium.photos_native'` from the buildscript header. This only works because the example app's root `build.gradle` carries that shim; a downstream consumer app without it (i.e. any real pub.dev consumer) has no namespace source for AGP 9's stricter check. Add `android { namespace 'dev.annotium.photos_native' }` to `android/build.gradle` directly and drop reliance on the example app's shim.
- Old variant APIs (`applicationVariants`, `variantFilter`) are removed in favor of `androidComponents.onVariants()`/`beforeVariants()` — not currently used by this plugin, no action needed.
- `dexOptions`, Wear OS `wearApp`, `deviceProvider`/`testServer` removed — not used here, no action needed.

## 2. Code quality issues — iOS (`ios/Classes/`)

**Bugs (real, not style):**
- `PHManagerImpl.m:41-46` — sort comparator returns a `BOOL` (`count0 < count1`) where an `NSComparisonResult` is required. Confirmed in source: `return count0 < count1;` inside `sortUsingComparator:`. This is undefined/incorrect sort behavior, not a style nit.
- `PHManager.m:316-334` (`getPixels:maxWidth:...`), `:348-352` (`getAssetDataWithId`), `:278-294` (`getThumbnail`) — no reply/error call on nil result (e.g. iCloud fetch failure) → the Dart-side future hangs forever with no timeout.
- `ImageTexture.m:41-42` — `@property (nonatomic, assign) UIImage* image;` should be `strong`. Confirmed: `assign` on an Objective-C object property means no retain — the backing `UIImage` can be deallocated out from under the texture, causing a dangling pointer read in the pixel-buffer path.

**Threading:**
- `PHManager.m:298-300,550-552` vs `:274,521` — `_cachedAssets` (`NSMutableSet`) is written on the main queue and read on a background operation queue with no synchronization — race condition.
- `PHManager.m:483-497` — a `usleep(20000)` retry loop blocks a shared `NSOperationQueue` worker thread instead of retrying asynchronously; can starve the queue under load.

**Error handling / security:**
- `PHManager.m:362,379` — `getPixelsDataFromUrl:` / `getPixelsFromUrl:` read an arbitrary path from Dart-supplied arguments and call `contentsAtPath:` directly with no sandbox containment check — potential arbitrary file read if the URI argument is ever attacker-influenced (e.g. a compromised WebView or deep link feeding into this plugin).
- `PhotosNativePlugin.m:134-138` — an app-group `NSUserDefaults` key is derived directly from an incoming URL host with no validation before the stored value is treated as a trusted path.

**Deprecated / dead code:**
- `PHManager.h:35-36` — `getThumbnail:` / `getBytes:` are marked deprecated but still wired with no documented migration path for consumers.
- `UrlLauncher.m:32-46` — unreachable pre-iOS-10 `openURL:` fallback given the actual supported runtime; dead code.
- `PHManager.m:523-538` — large commented-out block; delete.
- Stray `//NSLog` remnants at `PHManager.m:253,413,418,470,504`.

**Memory:**
- No `autoreleasepool` around per-asset decode loops in `getThumbnail` / `getPixels` / `loadImageWithId` batch paths — can build up autoreleased `UIImage`/`CGImage` memory before the pool drains.
- `PHManager.m:76-78` — `dealloc` doesn't unregister the `PHPhotoLibraryChangeObserver`. Latent today since `PHManager` is a singleton for the app's lifetime, but worth guarding.

## 3. Code quality issues — Android (`android/src/main/kotlin/dev/annotium/photos_native/`)

**Bugs (real):**
- `PhotosNativePlugin.kt:305-311` (`LAUNCH_URL` handler) — confirmed in source:
  ```kotlin
  Constants.Functions.LAUNCH_URL -> {
    val url = call.argument<String>(Constants.Arguments.URL)
    if (url.isNullOrEmpty()) {
      result.success(false)
    }
    val urlLauncher = UrlLauncher()
    urlLauncher.launch(activity, url, null)
    result.success(true)
  }
  ```
  The `if` branch calls `result.success(false)` but does not `return`, so execution falls through to launch with a null/empty URL and call `result.success(true)` a second time on the same channel result. Flutter throws on a second reply to the same `MethodChannel.Result` — **this is a live crash bug** whenever `launchUrl` is called with an empty/null URL. Highest-priority fix.
- `PermissionHandler.kt:32,36` — single-callback field is overwritten if `requestPermissions` is called again before the first result returns; the second call silently drops the first caller's callback.

**Error handling gaps:**
- `PhotosNativePlugin.kt:227,242-245,259-262,279-285,299-301` — repeated `!!` force-unwraps on method-call arguments (`ids`, `data`, `width`, `height`, `mime`); a malformed call from Dart throws an uncaught `NullPointerException` instead of a clean `PlatformException` reply.
- `ResultHandler.kt:26-27,42-44` — `success`/`error` wrap all exceptions in an empty `catch` block, silently hiding real bugs (e.g. "reply already submitted", which is exactly what the `launchUrl` bug above would otherwise surface as).
- `PhotosNativeHelper.kt:20-26` — `clearCachePath` swallows all exceptions with an empty catch block and no logging.
- Errors across `PhotoManager.kt` / `DeleteResultListenerHandle.kt` are consistently flattened to `Constants.Errors.UNKNOWN` plus a stringified exception, losing structured error info Dart-side callers could branch on.

**Threading:**
- `DeleteResultListenerHandle.kt:44` — launches an un-scoped `CoroutineScope(Dispatchers.IO)` with no lifecycle tie or cancellation; leaks if the activity is destroyed mid-delete.
- `PhotosNativePlugin.kt:33-34` — `_mediaStoreChanged` / `_memoMap` are plain mutable fields with no synchronization despite being reachable from concurrent method-channel calls; `getMemo` (`:412-419`) has surprising consume-once semantics (removes the key on read) that is undocumented.
- `ImageTexture.kt:23-39` — `post()` / `dispose()` race: the `surface` field can be nulled between the null-check and its use (TOCTOU) if called from different threads concurrently.

**Deprecated / redundant:**
- `PhotosNativeHelper.kt:32-34` — `Environment.getExternalStorageDirectory()` is deprecated and effectively broken under scoped storage (API 29+), still used behind `@Suppress("DEPRECATION")`.
- `PhotosNativePlugin.kt:382-383` — reinvents version-code compat logic instead of reusing the existing `PhotosNativeExtensions.getPackageInfoCompat`.
- Dead/commented-out code: `ImageTexture.kt:14,18,50-53` (old bitmap field/recycle logic), `ResultHandler.kt:10`, `PhotoManager.kt:50-66,437-458` (commented-out `loadImageBytes` / `scanFilePath`).

## 4. Dart layer issues

- `raw_image_provider.dart:56` — see dependency section above (dead `load` override, since fixed).
- Test coverage gaps:
  - Zero tests of `ph_types.dart` codec round-tripping (`PHGallery`, `PHAlbum`, `PHImageDescriptor`, `PHItem`, `PHVersion` `fromCodecMessage`), including malformed-message handling.
  - `photos_native_method_channel_test.dart` mock handler returns a constant value regardless of method name/args — doesn't exercise `save`, `delete`, `getPixels`, `getThumbnail`, `acquireTexture`, or `PlatformException` propagation.
  - `photos_native_test.dart` only exercises `getPlatformVersion`; every other static method on `FlutterPhotoNative` is untested.
  - The SDK-version-based permission-group selection logic in `photos_native_method_channel.dart` (Android 13+/Tiramisu → `Permission.photos`, older → `Permission.storage`) has no test coverage at all.

## 5. Prioritized action plan

**P0 — real bugs, fix first**
1. `PhotosNativePlugin.kt:305-311` — add `return@setMethodCallHandler` (or restructure with early `return`) after `result.success(false)` in the `LAUNCH_URL` branch to stop the double-reply crash.
2. `PHManagerImpl.m:41-46` — fix comparator to return `NSOrderedAscending` / `NSOrderedDescending` / `NSOrderedSame` instead of a `BOOL`.
3. iOS `getPixels` / `getAssetDataWithId` / `getThumbnail` — add an explicit error reply on the nil-result path so the Dart future never hangs.
4. `ImageTexture.m:41` — change `image` property from `assign` to `strong`.

**P1 — dependency & lint modernization**
1. Bump `crypto`, `equatable`, `permission_handler` to latest resolvable versions.
2. Upgrade `flutter_lints` 2.0.2 → 6.0.0 in a dedicated PR; fix newly surfaced lints separately from behavior changes.
3. Remove the dead `load` override in `raw_image_provider.dart` (keep `loadImage`), delete the associated `ignore_for_file`. **Done.**
4. Raise iOS deployment target from 9.0 to 12+ and remove the now-dead pre-iOS-10 `openURL:` branch in `UrlLauncher.m`. **Done.**
5. **Bump to AGP 9.** **Done and verified** — `./gradlew assembleDebug` succeeds from `example/android` after the following changes:
   - `example/android/gradle/wrapper/gradle-wrapper.properties` → Gradle `9.1.0`.
   - `android/build.gradle`: AGP classpath → `9.0.1`, `kotlin_version` → `2.2.10`, added explicit `namespace 'dev.annotium.photos_native'` inside `android { }` (no longer relies on `example/android/build.gradle`'s `subprojects`/`afterEvaluate` namespace shim for the plugin itself).
   - `example/android/settings.gradle`: bumped the `com.android.application` and `org.jetbrains.kotlin.android` plugin versions to match (`9.0.1` / `2.2.10`).
   - `example/android/app/build.gradle`: added explicit `namespace 'dev.annotium.photos_native_example'` — AGP 9 **no longer reads `namespace` from the manifest's `package` attribute at all** (this hit even though the app already had a namespace source; not just a library-only requirement as originally assumed).
   - `example/android/app/src/main/AndroidManifest.xml`: removed the now-rejected `package="dev.annotium.photos_native_example"` attribute (AGP 9 fails the build if it's present).
   - `example/android/gradle.properties`: added `android.builtInKotlin=false` **and** `android.newDsl=false`. Both were required — `builtInKotlin=false` alone was not enough; without `newDsl=false` too, applying the `kotlin-android` plugin threw `ClassCastException: ApplicationExtensionImpl$AgpDecorated_Decorated cannot be cast to BaseExtension`, because the new DSL's extension type is incompatible with what `kotlin-android` expects regardless of the built-in-Kotlin setting. These two opt-outs cover the remaining `kotlin-android` plugin usage (see item 7 below for kapt, which no longer needs an opt-out) and stay necessary until the plugin fully adopts AGP 9's built-in Kotlin (removes `apply plugin: 'kotlin-android'` entirely) — a further follow-up, since these opt-outs disappear in AGP 10 (mid-2026).
   - Also bumped `example/android/gradle.properties`' `org.gradle.jvmargs` from `-Xmx1536M` to `-Xmx4096M` — unrelated to AGP 9 itself, but the Jetifier transform step ran out of heap at the old value during verification and needed more memory to complete.
   - `compileSdkVersion` bumped 35 → 36 (AGP 9's max supported). **Done and verified.**
6. **Bump Glide 4.16.0 → 5.0.4** in `android/build.gradle:6` (`glide_version`), plus **bump `minSdkVersion` 16 → 23** in the same file — Glide 5 raised its own floor to API 23 to match AndroidX. **Done and verified**: `./gradlew assembleDebug` succeeds. This is a breaking change for any consumer app that was still targeting API 16–22; call it out explicitly in the changelog/release notes when publishing.
7. **Migrate Glide's annotation processor from kapt to KSP** in `android/build.gradle`. **Done and verified.** No source changes needed — the codebase only calls `Glide.with(context)` directly, never the deprecated generated `GlideApp`/`GlideRequests` builder API that KSP doesn't support (confirmed via grep before migrating). Changes:
   - Dropped `apply plugin: 'kotlin-kapt'`, added `apply plugin: 'com.google.devtools.ksp'`.
   - Added `classpath "com.google.devtools.ksp:com.google.devtools.ksp.gradle.plugin:$ksp_version"` to `buildscript.dependencies`, with `ksp_version = '2.2.10-2.0.2'` (KSP release matched to the project's Kotlin `2.2.10`).
   - Swapped `kapt "com.github.bumptech.glide:compiler:$glide_version"` → `ksp "com.github.bumptech.glide:ksp:$glide_version"`; dropped the redundant `annotationProcessor "...compiler:..."` line (Java-only, a no-op in this pure-Kotlin module).
   - Verified with `./gradlew clean assembleDebug`: `kspDebugKotlin` runs (no `kaptDebugKotlin` task at all after a clean build) and correctly regenerates `com.bumptech.glide.GeneratedAppGlideModuleImpl` from the existing `CustomAppGlideModule`/`@GlideModule` setup — confirmed the generated class exists in both `generated/ksp/.../GeneratedAppGlideModuleImpl.kt` and the final compiled/dexed output.
   - Note: `apply plugin: 'kotlin-android'` is still applied (not migrated to AGP 9's fully built-in Kotlin), so the `android.builtInKotlin=false`/`android.newDsl=false` opt-outs in item 5 are still required — this item only removed kapt's *own* incompatibility with built-in Kotlin, not `kotlin-android`'s.
8. **Attempted: drop `kotlin-android` entirely for AGP 9's built-in Kotlin, removing both opt-outs.** **Tried and reverted — currently blocked, not viable.** Removed `apply plugin: 'kotlin-android'`, the `kotlin-gradle-plugin` classpath, `kotlinOptions` blocks, and the `sourceSets { main.java.srcDirs += 'src/main/kotlin' }` line from both `android/build.gradle` (the plugin) and `example/android/app/build.gradle` (the example app), and removed the `org.jetbrains.kotlin.android` plugin declaration from `example/android/settings.gradle`. Two independent blockers surfaced when rebuilding:
   - With `android.newDsl=false` removed: Flutter's own `dev.flutter.flutter-gradle-plugin` throws `ClassCastException: ApplicationExtensionImpl$AgpDecorated_Decorated cannot be cast to AbstractAppExtension` — Flutter's Gradle tooling itself isn't updated for AGP 9's new DSL yet. Nothing in this repo can fix that.
   - With `android.newDsl=false` restored but `android.builtInKotlin=false` removed: Flutter's tooling NPEs in `FlutterPluginUtils.getLegacyAndroidExtension` (called from `getCompileSdkFromProject`), **and** the `permission_handler_android` plugin — a transitive dependency pulled in via `permission_handler` from pub.dev, not part of this repo — still applies `kotlin-android` itself in its own build, which then fails with `'kotlin-android' plugin requires one of the Android Gradle plugins` due to plugin-application ordering under built-in Kotlin.
   - **Conclusion**: both opt-outs (`android.builtInKotlin=false`, `android.newDsl=false`) must stay in `example/android/gradle.properties` for now — this is blocked on Flutter's own SDK/Gradle tooling being updated for AGP 9, and on third-party pub.dev plugins in the dependency tree (at least `permission_handler`) migrating off `kotlin-android` themselves. Revisit this once Flutter's stable channel ships AGP-9-compatible Gradle tooling; don't retry blindly before then. All changes from this attempt were reverted; the working state is `kotlin-android` + KSP (item 7) + both opt-outs (item 5).

**P2 — error handling & robustness**
1. Replace `!!` force-unwraps in `PhotosNativePlugin.kt` argument parsing with explicit null checks that reply `PlatformException` (bad-arguments error) instead of crashing.
2. Stop silently swallowing exceptions in `ResultHandler.kt` and `PhotosNativeHelper.kt` — at minimum log them.
3. Fix `PermissionHandler.kt`'s single-callback overwrite (queue concurrent requests or reject the second with a clear error).
4. Add synchronization (or explicitly document a single-thread-only contract) for `PhotosNativePlugin.kt`'s `_memoMap` / `_mediaStoreChanged`; document (or reconsider) `getMemo`'s consume-on-read behavior.
5. Fix the `ImageTexture.kt` `post()` / `dispose()` TOCTOU race.
6. Tie `DeleteResultListenerHandle.kt`'s coroutine scope to a cancellable lifecycle.

**P3 — security hardening**
1. Add path containment/sanitization to iOS `getPixelsDataFromUrl:` / `getPixelsFromUrl:` before calling `contentsAtPath:`.
2. Validate the URL-derived key in `PhotosNativePlugin.m:134-138` before trusting the value read from `NSUserDefaults`.

**P4 — dead code cleanup** (low risk, bundle with the above)
- Remove commented-out blocks in `PHManager.m`, `PhotoManager.kt`, `ImageTexture.kt`, `ResultHandler.kt`.
- Remove stray `NSLog` / debug remnants in `PHManager.m`.

**P5 — test coverage**
1. Add `ph_types.dart` codec round-trip tests (encode → decode → equality), including malformed/missing-key inputs.
2. Extend `photos_native_method_channel_test.dart` with per-method mock responses and at least one `PlatformException` propagation test.
3. Add tests for the SDK-version-based permission group selection logic in `photos_native_method_channel.dart`.

**P6 — Swift Package Manager support (iOS)**

**Done and verified** (both CocoaPods and SPM build paths). This was not in the original audit; added on request.

1. Moved all iOS sources from `ios/Classes/` to the SPM-required layout: headers under `ios/photos_native/Sources/photos_native/include/photos_native/`, implementation files under `ios/photos_native/Sources/photos_native/`. `ios/Classes/` no longer exists.
2. Added `ios/photos_native/Package.swift` — target name `photos_native`, iOS 13.0 platform floor (matches the podspec, see P1 item 4), depends on Flutter's local `FlutterFramework` SPM package (the standard Flutter-managed reference, not a real path in this repo — Flutter's tooling resolves it), `cSettings.headerSearchPath("include/photos_native")` for same-directory-style `#import` statements to keep working unchanged.
3. Updated `ios/photos_native.podspec`'s `source_files`/`public_header_files` to point at the new location — CocoaPods and SPM now share the same source files, no duplication.
4. **Found and fixed two real latent header bugs surfaced by SPM's stricter per-target compilation** (both existed before this change, just silently tolerated by CocoaPods' looser umbrella-module compilation):
   - `ImageConverter.h` used `UIImage`, `CGRect`, etc. without importing `UIKit/UIKit.h` — added the import.
   - `Constants.h` used `NSString*` throughout without importing `Foundation/Foundation.h` at all — added the import.
5. Verified both build paths from a clean state on the example app:
   - SPM: `flutter config --enable-swift-package-manager` → `flutter clean` → `flutter build ios --simulator --no-codesign` → succeeds (`✓ Built build/ios/iphonesimulator/Runner.app`). Flutter warns that `permission_handler_apple` (a different, third-party pub.dev plugin) doesn't support SPM yet — that's on its own maintainers, not actionable here.
   - CocoaPods: `flutter config --no-enable-swift-package-manager` → `flutter clean` → `flutter build ios --simulator --no-codesign` → succeeds.
6. **Note on example-app project churn**: the first `flutter build ios` after enabling SPM auto-migrates the consuming app's Xcode project (`project.pbxproj`, `Podfile`, `AppFrameworkInfo.plist`, UIScene lifecycle migration, etc.) — this is Flutter's own one-way project modernization, independent of this plugin, and happens for any sufficiently old Flutter iOS project. Those incidental changes were reverted after verification to keep this change scoped to the plugin's own SPM support; only `example/ios/Podfile.lock`'s checksum line changed for real (expected — the podspec's `source_files`/`public_header_files` paths changed, so its checksum did too).
