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
- Version: `versionName 3.4.1-premium.2` (premium.1 was the first pass) (the app's `SemVer` parser accepts the suffix and reads 3.4.1, so the server compatibility check is unchanged); `versionCode` = pubspec build number + 2 (`3040199 + 2 = 3040201`; premium.1 used +1 = 3040200).
- Collision audit: the manifest declares no `<provider>`/authorities; services, WorkManager and widget receivers use relative names; plugin authorities derive from `${applicationId}`; no hard-coded package strings in Kotlin. Custom URL schemes (`immich://`, `app.immich:/oauth-callback`) are shared with the official app. OAuth keeps working because the server's redirect URI is fixed at `app.immich:///oauth-callback`; with both apps installed Android may show an app chooser on the OAuth return, pick "Immich Premium".
- Release builds fall back to debug signing only when `android/key.jks` is missing (local builds). When the keystore exists, Gradle validates it before any release task runs (`gradle.taskGraph.whenReady` in `app/build.gradle`): it needs `ALIAS`, `ANDROID_KEY_PASSWORD` and `ANDROID_STORE_PASSWORD` (or `key.properties`), opens the PKCS12 store and checks alias and key password, and fails the build with a `GradleException` instead of silently signing with debug.

## Building

Locally (needs the toolchain from `mise.toml` and a few GB of free RAM for Gradle):

    mise //mobile:install:ci
    mise //mobile:codegen
    cd mobile && flutter build apk --release   # build/app/outputs/flutter-apk/app-release.apk

`codegen:native` runs ffigen, which needs `libclang` (Ubuntu: `libclang-dev`).

CI: `.github/workflows/premium-android.yml` runs on `workflow_dispatch` and on `premium-v*` tags, only in `jinnbuttcheeks/immich`. It uploads the APK as the `immich-premium-apk` artifact; on tag pushes it also creates a prerelease named after the tag with the APK attached. Example: `git tag premium-v3.4.1-1 && git push origin premium-v3.4.1-1`.

## Liquid Glass (premium.2)

premium.2 replaces the stock Material look with a glass language. All of it lives in `lib/theme/glass/` and is applied from there, with no scattered blur code.

### Design language

- **Material** (`GlassSurface`, `GlassBar`): `BackdropFilter` blur (sigma about 18 to 30 by variant) composed with a saturation and brightness `ColorFilter.matrix`, a theme-derived tint, a specular rim (gradient stroke, brightest where the light hits), an inner glow, an outer shadow painted only outside the shape (so the backdrop is not muddied), and squircle geometry (`RoundedSuperellipseBorder`). Variants: `thin` (chips, buttons), `regular` (bars, cards), `thick` (sheets, dialogs, details), `lens` (the nav active pill). Light and dark specs come from `GlassSpec.of(variant, brightness)`.
- **Light-reactive shimmer**: the rim direction follows a light `Offset` supplied by `GlassLightScope`. It is driven by scroll (`GlassLightScrollDriver`, `GlassMath.lightFromScroll`) or by tab position (`lightFromTab`). Device tilt is not implemented: no sensor package is in the dependency tree.
- **Ambient background** (`AmbientBackground`): three slowly drifting radial blobs derived from the theme (so dynamic color and the primary-color setting still apply), rendered at about 20 fps from a single `Ticker`, inside a `RepaintBoundary`. It pauses when `TickerMode` is off (route obscured) or `MediaQuery.disableAnimations` is on.
- **Tokens** (`GlassTokens`): tint, highlight, ink, canvas and blob colors per brightness. The dark palette is a deep ink-blue, the light palette a cool porcelain. `ThemeData` also restyles bottom sheets, snackbars, app bars, popup menus, dialogs, inputs, chips and all button types.
- **Type scale**: larger display and headline sizes with tight tracking; titles collapse into the glass app bar (`ImmichSliverAppBar.largeTitle`).
- **Motion**: springs for press, tab switch, chip select, viewer chrome (`GlassReveal`) and sheets. Everything checks `MediaQuery.disableAnimations` and degrades to instant or fade.

### Per-screen changes

| Screen | Change |
| --- | --- |
| Tab bar | True glass capsule; a glass `lens` pill slides under the active tab and its icon scales up; the light sweeps with tab position. |
| App bars | Transparent sliver app bar with a glass background that condenses on scroll and a large title that collapses. |
| Photos | Editorial headers (large month, secondary year, item count; day headers with an accent bar and count), glass scrubber thumb, glass date bubble and year chips, 3 px grid spacing with rounded tiles. |
| Library | Bento dashboard: Favorites hero, Archive and Shared links stack, wide People card with an avatar stack, Places, Device, Memories, Trash when enabled; a glass group for Folders, Locked, Partners. |
| Albums | Full-bleed cover cards with a frosted caption, glass filter chips, glass grid/list toggle, translucent sort menu, glass list tiles. |
| Search | Large title, glass field, glass filter chips, people rail and a 2x2 grid of glass quick links on the suggestions screen. |
| Viewer | Floating glass capsules (back, date, actions, bottom action bar) with spring show/hide on tap; thick glass details sheet. |
| Multi-select / sheets | Base bottom sheet is a glass surface that bleeds under the screen edge. |
| Settings | Large title, profile header card, inset glass groups with coloured icon badges. |
| Dialogs, toasts, profile | `ConfirmDialog`, the account dialog and toasts are thick glass. |
| Login | Glass card over the ambient background. |

### Performance guardrails

- `GlassLayerBudget` caps live `BackdropFilter` layers at 4. A surface that cannot get a slot, is hidden (`TickerMode` off) or runs under high contrast falls back to fake glass: a denser static tint with no blur. Surfaces marked `essential` (sheets, dialogs, toasts, the nav bar) always get a slot.
- No blur per grid tile or scrolling card: album cards, bento cards and scrubber thumbs use fake glass. Bars only take a budget slot once condensed.
- Every glass surface and the ambient field sit in a `RepaintBoundary`.
- `BackdropGroup` was evaluated and not used: the filters do not overlap and the saving is small.
- The preload window and decode sizes described above are untouched.
- Numbers are not measured on a device; profile with DevTools before tuning sigma or the budget.
- Tests: `test/theme/glass/glass_test.dart` covers the saturation matrix, shimmer math, variant ordering, budget grant/release, and ambient bounds. `test/flutter_test_config.dart` disables the ambient animation so `pumpAndSettle` settles.

### Release signing

CI (`.github/workflows/premium-android.yml`) uses four repository secrets: `PREMIUM_KEYSTORE_B64` (base64 of the PKCS12 `.jks`), `PREMIUM_STORE_PASSWORD`, `PREMIUM_KEY_ALIAS`, `PREMIUM_KEY_PASSWORD`.

- With the keystore secret present: it is decoded to `mobile/android/key.jks` (never echoed), the three env vars Gradle reads (`ALIAS`, `ANDROID_KEY_PASSWORD`, `ANDROID_STORE_PASSWORD`) are set for the build step only, the APK is verified with `apksigner verify --print-certs` (only the SHA-256 digest is printed), and tag pushes publish the prerelease. The keystore is deleted in an `if: always()` step.
- With the secret missing or empty: the APK is still built and uploaded as an artifact, no release is published, and a `::warning::` explains why.
- `key.jks` is gitignored. Never commit a keystore or passwords.

**One-time reinstall:** premium.1 was signed with a throwaway debug key. premium.2 and later use the permanent key, so premium.1 must be uninstalled once before installing premium.2. Later updates install over each other.

### Screenshots

`test/screens/screens_test.dart` renders the redesigned widgets over sample data (dark and light) with the real fonts loaded. It is skipped unless `SCREENSHOT_DIR` is set:

    SCREENSHOT_DIR=/workspace/builds/immich-premium/screens flutter test test/screens
