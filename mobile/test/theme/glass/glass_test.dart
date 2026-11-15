import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:immich_mobile/theme/glass/glass.dart';

void main() {
  group('GlassMath', () {
    test('saturation 1 with no brightness is the identity', () {
      final m = GlassMath.saturationMatrix(1);
      expect(m.length, 20);
      for (var row = 0; row < 4; row++) {
        for (var col = 0; col < 5; col++) {
          expect(m[row * 5 + col], closeTo(row == col ? 1 : 0, 1e-9));
        }
      }
    });

    test('colour rows keep luminance weights summing to 1', () {
      final m = GlassMath.saturationMatrix(1.8);
      for (var row = 0; row < 3; row++) {
        expect(m[row * 5] + m[row * 5 + 1] + m[row * 5 + 2], closeTo(1, 1e-9));
      }
    });

    test('light from scroll is bounded and starts at the resting light', () {
      expect(GlassMath.lightFromScroll(0).dx, closeTo(GlassMath.restingLight.dx, 1e-9));
      for (final offset in [0.0, 100.0, 900.0, 2400.0, 50000.0, -300.0]) {
        final l = GlassMath.lightFromScroll(offset);
        expect(l.dx, inInclusiveRange(-1, 1));
        expect(l.dy, inInclusiveRange(-1, 1));
      }
    });

    test('light from scroll moves smoothly', () {
      final a = GlassMath.lightFromScroll(1000);
      final b = GlassMath.lightFromScroll(1001);
      expect((a - b).distance, lessThan(0.01));
    });

    test('light from tab sweeps left to right', () {
      expect(GlassMath.lightFromTab(0, 4).dx, closeTo(-0.9, 1e-9));
      expect(GlassMath.lightFromTab(3, 4).dx, closeTo(0.9, 1e-9));
      expect(GlassMath.lightFromTab(1.5, 4).dx, closeTo(0, 1e-9));
      expect(GlassMath.lightFromTab(0, 1), GlassMath.restingLight);
    });

    test('rim is brightest on the side the light comes from', () {
      final a = GlassMath.rimAlignment(const Offset(-1, -1));
      expect(a.begin, Alignment.topLeft);
      expect(a.end, Alignment.bottomRight);
    });

    test('variants get progressively denser', () {
      for (final b in Brightness.values) {
        final thin = GlassSpec.of(GlassVariant.thin, b);
        final regular = GlassSpec.of(GlassVariant.regular, b);
        final thick = GlassSpec.of(GlassVariant.thick, b);
        expect(thin.sigma, lessThan(regular.sigma));
        expect(regular.sigma, lessThan(thick.sigma));
        expect(thin.tintAlpha, lessThan(thick.tintAlpha));
        expect(thin.sigma, inInclusiveRange(18, 30));
        expect(thick.sigma, inInclusiveRange(18, 30));
      }
    });
  });

  group('GlassLayerBudget', () {
    test('grants up to max and refuses the rest', () {
      final budget = GlassLayerBudget(max: 2);
      final a = Object();
      final b = Object();
      final c = Object();
      expect(budget.tryAcquire(a), isTrue);
      expect(budget.tryAcquire(b), isTrue);
      expect(budget.tryAcquire(c), isFalse);
      expect(budget.active, 2);
    });

    test('re-acquire is idempotent and release frees a slot', () {
      final budget = GlassLayerBudget(max: 1);
      final a = Object();
      final b = Object();
      expect(budget.tryAcquire(a), isTrue);
      expect(budget.tryAcquire(a), isTrue);
      expect(budget.active, 1);
      expect(budget.tryAcquire(b), isFalse);
      budget.release(a);
      expect(budget.tryAcquire(b), isTrue);
    });

    test('essential surfaces always get a slot', () {
      final budget = GlassLayerBudget(max: 1);
      expect(budget.tryAcquire(Object()), isTrue);
      expect(budget.tryAcquire(Object(), essential: true), isTrue);
      expect(budget.active, 2);
    });
  });

  group('AmbientBackground', () {
    test('blob centres stay on screen and move slowly', () {
      for (var t = 0.0; t < 600; t += 7) {
        final c = AmbientBackground.blobCentres(t);
        for (final o in [c.a, c.b, c.c]) {
          expect(o.dx, inInclusiveRange(-0.1, 1.1));
          expect(o.dy, inInclusiveRange(-0.1, 1.1));
        }
      }
      final a = AmbientBackground.blobCentres(10).a;
      final b = AmbientBackground.blobCentres(11).a;
      expect((a - b).distance, lessThan(0.02));
    });
  });

  group('GlassSurface', () {
    Widget host(GlassLayerBudget budget, {int count = 3, bool essentialLast = false}) {
      return MaterialApp(
        theme: ThemeData(extensions: [GlassTokens.fromScheme(const ColorScheme.dark())]),
        home: Column(
          children: [
            for (var i = 0; i < count; i++)
              GlassSurface(
                key: ValueKey(i),
                budget: budget,
                essential: essentialLast && i == count - 1,
                child: const SizedBox(width: 40, height: 40),
              ),
          ],
        ),
      );
    }

    testWidgets('only budgeted surfaces mount a backdrop filter', (tester) async {
      final budget = GlassLayerBudget(max: 2);
      await tester.pumpWidget(host(budget));
      final enabled = tester.widgetList<BackdropFilter>(find.byType(BackdropFilter)).where((f) => f.enabled);
      expect(enabled.length, 2);
      expect(budget.active, 2);
    });

    testWidgets('slots are released on dispose', (tester) async {
      final budget = GlassLayerBudget(max: 2);
      await tester.pumpWidget(host(budget));
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      expect(budget.active, 0);
    });

    testWidgets('blur false never takes a slot', (tester) async {
      final budget = GlassLayerBudget(max: 2);
      await tester.pumpWidget(
        MaterialApp(
          home: GlassSurface(budget: budget, blur: false, child: const SizedBox(width: 10, height: 10)),
        ),
      );
      expect(budget.active, 0);
    });
  });
}
