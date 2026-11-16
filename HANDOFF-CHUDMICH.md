# HANDOFF-CHUDMICH

Status: in progress (Chudmich v4). Repo jinnbuttcheeks/chudmich, branch `premium-ui`. A Cursor (or any) agent can resume from this file alone.

## Goal

Chudmich v4 (Android Flutter app in `mobile/`): (A) fix video lag and stuck swipes in the asset viewer, (B) remove all frosted glass and the ambient gradient, replace with a solid AIOStreams-inspired UI, (C) bump to `3.4.1-chudmich.4` and update docs. Full brief below.

## AIOStreams design findings & tokens

Reference: github.com/Viren070/AIOStreams, `packages/web` (shell, nav, styles.css) and `packages/ui` (theme.css, tailwind-preset.ts, components).

- Dark background `#070707`; paper/cards gray-950 rgb(11,11,11); deep panels gray-900 rgb(16,16,16); gray-800 rgb(28,28,28).
- Foreground gray-200 rgb(209,209,209), white for emphasis; muted text white@40%, muted-highlight white@60%; inactive nav gray-400 rgb(143,143,143).
- Borders white@10%. Subtle fills white@6% (hover/pressed 8%).
- Brand violet: 500 rgb(97,82,223), 400 rgb(159,146,255), 300 rgb(199,194,255), 200 rgb(212,208,255), 600 rgb(82,67,203), 700 rgb(63,46,178). Primary button: brand-500 ~70% opacity, brand-400@20% border, white text.
- Radii: 8 px buttons/inputs, 12 px cards (1 px border, paper bg, shadow-sm), pills/nav fully rounded.
- Solid surface: page background, 1 px border white@10%, shadow `0 12px 32px -12px rgb(0 0 0 / 0.7)`. No blur.
- Nav: floating fully-rounded bar, centered, 12 px from edges, 6 px inner padding, 4 px gap, max width ~448 px; icon above a 0.65rem label; active tab = white@10% pill with white text; inactive gray-400; hides on scroll down (translateY 100%, 200 ms ease-out), returns on scroll up.
- Pill tabs: gray-900 rounded-full track, p-1 gap-1, selected pill white with dark text.
- Motion: short and functional. 200 ms ease-out slides; 450 ms cubic-bezier(0.05, 0.7, 0.1, 1) for shared-element transitions; 0.5rem rise on panel entry; 100 ms fade-outs; half-speed parallax on detail pages.

## Done

- Handoff file created.
- Task A diagnosis (goldfish + elephant) and fixes 1 and 2 below, with tests.

## In progress

- Task A fix 3 (viewer chrome blur) is folded into Task B: the glass capsules over the video are removed with the glass system.

## Next steps

1. Task A: diagnose (goldfish + elephant), failing tests, fixes.
2. Task B: delete `lib/theme/glass/` and ambient background, solid tokens, nav, viewer chrome.
3. Task C: version bump and docs.
4. Screenshots harness, precommit review, final handoff update.

## Video root-cause notes

Goldfish (symptom only) ranked: (1) live `BackdropFilter` glass capsules in the viewer top/bottom bars over the Android platform-view video surface, (2) native 8 ms position poll flooding Dart with ~125 channel calls/s plus platform-view lifecycle cost, (3) glass/ambient overhead (weak). Elephant (code reading) ranked: (1) `NativeVideoPlayerView` platform view created for every built video page, including the neighbour page that PageView builds as soon as a drag starts, (2) glass blur over the surface, (3) ambient ticker. Converged on the glass blur; the goldfish missed the neighbour-surface creation, the elephant missed the 8 ms poll. Both are real, so all are fixed.

1. Neighbour surface creation (`lib/presentation/widgets/asset_viewer/video_viewer.widget.dart`, `_surfaceRequested`): the Android view is created via `PlatformViewsService.initSurfaceAndroidView` (main-thread) when the page is built mid-drag, and disposed when the page leaves. Fix: only request the surface once the page is current (current flips on scroll end, see `_onScrollEnd` in `asset_viewer.page.dart`); the thumbnail stands in until then. Tests: `test/presentation/widgets/asset_viewer/video_viewer_test.dart` group `paging` (red before the fix, green after).
2. Position flood (`lib/providers/asset_viewer/video_player_provider.dart`, `shouldPublishPosition`, plus `!widget.isCurrent` early return in `_onPlaybackPositionChanged`): native poll runs every 8 ms; each change rebuilt the slider and time label and restarted the buffering timer. Fix: publish only when the position moved >= 100 ms, ignore ticks from non-current pages. Tests: `test/providers/asset_viewer/video_player_provider_test.dart`.
3. Glass blur over video (viewer bars use `GlassSurface` with `BackdropFilter`): removed with the glass system in Task B. A test asserting no `BackdropFilter` in the viewer chrome lands with it.

