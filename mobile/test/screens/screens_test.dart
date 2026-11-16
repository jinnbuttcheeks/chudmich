// Renders the redesigned widgets over sample content and writes PNGs.
//
// Skipped unless SCREENSHOT_DIR is set, so it never writes outside the repo during
// a normal `flutter test` run:
//   SCREENSHOT_DIR=/workspace/builds/chudmich/screens flutter test test/screens
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:immich_mobile/domain/models/timeline.model.dart';
import 'package:immich_mobile/domain/services/timeline.service.dart';
import 'package:immich_mobile/presentation/pages/library.page.dart';
import 'package:immich_mobile/presentation/widgets/navigation/floating_nav_bar.dart';
import 'package:immich_mobile/presentation/widgets/timeline/header.widget.dart';
import 'package:immich_mobile/presentation/widgets/timeline/scrubber.widget.dart';
import 'package:immich_mobile/providers/infrastructure/timeline.provider.dart';
import 'package:immich_mobile/theme/solid/solid.dart';
import 'package:immich_mobile/theme/theme_data.dart';
import 'package:immich_mobile/widgets/common/confirm_dialog.dart';
import 'package:mocktail/mocktail.dart';

import '../unit/presentation/presentation_context.dart';

final String? _outDir = Platform.environment['SCREENSHOT_DIR'];
const _size = Size(393, 852);

Future<void> _loadFonts() async {
  final loader = FontLoader('GoogleSans');
  for (final name in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
    final bytes = File('fonts/GoogleSans/GoogleSans-$name.ttf').readAsBytesSync();
    loader.addFont(Future.value(ByteData.sublistView(bytes)));
  }
  await loader.load();
  final icons = FontLoader('MaterialIcons');
  final sdk =
      Platform.environment['FLUTTER_ROOT'] ?? '/workspace/tools/mise-data/installs/aqua-flutter-flutter/3.47.2/flutter';
  final file = File('$sdk/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf');
  icons.addFont(Future.value(ByteData.sublistView(file.readAsBytesSync())));
  await icons.load();
}

/// Procedural "photo": a sky gradient, a sun and two hills, tinted by [seed].
class _FakePhoto extends StatelessWidget {
  const _FakePhoto(this.seed);

  final int seed;

  @override
  Widget build(BuildContext context) => CustomPaint(painter: _PhotoPainter(seed), size: Size.infinite);
}

class _PhotoPainter extends CustomPainter {
  _PhotoPainter(this.seed);

  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = math.Random(seed);
    final hue = (seed * 47) % 360;
    final top = HSLColor.fromAHSL(1, hue.toDouble(), 0.7, 0.55).toColor();
    final bottom = HSLColor.fromAHSL(1, (hue + 40) % 360, 0.8, 0.78).toColor();
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [top, bottom],
        ).createShader(rect),
    );
    canvas.drawCircle(
      Offset(size.width * (0.2 + rnd.nextDouble() * 0.6), size.height * (0.2 + rnd.nextDouble() * 0.2)),
      size.shortestSide * 0.14,
      Paint()..color = Colors.white.withValues(alpha: 0.85),
    );
    for (var i = 0; i < 2; i++) {
      final base = size.height * (0.62 + i * 0.14);
      final path = Path()..moveTo(0, size.height);
      path.lineTo(0, base);
      path.quadraticBezierTo(
        size.width * (0.3 + rnd.nextDouble() * 0.3),
        base - size.height * 0.22,
        size.width,
        base + size.height * 0.04,
      );
      path.lineTo(size.width, size.height);
      canvas.drawPath(
        path,
        Paint()..color = HSLColor.fromAHSL(1, (hue + 160 + i * 20) % 360, 0.45, 0.3 - i * 0.07).toColor(),
      );
    }
  }

  @override
  bool shouldRepaint(_PhotoPainter old) => old.seed != seed;
}

class _PhotoGrid extends StatelessWidget {
  const _PhotoGrid({this.top = 0});

