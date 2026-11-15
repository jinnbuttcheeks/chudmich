# Immich Premium (Android fork build)

Branch `premium-ui`, based on upstream `v3.4.1`. Only `mobile/` and one CI workflow change; the server API contract is untouched.

## Design changes

| Area | Change | Files |
| --- | --- | --- |
| Tokens | `PremiumTokens` theme extension: shape radii, 4pt spacing, floating-surface/pill/skeleton colors derived from the active `ColorScheme` (so dynamic color, the primary-color setting and light/dark keep working). `SpringCurve`, `PremiumMotion` (springs, durations, reduced-motion helper) and `SpringRectTween`. Sheets/dialogs rounded, heading tracking tightened, rail styled. | `lib/theme/premium_tokens.dart`, `lib/theme/theme_data.dart` |
| Navigation | Floating, blurred pill bar replaces `NavigationBar`. One spring-driven fractional position drives the sliding/stretching active pill, label reveal and icon cross-fade. Re-tapping mid-flight re-targets the spring and keeps velocity. Light haptic through the existing haptic setting. Bar slides in when it reappears (after multi-select). Landscape keeps the `NavigationRail`, restyled with a pill indicator. The shell uses `extendBody`, so `MediaQuery` bottom padding includes the bar and the timeline, scrubber and multi-select padding adjust automatically. Library, Albums and Search got a trailing `BottomInsetSliver`. | `lib/presentation/widgets/navigation/floating_nav_bar.dart`, `lib/pages/common/tab_shell.page.dart`, `lib/presentation/widgets/common/bottom_inset_sliver.dart` |
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
- Launcher label: "Immich Premium" (`app_name` resource).
- Version: `versionName 3.4.1-premium.1` (the app's `SemVer` parser accepts the suffix and reads 3.4.1, so the server compatibility check is unchanged); `versionCode` = pubspec build number + 1 (3040200).
- Collision audit: the manifest declares no `<provider>`/authorities; services, WorkManager and widget receivers use relative names; plugin authorities derive from `${applicationId}`; no hard-coded package strings in Kotlin. Custom URL schemes (`immich://`, `app.immich:/oauth-callback`) are shared with the official app. OAuth keeps working because the server's redirect URI is fixed at `app.immich:///oauth-callback`; with both apps installed Android may show an app chooser on the OAuth return, pick "Immich Premium".
- Release builds keep falling back to debug signing when `android/key.jks` is missing. Debug-signed APKs cannot be updated by APKs signed with another key; use the same signing path every time.

## Building

Locally (needs the toolchain from `mise.toml` and a few GB of free RAM for Gradle):

    mise //mobile:install:ci
    mise //mobile:codegen
    cd mobile && flutter build apk --release   # build/app/outputs/flutter-apk/app-release.apk

`codegen:native` runs ffigen, which needs `libclang` (Ubuntu: `libclang-dev`).

CI: `.github/workflows/premium-android.yml` runs on `workflow_dispatch` and on `premium-v*` tags, only in `jinnbuttcheeks/immich`. It uploads the APK as the `immich-premium-apk` artifact; on tag pushes it also creates a prerelease named after the tag with the APK attached. Example: `git tag premium-v3.4.1-1 && git push origin premium-v3.4.1-1`.