## Test commands

Toolchain is mise per `mobile/mise.toml` (Flutter 3.47.2, Java 21). From `mobile/`:

    flutter analyze                       # must show "No issues found"
    flutter test                          # full suite
    SCREENSHOT_DIR=/tmp/screens-v4 flutter test test/screens   # screenshot harness (do not commit PNGs)
    dart format <changed files only>
    rg -n "BackdropFilter|ImageFilter.blur" mobile/lib         # must show nothing from our layer

## Version & tag plan

versionName `3.4.1-chudmich.4`, versionCode `3040203` (pubspec build number + 4 in `mobile/android/app/build.gradle`). Tag `chudmich-v3.4.1-4` is pushed by the supervisor, not the agent. CI (`.github/workflows/chudmich-android.yml`) builds and signs the APK on tag push, so no local APK build is needed. Remaining for supervisor at the end: push tag, verify the release.

## Task brief

# Chudmich v4: fix video lag / stuck swipes, drop glass for a solid AIOStreams-style UI

Repo root, branch `premium-ui` at 21632f02d (= chudmich-v3.4.1-3), GitHub jinnbuttcheeks/chudmich. Flutter app in `mobile/`, Android only. Read `mobile/CHUDMICH.md` and `README.md` first. Toolchain:
Box-only toolchain setup omitted (use mise per `mobile/mise.toml`).
No full APK build or emulator here (RAM); CI builds and signs. `flutter analyze` and `flutter test` are expected. (Box-only graphify notes omitted.)

Skills (~/.claude/skills): graphify, writing-plans (plan at HANDOFF-CHUDMICH.md plan sections), **eg-fix-bug** (goldfish diagnosis), **systematic-debugging**, **eg-precommit-review**, apple-design, taste-skill-2, unslop, karpathy-guidelines, dead-code-detector, verification-before-completion. Use any other installed skill that helps.

## Headless overrides for the eg skills (owner-authorized for this run)

- eg-fix-bug: "use your best guess for the repro". The repro is the symptom below; print it before spawning the goldfish. Resolve goldfish/elephant divergence yourself and record both diagnoses and why you chose.
- eg-precommit-review: "auto-accept at the R5 cap". Pass `$ARGUMENTS` = "Only review changes since commit 21632f02d (git diff 21632f02d plus uncommitted changes); ignore older history in git diff main...HEAD." Keep the template otherwise verbatim. Do NOT run its lint-baseline stash / `git checkout -- :/` / `git clean -fd` routine. The baseline is `flutter analyze` showing "No issues found" at 21632f02d.
- Commit authorization: commit once the review loop exits and the test gate passes. Do not push, tag, or touch remotes.

## Task A (TOP PRIORITY): video lag and stuck swipes (run /eg-fix-bug + systematic-debugging)

