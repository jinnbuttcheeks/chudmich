# Chudmich (Android fork build)

Branch `premium-ui`, based on upstream `v3.4.1`. Only `mobile/` and one CI workflow change; the server API contract is untouched.

## Design changes

| Area | Change | Files |
| --- | --- | --- |
| Tokens | `PremiumTokens` theme extension: shape radii, 4pt spacing, floating-surface/pill/skeleton colors derived from the active `ColorScheme` (so dynamic color, the primary-color setting and light/dark keep working). `SpringCurve`, `PremiumMotion` (springs, durations, reduced-motion helper) and `SpringRectTween`. Sheets/dialogs rounded, heading tracking tightened, rail styled. | `lib/theme/premium_tokens.dart`, `lib/theme/theme_data.dart` |
| Navigation | Floating solid pill bar replaces `NavigationBar` (AIOStreams mobile nav): equal tabs with the icon above a 0.65rem label, a white 10% pill slides under the active tab (200 ms ease-out), inactive tabs are gray-400. The bar slides off the bottom while scrolling down and returns on scroll up (`UserScrollNotification` in the tab shell, `FloatingNavBar.visible`). Light haptic through the existing haptic setting. Landscape keeps the `NavigationRail`, restyled with a pill indicator. The shell uses `extendBody`, so `MediaQuery` bottom padding includes the bar and the timeline, scrubber and multi-select padding adjust automatically. Library, Albums and Search got a trailing `BottomInsetSliver`. | `lib/presentation/widgets/navigation/floating_nav_bar.dart`, `lib/pages/common/tab_shell.page.dart`, `lib/presentation/widgets/common/bottom_inset_sliver.dart` |
| Motion | Tab switch: 280 ms fade plus a 14 px spring rise (was a 600 ms fade). Grid-to-viewer hero uses a spring rect tween on both ends (also on return after swiping to another asset, thanks to the existing per-asset hero tags); viewer route 420/340 ms. When the source tile is off-screen no hero exists and the route fades. | `tab_shell.page.dart`, `thumbnail_tile.widget.dart`, `asset_page.widget.dart`, `routing/router.dart` |
| Micro-interactions | `PressScale` on grid tiles: starts after a 70 ms hold, cancelled by movement beyond touch slop (scrolling never shrinks tiles). Selection check scales in with a spring. Album pull-to-refresh uses theme colors. Every new animation checks `MediaQuery.disableAnimations`. | `presentation/widgets/common/press_scale.dart` |
| Loading | Thumbhash to thumbnail crossfade 100 to 180 ms (instant when motion is reduced); tile skeletons use the shared skeleton tokens. | `thumbnail.widget.dart`, `widgets/asset_grid/thumbnail_placeholder.dart` |

## Performance changes

Profiling was done by reading the code paths (no device profiler on the build box), so numbers below are derived, not measured on a phone.

What upstream 3.4.1 already does well and was left alone: scroll cache of two viewports in the timeline (`scrollCacheExtent: maxHeight * 2`), remote thumbnails decoded at `tile size x devicePixelRatio` through `decodeSize`, request cancellation when the last listener leaves (`ImageLoader.cancel`), a separate small/large `CustomImageCache` so one large image cannot evict thumbnails, and per-tile repaint boundaries.

1. **Viewer preload window** (`asset_preload_window.dart`, `asset_preloader.dart`).
   - Slow: only index +-1 was preloaded, and only 400 ms after the page settled. A swipe-and-swipe-again within about 400 ms started the second image from scratch, and the second asset ahead was never warm.
   - Change: preload 2 ahead and 1 behind relative to the travel direction (mirrored after swiping back), debounce 150 ms. Streams are keyed by asset and only released when they leave the window, so a timeline reload cannot reuse a stale stream.
   - Why it helps: the next image begins loading about 250 ms sooner, and a second consecutive forward swipe finds its image already decoded. Worst case window is current + 3 = 4 entries, within the 5-entry large-image cache. Cost: one more preview request per page change (a preview is typically a few hundred KB).
   - Tested by `test/presentation/widgets/asset_viewer/asset_preload_window_test.dart` (direction, edges, cache budget).
