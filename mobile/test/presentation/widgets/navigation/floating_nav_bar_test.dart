import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:immich_mobile/presentation/widgets/navigation/floating_nav_bar.dart';
import 'package:immich_mobile/theme/premium_tokens.dart';

const _items = [
  FloatingNavItem(label: 'Photos', icon: Icons.photo_library_outlined, selectedIcon: Icons.photo_library),
  FloatingNavItem(label: 'Search', icon: Icons.search_rounded, selectedIcon: Icons.search),
  FloatingNavItem(
    label: 'Albums',
    icon: Icons.photo_album_outlined,
    selectedIcon: Icons.photo_album_rounded,
    enabled: false,
  ),
];

Widget _host({required int selected, required ValueChanged<int> onSelected, bool reduceMotion = false}) {
  return MaterialApp(
    theme: ThemeData(extensions: [PremiumTokens.fromScheme(const ColorScheme.light())]),
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: reduceMotion, size: const Size(400, 800)),
      child: Scaffold(
        body: Align(
          alignment: Alignment.bottomCenter,
          child: FloatingNavBar(items: _items, selectedIndex: selected, onSelected: onSelected),
        ),
      ),
    ),
  );
}

void main() {
  group('FloatingNavBar.layout', () {
    test('widths always add up to the available width', () {
      for (final position in [0.0, 0.3, 1.0, 1.5, 2.0]) {
        final rects = FloatingNavBar.layout(count: 3, position: position, totalWidth: 300);
        expect(rects.fold<double>(0, (a, r) => a + r.width), closeTo(300, 1e-9));
        expect(rects.first.left, 0);
      }
    });

    test('active tab is wider than inactive tabs and tabs do not overlap', () {
      final rects = FloatingNavBar.layout(count: 3, position: 1, totalWidth: 300);
      expect(rects[1].width, greaterThan(rects[0].width));
      expect(rects[0].width, closeTo(rects[2].width, 1e-9));
      expect(rects[1].left, closeTo(rects[0].left + rects[0].width, 1e-9));
    });

    test('emphasis falls from 1 to 0 over one tab', () {
      expect(FloatingNavBar.emphasis(1, 1), 1);
      expect(FloatingNavBar.emphasis(1, 1.5), 0.5);
      expect(FloatingNavBar.emphasis(0, 2), 0);
    });
  });

  group('FloatingNavBar widget', () {
    testWidgets('reports taps on enabled tabs only', (tester) async {
      final taps = <int>[];
      await tester.pumpWidget(_host(selected: 0, onSelected: taps.add));
      await tester.pumpAndSettle();

      await tester.tap(find.bySemanticsLabel('Search'));
      await tester.tap(find.bySemanticsLabel('Albums'));
      expect(taps, [1]);
    });

    testWidgets('moves the pill to the new tab after a selection change', (tester) async {
      await tester.pumpWidget(_host(selected: 0, onSelected: (_) {}));
      await tester.pumpAndSettle();
      final before = tester.getTopLeft(find.byKey(FloatingNavBar.activePillKey)).dx;

      await tester.pumpWidget(_host(selected: 1, onSelected: (_) {}));
      await tester.pumpAndSettle();
      expect(find.text('Search'), findsOneWidget);
      expect(tester.getTopLeft(find.byKey(FloatingNavBar.activePillKey)).dx, isNot(before));
    });

    testWidgets('jumps straight to the target when motion is reduced', (tester) async {
      await tester.pumpWidget(_host(selected: 0, onSelected: (_) {}, reduceMotion: true));
      await tester.pumpAndSettle();
      await tester.pumpWidget(_host(selected: 2, onSelected: (_) {}, reduceMotion: true));
      final immediate = tester.getTopLeft(find.byKey(FloatingNavBar.activePillKey)).dx;
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(find.byKey(FloatingNavBar.activePillKey)).dx, immediate);
    });
  });
}