Owner, on a real phone running chudmich-v3.4.1-3: "On the videos specifically it's a little laggy... when swiping past a video it gets stuck." Repro: open the asset viewer on a timeline that mixes photos and videos. Swipe horizontally onto a video: playback is laggy. Keep swiping past the video: the PageView gets stuck (the swipe doesn't complete or snaps back, or the page sticks mid-way).

Find the actual root cause(s) in code; don't guess. Candidates to check (and others you find):
- Gesture arena conflicts between the viewer PageView and the video layer: native/platform-view video surfaces (Texture vs PlatformView/AndroidView hybrid composition, which is slow and eats gestures), the video controls, the seek bar/scrubber, tap/double-tap/scale detectors, and our glass viewer chrome capsules, plus any GestureDetector with horizontal-drag recognizers on the video page.
- The video controller initializing or disposing on the UI thread during the swipe (await-in-build, synchronous dispose, heavy setState), preload hooks that start video players for neighbours, autoplay on page change before the page settles.
- Hero animation on video assets, and the PressScale or spring code from our passes interfering.
- Glass (BackdropFilter) over the video surface (a blur over a texture that updates every frame is very expensive), and the ambient background ticking under the viewer.
- setState storms from position or buffer updates (rebuild of the whole page or chrome on every position tick). Use narrow listeners or ValueListenable selectors.
- Anything we changed vs upstream v3.4.1 in the viewer and video code (`git diff v3.4.1..HEAD -- mobile/lib` around asset_viewer/video). Check whether upstream already had the issue; fix it regardless.
Capture with failing tests where feasible: e.g. a widget test that drags a PageView across a video page with a fake/mocked controller and asserts the page settles at the next index; rebuild-count tests for position updates; a test that no BackdropFilter is in the viewer tree. Then fix. Requirements: video starts fast (show the thumbnail or preview instantly, init the controller without blocking the frame, start playback only once the page has settled), swiping across videos is smooth and never sticks, and controllers are disposed off the hot path. Keep the existing preload work for images.

## Task B: remove frosted glass; solid, smooth UI modeled on AIOStreams

The owner wants no frosted glass at all, just a smooth UI similar to AIOStreams (github.com/Viren070/AIOStreams). Its web UI is in github.com/Viren070/AIOStreams packages/web (shell, nav, styles.css) and github.com/Viren070/AIOStreams packages/ui (theme.css, tailwind-preset.ts, components). The Android app is packages/android: a WebView over a native player. Read those files yourself to confirm. The supervisor extracted these from the source:

- Palette (theme.css):
  - Dark background `#070707`; paper/cards `gray-950` = rgb(11,11,11); deep panels `gray-900` = rgb(16,16,16); `gray-800` = rgb(28,28,28).
  - Foreground `gray-200` = rgb(209,209,209), with white for emphasis; muted text white @ 40%, muted-highlight white @ 60%; inactive nav text `gray-400` = rgb(143,143,143).
  - Borders white @ 10%. Subtle fills white @ 6% (hover/pressed 8%).
  - Brand accent (violet): brand-500 rgb(97,82,223), 400 rgb(159,146,255), 300 rgb(199,194,255) (used as `--brand` text), 200 rgb(212,208,255) (dark focus ring), 600 rgb(82,67,203), 700 rgb(63,46,178). Primary button: brand-500 at about 70% opacity on dark with a brand-400 @ 20% border, white text.
  - Light mode: white background, gray-800 text, gray-200 borders, subtle black @ 4-6%.
- Radii: base 0.5rem (8 px) for buttons/inputs (`rounded-lg`); cards `rounded-xl` (12 px) with a 1 px border, paper bg and `shadow-sm`; pills and nav fully rounded.
- Surfaces: SOLID mode (`.glass-surface[data-surface='solid']`): background = page background, 1 px border white @ 10%, shadow `0 12px 32px -12px rgb(0 0 0 / 0.7)`. AIOStreams also has glass modes, but we use only the solid mode. No blur anywhere.
- Typography: Inter (fall back to the app's existing font if Inter isn't bundled; don't add large font assets unless cheap). Headings extrabold/bold with tight tracking (h1 4xl extrabold, h2 3xl bold, h3 2xl semibold); body medium weight for UI labels.
- Nav (mobile-nav.tsx): a floating fully-rounded bar, centered, `px-3` from the edges, `p-1.5` inner padding, `gap-1`, max width ~28rem, over the solid surface. Tabs are rounded-full with the icon above a tiny 0.65rem label. The active tab is a `bg-white/10` pill with white text; inactive tabs are gray-400. The bar hides on scroll down (translateY 100%, 200 ms ease-out) and returns on scroll up. Pill tabs elsewhere (pill-tabs.tsx): a `bg-gray-900` rounded-full track, `p-1 gap-1`, with the selected pill white (dark text) and the others gray-basic.
- Motion: short and functional. Color transitions; 200 ms ease-out slides; 450 ms `cubic-bezier(0.05, 0.7, 0.1, 1)` (emphasized decelerate) for shared-element title or logo transitions; a small "rise" (translateY 0.5rem to 0) on panel entry; 100 ms fade-outs; backdrop/hero scrolls at half speed (parallax) on detail pages.

Do this:
- Delete the glass system (`lib/theme/glass/` and everything using it) and the ambient animated gradient. There must be no BackdropFilter and no ImageFilter.blur anywhere in our code. Upstream code that had blur before our fork may stay only if it's essential; list any that remain. Delete dead code and tests for removed features (dead-code-detector).
- Build a small solid design token set in the theme (palette above, radii, borders, shadows, type scale) and apply it app-wide, in dark and light. Default dark should match AIOStreams closely. Decide how the existing primary-color/dynamic-color settings map: keep them working but default the accent to the AIOStreams violet.
- Keep the good structure from the earlier passes unless it conflicts: the pill tab bar (now the AIOStreams-style solid floating bar with the white/10 active pill, hide-on-scroll), the library bento dashboard, the album cover cards, search, the grouped settings, the large titles, the spring motion where it feels good (keep it subtle), the hero zoom, the image preload tweaks, and the centered scrubber arrows (keep the arrow test passing).
- Viewer chrome: solid or scrim (gradient-to-black) controls, no glass; very cheap over video.
- Performance first everywhere: no saveLayer-heavy effects, pre-baked shadows, RepaintBoundary where it matters, no continuously running tickers when idle, no per-frame rebuilds on scroll.
- Follow taste-skill-2 + unslop: clean, restrained, not generic Material.

## Task C: version and docs

- versionName `3.4.1-chudmich.4`, versionCode `3040203` (same offset mechanism in build.gradle: pubspec build number + 4). Semver must still read 3.4.1.
- Update `mobile/CHUDMICH.md` and `README.md`: remove the glass language and describe the solid AIOStreams-inspired design (credit AIOStreams as the inspiration, a link is fine), and the video fixes.
- Workflow: no change needed unless something references glass. The tag `chudmich-v3.4.1-4` will be pushed by the supervisor.

## Screenshots

Update the screenshot harness for the new UI and render it to `a local dir such as /tmp/screens-v4/` (`SCREENSHOT_DIR=/tmp/screens-v4 flutter test test/screens`), including the viewer chrome over a video-like frame, the nav bar, library, albums, search, settings, the timeline, and the scrubber. Do not commit PNGs.

## Verification and commits

- `flutter analyze`: no issues. Full `flutter test`: all pass. `dart format` only the changed files (not the whole tree). Confirm that `rg -n "BackdropFilter|ImageFilter.blur" mobile/lib` shows nothing from our layer.
- Small conventional commits on `premium-ui` with identity `git -c user.name=jinn -c user.email=jinn@users.noreply.github.com commit ...`. No AI attribution and no Co-Authored-By trailers. Suggested commits: `fix(mobile): smooth video paging in asset viewer` (one or more), `refactor(mobile): replace glass with solid surfaces`, `feat(mobile): AIOStreams-style solid theme and nav`, `chore(mobile): bump to 3.4.1-chudmich.4`, `docs: ...`.
- Watch line endings: don't convert CRLF files to LF.
- Final reply should cover:
  - commits;
  - the goldfish diagnosis for the video bug (goldfish vs elephant, converged or diverged and why);
  - each video root cause, its fix (file:line) and the test that proves it;
  - what was removed (glass, ambient), with a count of files and lines;
  - the new design tokens and what visibly changed per screen;
  - eg-precommit-review outcome (rounds, fixes, rebuttals verbatim);
  - analyze and test results, screenshot paths, and risks or work not done.

## ADDED REQUIREMENT: resumable handoff (owner may run out of Claude usage mid-task)

A Cursor agent must be able to take over from the GitHub repo alone (jinnbuttcheeks/chudmich, branch premium-ui). So:
1. FIRST commit, before any code change: create repo-root `HANDOFF-CHUDMICH.md` containing the FULL text of this brief (copy it verbatim into a "Task brief" section, but replace box-only paths with notes: the AIOStreams reference is github.com/Viren070/AIOStreams packages/web + packages/ui; toolchain is mise per mobile/mise.toml), plus sections: Goal, AIOStreams design findings & tokens, Done, In progress, Next steps, Video root-cause notes, Test commands (`flutter analyze`, `flutter test`, screenshot harness), Version & tag plan (3.4.1-chudmich.4 / versionCode 3040203 / tag chudmich-v3.4.1-4 pushed by the supervisor; CI builds + signs the APK on tag push via `.github/workflows/chudmich-android.yml`, so no local APK build is needed). Commit `docs: add Chudmich v4 handoff` and push immediately.
2. After EVERY meaningful step (diagnosis written, each fix, each refactor chunk, tests green), update HANDOFF-CHUDMICH.md (Done / In progress / Next steps / root-cause notes) and commit + push to premium-ui. Small WIP commits are fine (prefix `wip(mobile):` is OK; keep them conventional). Keep `flutter analyze` from regressing at each pushed commit where practical.
   This push authorization overrides the earlier "do not push" lines: you MAY push premium-ui (only that branch; no tags, no force-push, no other remotes, never merge PR #1). Push command (token in env, never print it):
   `T=$(printf %s "$GITHUB_TOKEN" | tr -d '[:space:]'); git -c http.extraheader="Authorization: Basic $(printf 'x-access-token:%s' "$T" | base64 -w0)" push origin premium-ui`
3. The precommit review still runs before the final commits; the final state must have HANDOFF-CHUDMICH.md marked "Status: complete" with what remains for the supervisor (tag + release verification).