  final double top;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: EdgeInsets.only(top: top),
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 3,
        crossAxisSpacing: 3,
      ),
      itemCount: 60,
      itemBuilder: (_, i) => ClipRRect(borderRadius: BorderRadius.circular(7), child: _FakePhoto(i + 3)),
    );
  }
}

Future<void> _shoot(
  WidgetTester tester,
  PresentationContext context,
  String name,
  Widget Function(Brightness) screen, {
  List<Override> overrides = const [],
}) async {
  for (final brightness in Brightness.values) {
    final scheme = ColorScheme.fromSeed(seedColor: const Color(0xFF4250AF), brightness: brightness);
    final key = GlobalKey();
    tester.view.physicalSize = _size * 2.75;
    tester.view.devicePixelRatio = 2.75;
    await tester.pumpTestWidget(
      context,
      Theme(
        data: getThemeData(colorScheme: scheme, locale: const Locale('en')),
        child: RepaintBoundary(key: key, child: screen(brightness)),
      ),
      expectSettle: false,
      overrides: overrides,
    );
    await tester.pump(const Duration(milliseconds: 900));
    await tester.runAsync(() async {
      final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 1.5);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      final file = File('$_outDir/${name}_${brightness.name}.png')..createSync(recursive: true);
      file.writeAsBytesSync(data!.buffer.asUint8List());
    });
  }
}

class _MockTimelineService extends Mock implements TimelineService {}