2. **Per-thumbnail decode size, for reference.** A 12 MP original decoded at full size is 4000 x 3000 x 4 B = 48 MB; the tile decode is about 357 x 357 x 4 B (130 dp at 2.75 dpr) = 0.5 MB, roughly 94 times less. This was already in place; the premium work kept it (the hero shuttle reuses the tile's own image, so no larger decode is introduced).
3. **Not changed, deliberately.** Image-cache byte limits (no on-device data to justify a higher memory ceiling) and preloading the adjacent video (upstream intentionally keeps adjacent players from becoming ready; enabling `allowImplicitScrolling` would build neighbour pages, a larger risk than the gain). Both are good next steps once measured with DevTools on a device.

## Packaging (Android)

- `applicationId`: `app.alextran.immich.jinn` (`applicationIdSuffix ".jinn"`; Kotlin `namespace` unchanged). Debug builds become `...jinn.debug`.
- Launcher label: "Chudmich" (`app_name` resource).
- Version: `versionName 3.4.1-chudmich.4` (earlier builds were `premium.1`, `premium.2` and `chudmich.3`; the app's `SemVer` parser accepts the suffix and reads 3.4.1, so the server compatibility check is unchanged, see `test/unit/utils/semver_test.dart`); `versionCode` = pubspec build number + 4 (`3040199 + 4 = 3040203`; premium.1 used +1, premium.2 +2, chudmich.3 +3), so updates install in place.
- Collision audit: the manifest declares no `<provider>`/authorities; services, WorkManager and widget receivers use relative names; plugin authorities derive from `${applicationId}`; no hard-coded package strings in Kotlin. Custom URL schemes (`immich://`, `app.immich:/oauth-callback`) are shared with the official app. OAuth keeps working because the server's redirect URI is fixed at `app.immich:///oauth-callback`; with both apps installed Android may show an app chooser on the OAuth return, pick "Chudmich".
- Release builds fall back to debug signing only when `android/key.jks` is missing (local builds). When the keystore exists, Gradle validates it before any release task runs (`gradle.taskGraph.whenReady` in `app/build.gradle`): it needs `ALIAS`, `ANDROID_KEY_PASSWORD` and `ANDROID_STORE_PASSWORD` (or `key.properties`), opens the PKCS12 store and checks alias and key password, and fails the build with a `GradleException` instead of silently signing with debug.

## Building

Locally (needs the toolchain from `mise.toml` and a few GB of free RAM for Gradle):

    mise //mobile:install:ci
    mise //mobile:codegen
    cd mobile && flutter build apk --release   # build/app/outputs/flutter-apk/app-release.apk

`codegen:native` runs ffigen, which needs `libclang` (Ubuntu: `libclang-dev`).

CI: `.github/workflows/chudmich-android.yml` runs on `workflow_dispatch` and on `chudmich-v*` (and legacy `premium-v*`) tags, only in `jinnbuttcheeks/chudmich`. It uploads the APK as the `chudmich-apk` artifact; on tag pushes it also creates a prerelease titled "Chudmich <version>" (tag minus its prefix, so `chudmich-v3.4.1-4` becomes "Chudmich 3.4.1-4") with `chudmich-<tag>.apk` attached. Example: `git tag chudmich-v3.4.1-4 && git push origin chudmich-v3.4.1-4`.

## Solid design (AIOStreams inspired)

Chudmich 3.4.1-4 removed the frosted glass of earlier builds. The look is now flat and quiet, modeled on the [AIOStreams](https://github.com/Viren070/AIOStreams) web UI. The design lives in `lib/theme/solid/` and `lib/theme/theme_data.dart`. There is no `BackdropFilter` and no `ImageFilter.blur` in the Chudmich layer, and no ambient animated background.

- **Tokens** (`SolidTokens`, `AioPalette`): dark background `#070707`, paper `gray-950`, panels `gray-900`, raised `gray-800`; text `gray-200` with white for emphasis, muted text white at 40% (60% highlighted), inactive navigation `gray-400`; borders white at 10%, subtle fills white at 6% (8% pressed). The accent is AIOStreams violet (brand 500 `#6152DF`, 400 `#9F92FF`, 300 `#C7C2FF`, 200 focus ring); primary buttons use the accent at 70% with a light 20% border. Light mode: white page, gray-800 text, gray-200 borders.
- **Accent settings**: the primary-color presets and dynamic color still work, since the tokens derive from the active `ColorScheme`. The default (indigo) preset is now the violet; `decolorizeSurfaces` maps the neutral surfaces to the palette above.
- **Radii and surfaces**: 8 px for buttons and inputs, 12 px for cards, 20 px for sheets, fully rounded pills and nav. `SolidSurface` is a paper fill with a 1 px hairline; floating bars, sheets and toasts add the pre-baked shadow `0 12px 32px -12px rgb(0 0 0 / 0.7)`. `SolidBar` fades a solid background and hairline in under app bars.
- **Type**: the existing GoogleSans (Inter is not bundled), heavy headings with tight tracking, medium weight labels.
- **Motion**: 200 ms ease-out for slides and color changes, 100 ms fade-outs, a small rise on panel entry (`SolidReveal`), 450 ms emphasized decelerate `cubic-bezier(0.05, 0.7, 0.1, 1)` available for shared elements. The spring motion of earlier builds stays where it feels good (press feedback, tab transition, hero zoom), and everything respects `MediaQuery.disableAnimations`.
- **Screens**: nav bar as described above; Photos keeps the editorial headers and the 3 px grid; Library keeps the bento layout on flat paper cards where only the icon carries color; Albums keeps the full-bleed cover cards with a solid caption; Search and Settings use solid groups with colored icon badges; dialogs, toasts and sheets are solid surfaces.
- **Viewer chrome**: scrim gradients (top) and solid dark capsules (`SolidTokens.overPhoto`, 72% black) over photos and video. No blur sits over a video surface.
- **Performance**: no blur, no saveLayer-heavy effects, pre-baked shadows, a `RepaintBoundary` around the floating bar, no ticker while idle, no per-frame rebuilds on scroll.
- **Remaining blur (upstream, not ours)**: `animated_play_pause.dart` (blurred icon shadow), `slideshow_slide.widget.dart` and `memory_card.widget.dart` (blurred photo behind a letterboxed image). `test/theme/no_blur_test.dart` fails if blur appears anywhere else in `lib`, or at all in the viewer and video code. The `BackdropFilter` that upstream put on the person and album header images was removed.

## Video viewer fixes

Symptom on 3.4.1-chudmich.3: videos were laggy, and swiping past a video got stuck.

1. **Neighbour surface creation** (`lib/presentation/widgets/asset_viewer/video_viewer.widget.dart`, `_surfaceRequested`). The native video view (`PlatformViewsService.initSurfaceAndroidView`, main thread) was created for every built video page, including the neighbour that `PageView` builds as soon as a drag starts, so the swipe itself paid the platform view cost. The surface is now requested only once the page is current (after the scroll settles); the thumbnail stands in until then. Tests: group `paging` in `test/presentation/widgets/asset_viewer/video_viewer_test.dart`.
2. **Position flood** (`lib/providers/asset_viewer/video_player_provider.dart`, `shouldPublishPosition`). The native player polls every 8 ms; each tick rebuilt the slider and time label and restarted the buffering timer. Updates are now published only when the position moved at least 100 ms, and ticks from non-current pages are ignored. Tests: `test/providers/asset_viewer/video_player_provider_test.dart`.
3. **Blur over the video surface.** The viewer capsules used a live `BackdropFilter` over the platform view. Removed with the glass system; `test/theme/no_blur_test.dart` guards it.

### Screenshots

`test/screens/screens_test.dart` renders the redesigned widgets (nav bar, timeline, library, albums, search, settings, dialog, scrubber, viewer chrome over a video frame) over sample data in dark and light, with the real fonts loaded. It is skipped unless `SCREENSHOT_DIR` is set:

    SCREENSHOT_DIR=/tmp/screens-v4 flutter test test/screens

### Release signing

CI (`.github/workflows/chudmich-android.yml`) uses four repository secrets: `PREMIUM_KEYSTORE_B64` (base64 of the PKCS12 `.jks`), `PREMIUM_STORE_PASSWORD`, `PREMIUM_KEY_ALIAS`, `PREMIUM_KEY_PASSWORD`.

- With the keystore secret present: it is decoded to `mobile/android/key.jks` (never echoed), the three env vars Gradle reads (`ALIAS`, `ANDROID_KEY_PASSWORD`, `ANDROID_STORE_PASSWORD`) are set for the build step only, the APK is verified with `apksigner verify --print-certs` (only the SHA-256 digest is printed), and tag pushes publish the prerelease. The keystore is deleted in an `if: always()` step.
- With the secret missing or empty: the APK is still built and uploaded as an artifact, no release is published, and a `::warning::` explains why.
- `key.jks` is gitignored. Never commit a keystore or passwords.

**One-time reinstall:** premium.1 (`premium-v3.4.1-1`) was signed with a throwaway debug key. Every later build uses the permanent key, so premium.1 must be uninstalled once. Later updates install over each other.
