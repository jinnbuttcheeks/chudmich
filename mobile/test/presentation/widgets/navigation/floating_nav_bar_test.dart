import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:immich_mobile/presentation/widgets/navigation/floating_nav_bar.dart';
import 'package:immich_mobile/theme/solid/solid.dart';

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

Widget _host({
  required int selected,
  required ValueChanged<int> onSelected,
  bool reduceMotion = false,
  bool visible = true,
}) {
  return MaterialApp(
    theme: ThemeData(extensions: [SolidTokens.fromScheme(const ColorScheme.light())]),
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: reduceMotion, size: const Size(400, 800)),
      child: Scaffold(
        body: Align(
          alignment: Alignment.bottomCenter,
          child: FloatingNavBar(items: _items, selectedIndex: selected, onSelected: onSelected, visible: visible),
        ),
      ),
    ),
  );
}

void main() {
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

    testWidgets('slides off the bottom edge when hidden and back when shown', (tester) async {
      await tester.pumpWidget(_host(selected: 0, onSelected: (_) {}));
      await tester.pumpAndSettle();
      final shown = tester.getTopLeft(find.byKey(FloatingNavBar.activePillKey)).dy;

      await tester.pumpWidget(_host(selected: 0, onSelected: (_) {}, visible: false));
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(find.byKey(FloatingNavBar.activePillKey)).dy, greaterThan(shown + 40));

      await tester.pumpWidget(_host(selected: 0, onSelected: (_) {}));
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(find.byKey(FloatingNavBar.activePillKey)).dy, shown);
    });
  });
}