void main() {
  late PresentationContext context;

  setUpAll(_loadFonts);
  setUp(() async => context = await PresentationContext.create());
  tearDown(() async => context.dispose());

  // Only renders when SCREENSHOT_DIR is set.
  final skip = _outDir == null;

  testWidgets('photos timeline with solid bars', (tester) async {
    await _shoot(tester, context, 'photos', (b) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Builder(builder: (c) => ColoredBox(color: c.solid.canvas)),
          const _PhotoGrid(top: 150),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SizedBox(
              height: 110,
              child: Stack(
                children: [
                  const SolidBar(),
                  Builder(
                    builder: (c) => Padding(
                      padding: const EdgeInsets.fromLTRB(20, 56, 20, 0),
                      child: Row(
                        children: [
                          Text('immich', style: c.textThemeLarge),
                          const Spacer(),
                          const SolidIconButton(
                            icon: Icons.cloud_done_rounded,
                            onPressed: null,
                            size: 38,
                            iconSize: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: FloatingNavBar(
              selectedIndex: 0,
              onSelected: (_) {},
              items: const [
                FloatingNavItem(label: 'Photos', icon: Icons.photo_library_outlined, selectedIcon: Icons.photo_library),
                FloatingNavItem(label: 'Search', icon: Icons.search_rounded, selectedIcon: Icons.search),
                FloatingNavItem(
                  label: 'Albums',
                  icon: Icons.photo_album_outlined,
                  selectedIcon: Icons.photo_album_rounded,
                ),
                FloatingNavItem(
                  label: 'Library',
                  icon: Icons.space_dashboard_outlined,
                  selectedIcon: Icons.space_dashboard_rounded,
                ),
              ],
            ),
          ),
        ],
      );
    });
  }, skip: skip);

  testWidgets('timeline headers', (tester) async {
    final timeline = _MockTimelineService();
    when(() => timeline.getAssets(any(), any())).thenReturn([]);
    await _shoot(tester, context, 'timeline_headers', (b) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Builder(builder: (c) => ColoredBox(color: c.solid.canvas)),
          Column(
            children: [
              const SizedBox(height: 70),
              TimelineHeader(
                bucket: TimeBucket(date: DateTime(2026, 7, 12), assetCount: 48),
                header: HeaderType.monthAndDay,
                height: 128,
                assetOffset: 0,
              ),
              SizedBox(
                height: 150,
                child: Row(
                  children: [
                    for (var i = 0; i < 3; i++)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(1.5),
                          child: ClipRRect(borderRadius: BorderRadius.circular(7), child: _FakePhoto(i + 20)),
                        ),
                      ),
                  ],
                ),
              ),
              TimelineHeader(
                bucket: TimeBucket(date: DateTime(2026, 7, 9), assetCount: 12),
                header: HeaderType.day,
                height: 72,
                assetOffset: 0,
              ),
              SizedBox(
                height: 150,
                child: Row(
                  children: [
                    for (var i = 0; i < 3; i++)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(1.5),
                          child: ClipRRect(borderRadius: BorderRadius.circular(7), child: _FakePhoto(i + 40)),
                        ),
                      ),
                  ],
                ),
              ),
              TimelineHeader(
                bucket: TimeBucket(date: DateTime(2026, 6, 1), assetCount: 230),
                header: HeaderType.month,
                height: 80,
                assetOffset: 0,
              ),
              SizedBox(
                height: 150,
                child: Row(
                  children: [
                    for (var i = 0; i < 3; i++)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(1.5),
                          child: ClipRRect(borderRadius: BorderRadius.circular(7), child: _FakePhoto(i + 60)),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      );
    }, overrides: [timelineServiceProvider.overrideWithValue(timeline)]);
  }, skip: skip);

  testWidgets('library dashboard', (tester) async {
    await _shoot(tester, context, 'library', (b) {
      return Builder(
        builder: (c) {
          const gap = 12.0;
          const unit = (393 - 32 - gap) / 2;
          const small = (unit - gap) / 2;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 70, 16, 0),
            physics: const NeverScrollableScrollPhysics(),
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 16),
                child: Text('Library', style: c.textThemeLarge?.copyWith(fontSize: 36)),
              ),
              SizedBox(
                height: unit,
                child: Row(
                  children: [
                    Expanded(
                      child: LibraryBentoCard(
                        hue: LibraryHue.favorites,
                        icon: Icons.favorite_rounded,
                        title: 'Favorites',
                        hero: true,
                        onTap: () {},
                      ),
                    ),
                    const SizedBox(width: gap),
                    Expanded(
                      child: Column(
                        children: [
                          Expanded(
                            child: LibraryBentoCard(
                              hue: LibraryHue.archive,
                              icon: Icons.inventory_2_rounded,
                              title: 'Archive',
                              onTap: () {},
                            ),
                          ),
                          const SizedBox(height: gap),
                          Expanded(
                            child: LibraryBentoCard(
                              hue: LibraryHue.links,
                              icon: Icons.link_rounded,
                              title: 'Shared links',
                              onTap: () {},
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: gap),
              SizedBox(
                height: small + 8,
                child: LibraryWideCard(
                  hue: LibraryHue.people,
                  icon: Icons.face_retouching_natural_rounded,
                  title: 'People',
                  onTap: () {},
                  trailing: LibraryAvatarStack(children: [for (var i = 0; i < 4; i++) _FakePhoto(i + 90)]),
                ),
              ),
              const SizedBox(height: gap),
              SizedBox(
                height: unit * 0.82,
                child: Row(
                  children: [
                    Expanded(
                      child: LibraryBentoCard(
                        hue: LibraryHue.places,
                        icon: Icons.place_rounded,
                        title: 'Places',
                        onTap: () {},
                      ),
                    ),
                    const SizedBox(width: gap),
                    Expanded(
                      child: LibraryBentoCard(
                        hue: LibraryHue.device,
                        icon: Icons.smartphone_rounded,
                        title: 'On this device',
                        subtitle: '14',
                        onTap: () {},
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: gap),
              SizedBox(
                height: small + 8,
                child: LibraryWideCard(
                  hue: LibraryHue.memories,
                  icon: Icons.auto_awesome_rounded,
                  title: 'Memories',
                  onTap: () {},
                  trailing: LibraryAvatarStack(children: [for (var i = 0; i < 4; i++) _FakePhoto(i + 120)]),
                ),
              ),
            ],
          );
        },
      );
    });
  }, skip: skip);

  testWidgets('albums grid', (tester) async {
    await _shoot(tester, context, 'albums', (b) {
      return Builder(
        builder: (c) {
          Widget card(String name, int n, int seed) => ClipRSuperellipse(
            borderRadius: BorderRadius.circular(28),
            child: Stack(
              fit: StackFit.expand,
              children: [
                _FakePhoto(seed),
                Positioned(
                  left: 8,
                  right: 8,
                  bottom: 8,
                  child: SolidSurface(
                    radius: 20,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(name, style: c.textThemeTitle),
                        Text(
                          '$n items • Owned',
                          style: Theme.of(c).textTheme.labelMedium?.copyWith(color: c.solid.mutedStrong),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
          return ListView(
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 70, 16, 0),
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 14),
                child: Text('Albums', style: c.textThemeLarge?.copyWith(fontSize: 36)),
              ),
              const SolidSurface(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(children: [Icon(Icons.search_rounded), SizedBox(width: 12), Text('Search albums')]),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  SolidChip(label: 'All', selected: true, onTap: () {}),
                  const SizedBox(width: 8),
                  SolidChip(label: 'Shared with me', selected: false, onTap: () {}),
                  const SizedBox(width: 8),
                  SolidChip(label: 'My albums', selected: false, onTap: () {}),
                ],
              ),
              const SizedBox(height: 14),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                childAspectRatio: 0.82,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  card('Iceland 2026', 214, 7),
                  card('Family', 1042, 11),
                  card('Roadtrip', 88, 23),
                  card('Pets', 530, 31),
                ],
              ),
            ],
          );
        },
      );
    });
  }, skip: skip);

  testWidgets('viewer chrome', (tester) async {
    await _shoot(tester, context, 'viewer', (b) {
      return Stack(
        fit: StackFit.expand,
        children: [
          const _FakePhoto(15),
          Builder(
            builder: (c) => Positioned(
              top: 54,
              left: 12,
              right: 12,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SolidIconButton(
                    icon: Icons.arrow_back_rounded,
                    onPressed: null,
                    fill: SolidTokens.overPhoto,
                    color: Colors.white,
                  ),
                  SolidSurface(
                    color: SolidTokens.overPhoto,
                    radius: 20,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Jul 12, 2026',
                          style: Theme.of(
                            c,
                          ).textTheme.labelLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                        ),
                        Text('18:42', style: Theme.of(c).textTheme.labelSmall?.copyWith(color: Colors.white70)),
                      ],
                    ),
                  ),
                  const SolidSurface(
                    color: SolidTokens.overPhoto,
                    radius: 26,
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 11),
                    child: Row(
                      children: [
                        Icon(Icons.favorite_border_rounded, color: Colors.white),
                        SizedBox(width: 14),
                        Icon(Icons.more_vert_rounded, color: Colors.white),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Positioned(
            left: 16,
            right: 16,
            bottom: 34,
            child: SolidSurface(
              color: SolidTokens.overPhoto,
              radius: 32,
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Icon(Icons.ios_share_rounded, color: Colors.white),
                  Icon(Icons.tune_rounded, color: Colors.white),
                  Icon(Icons.add_rounded, color: Colors.white),
                  Icon(Icons.delete_outline_rounded, color: Colors.white),
                ],
              ),
            ),
          ),
        ],
      );
    });
  }, skip: skip);

  testWidgets('settings groups', (tester) async {
    await _shoot(tester, context, 'settings', (b) {
      return Builder(
        builder: (c) => ListView(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.only(top: 70),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: Text('Settings', style: c.textThemeLarge?.copyWith(fontSize: 36)),
            ),
            const SolidGroup(
              margin: EdgeInsets.fromLTRB(16, 0, 16, 12),
              children: [
                SolidGroupTile(
                  leading: CircleAvatar(radius: 26, child: Text('A')),
                  title: 'Alex Morgan',
                  subtitle: 'alex@example.com',
                  trailing: SizedBox.shrink(),
                ),
              ],
            ),
            SolidGroup(
              children: [
                SolidGroupTile(
                  icon: Icons.cloud_upload_outlined,
                  iconColor: const Color(0xFF34C759),
                  title: 'Backup',
                  subtitle: 'Back up photos and videos',
                  onTap: () {},
                ),
                SolidGroupTile(
                  icon: Icons.cleaning_services_outlined,
                  iconColor: const Color(0xFFFF9F0A),
                  title: 'Free up space',
                  subtitle: 'Remove backed up media',
                  onTap: () {},
                ),
                SolidGroupTile(
                  icon: Icons.sync_outlined,
                  iconColor: const Color(0xFF64D2FF),
                  title: 'Sync status',
                  subtitle: 'Server sync state',
                  onTap: () {},
                ),
              ],
            ),
            SolidGroup(
              children: [
                SolidGroupTile(
                  icon: Icons.interests_outlined,
                  iconColor: const Color(0xFFFF375F),
                  title: 'Preferences',
                  subtitle: 'Theme, colours and layout',
                  onTap: () {},
                ),
                SolidGroupTile(
                  icon: Icons.language,
                  iconColor: const Color(0xFF5E5CE6),
                  title: 'Language',
                  subtitle: 'Choose your language',
                  onTap: () {},
                ),
                SolidGroupTile(
                  icon: Icons.notifications_none_rounded,
                  iconColor: const Color(0xFFFF453A),
                  title: 'Notifications',
                  subtitle: 'Manage notifications',
                  onTap: () {},
                ),
              ],
            ),
          ],
        ),
      );
    });
  }, skip: skip);

  testWidgets('dialog', (tester) async {
    await _shoot(tester, context, 'dialog', (b) {
      return Stack(
        fit: StackFit.expand,
        children: [
          const _PhotoGrid(),
          ColoredBox(color: Colors.black.withValues(alpha: 0.45)),
          const Center(
            child: ConfirmDialog(
              title: 'Delete album',
              content: 'Are you sure you want to delete the album "Iceland 2026"? This cannot be undone.',
              ok: 'Delete',
            ),
          ),
        ],
      );
    });
  }, skip: skip);

  testWidgets('scrubber close-up', (tester) async {
    await _shoot(tester, context, 'scrubber', (b) {
      return const Stack(
        fit: StackFit.expand,
        children: [
          _PhotoGrid(),
          Align(
            alignment: Alignment(1, -0.2),
            child: Padding(padding: EdgeInsets.only(right: 4), child: ScrubberHandle()),
          ),
        ],
      );
    });
  }, skip: skip);

  testWidgets('solid specimens', (tester) async {
    await _shoot(tester, context, 'material', (b) {
      return Stack(
        fit: StackFit.expand,
        children: [
          const _PhotoGrid(),
          Builder(
            builder: (c) => ListView(
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(24, 90, 24, 0),
              children: [
                for (final v in ['paper', 'panel', 'floating']) ...[
                  SolidSurface(
                    floating: v == 'floating',
                    color: v == 'panel' ? c.solid.panel : null,
                    radius: SolidTokens.radiusCard,
                    padding: const EdgeInsets.all(20),
                    child: Text(v, style: c.textThemeTitle),
                  ),
                  const SizedBox(height: 18),
                ],
                Row(
                  children: [
                    SolidButton(label: 'Share', icon: Icons.ios_share_rounded, onPressed: () {}),
                    const SizedBox(width: 12),
                    SolidButton(label: 'Backup', prominent: true, onPressed: () {}),
                    const SizedBox(width: 12),
                    const SolidIconButton(icon: Icons.favorite_rounded, onPressed: null),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    SolidChip(label: 'People', selected: true, onTap: () {}),
                    const SizedBox(width: 8),
                    SolidChip(label: 'Places', selected: false, onTap: () {}),
                  ],
                ),
              ],
            ),
          ),
        ],
      );
    });
  }, skip: skip);
}

extension on BuildContext {
  TextStyle? get textThemeLarge => Theme.of(this).textTheme.headlineLarge?.copyWith(color: solid.ink);
  TextStyle? get textThemeTitle => Theme.of(this).textTheme.titleSmall?.copyWith(color: solid.ink);
}
