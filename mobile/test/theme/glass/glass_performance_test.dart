import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:immich_mobile/theme/glass/glass.dart';

ThemeData _theme() => ThemeData(extensions: [GlassTokens.fromScheme(const ColorScheme.dark())]);

int _liveBlurs(WidgetTester tester) =>
    tester.widgetList<BackdropFilter>(find.byType(BackdropFilter)).where((f) => f.enabled).length;

void main() {
  setUp(() {
    GlassScrollActivity.scrolling.value = false;
    AmbientBackground.animationsEnabled = true;
  });
  tearDown(() {
    GlassScrollActivity.scrolling.value = false;
    AmbientBackground.animationsEnabled = false;
  });

  group('backdrop filter cache', () {
    test('one filter instance per recipe', () {
      final spec = GlassSpec.of(GlassVariant.regular, Brightness.dark);
      expect(identical(GlassMath.backdropFilter(spec), GlassMath.backdropFilter(spec)), isTrue);
      final before = GlassMath.cachedFilterCount;
      for (var i = 0; i < 50; i++) {
        GlassMath.backdropFilter(GlassSpec.of(GlassVariant.regular, Brightness.dark));
      }
      expect(GlassMath.cachedFilterCount, before, reason: 'repeated builds allocate nothing');
    });

    test('distinct recipes get distinct filters', () {
      final a = GlassMath.backdropFilter(GlassSpec.of(GlassVariant.thin, Brightness.dark));
      final b = GlassMath.backdropFilter(GlassSpec.of(GlassVariant.thick, Brightness.dark));
      expect(identical(a, b), isFalse);
    });

    testWidgets('rebuilding a surface hands the same filter to BackdropFilter', (tester) async {
      Widget host() => MaterialApp(
        theme: _theme(),
        home: GlassSurface(budget: GlassLayerBudget(), child: const SizedBox(width: 10, height: 10)),
      );
      await tester.pumpWidget(host());
      final first = tester.widget<BackdropFilter>(find.byType(BackdropFilter)).filter;
      await tester.pumpWidget(host());
      expect(identical(tester.widget<BackdropFilter>(find.byType(BackdropFilter)).filter, first), isTrue);
    });
  });

  group('light driver', () {
    testWidgets('publishes a bounded number of light updates for a long scroll', (tester) async {
      late ValueNotifier<Offset> light;
      final controller = ScrollController();
      await tester.pumpWidget(
        MaterialApp(
          home: GlassLightScrollDriver(
            child: Builder(
              builder: (context) {
                light = GlassLightScope.of(context);
                return ListView(controller: controller, children: const [SizedBox(height: 20000)]);
              },
            ),
          ),
        ),
      );
      var updates = 0;
      light.addListener(() => updates++);
      for (var i = 0; i < 300; i++) {
        controller.jumpTo(i * 1.0);
        await tester.pump();
      }
      // 300 px of scrolling is 0.43 of light travel: with a 0.015 step that is at most ~30 repaints, not 300.
      expect(updates, inInclusiveRange(1, 45));
    });
  });

  group('scroll gate', () {
    testWidgets('scroll aware surface drops its blur while scrolling and restores it when idle', (tester) async {
      final activity = ValueNotifier<bool>(false);
      await tester.pumpWidget(
        MaterialApp(
          theme: _theme(),
          home: GlassSurface(
            budget: GlassLayerBudget(),
            scrollAware: true,
            activity: activity,
            child: const SizedBox(width: 10, height: 10),
          ),
        ),
      );
      expect(_liveBlurs(tester), 1);

      activity.value = true;
      await tester.pumpAndSettle();
      expect(_liveBlurs(tester), 0, reason: 'no live blur over a scrolling grid');

      activity.value = false;
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 20));
      expect(_liveBlurs(tester), 1, reason: 'blur comes back as soon as the glass starts to clear');
      await tester.pumpAndSettle();
      expect(_liveBlurs(tester), 1);
    });

    testWidgets('surfaces that are not scroll aware keep blurring', (tester) async {
      final activity = ValueNotifier<bool>(true);
      await tester.pumpWidget(
        MaterialApp(
          theme: _theme(),
          home: GlassSurface(
            budget: GlassLayerBudget(),
            activity: activity,
            child: const SizedBox(width: 10, height: 10),
          ),
        ),
      );
      expect(_liveBlurs(tester), 1);
    });

    testWidgets('GlassBar is static glass while scrolling', (tester) async {
      final activity = ValueNotifier<bool>(false);
      await tester.pumpWidget(
        MaterialApp(
          theme: _theme(),
          home: GlassBar(budget: GlassLayerBudget(), activity: activity),
        ),
      );
      expect(_liveBlurs(tester), 1);
      activity.value = true;
      await tester.pumpAndSettle();
      expect(_liveBlurs(tester), 0);
    });

    testWidgets('the gate schedules no frames when idle', (tester) async {
      final activity = ValueNotifier<bool>(false);
      await tester.pumpWidget(
        MaterialApp(
          theme: _theme(),
          home: GlassSurface(
            budget: GlassLayerBudget(),
            scrollAware: true,
            activity: activity,
            child: const SizedBox(width: 10, height: 10),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.hasRunningAnimations, isFalse);
      expect(tester.binding.hasScheduledFrame, isFalse);
    });

    testWidgets('a scrollable that disappears mid scroll does not leave the glass static', (tester) async {
      Widget app({required bool list}) => MaterialApp(
        home: GlassScrollActivityListener(
          child: list ? ListView(children: const [SizedBox(height: 5000)]) : const SizedBox(),
        ),
      );
      await tester.pumpWidget(app(list: true));
      final gesture = await tester.startGesture(tester.getCenter(find.byType(ListView)));
      await gesture.moveBy(const Offset(0, -80));
      await tester.pump();
      expect(GlassScrollActivity.scrolling.value, isTrue);
      await tester.pumpWidget(app(list: false));
      await tester.pump(const Duration(milliseconds: 300));
      expect(GlassScrollActivity.scrolling.value, isFalse);
      await gesture.up();
    });

    testWidgets('listener publishes vertical scrolling only, with a debounced end', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: _theme(),
          home: GlassScrollActivityListener(
            child: Column(
              children: [
                SizedBox(
                  height: 100,
                  child: ListView(
                    key: const ValueKey('horizontal'),
                    scrollDirection: Axis.horizontal,
                    children: const [SizedBox(width: 2000, height: 100)],
                  ),
                ),
                Expanded(
                  child: ListView(key: const ValueKey('vertical'), children: const [SizedBox(height: 5000)]),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.drag(find.byKey(const ValueKey('horizontal')), const Offset(-100, 0));
      await tester.pump();
      expect(GlassScrollActivity.scrolling.value, isFalse);
      await tester.pumpAndSettle();

      final gesture = await tester.startGesture(tester.getCenter(find.byKey(const ValueKey('vertical'))));
      await gesture.moveBy(const Offset(0, -80));
      await tester.pump();
      expect(GlassScrollActivity.scrolling.value, isTrue);
      await gesture.up();
      await tester.pump(const Duration(milliseconds: 100));
      expect(GlassScrollActivity.scrolling.value, isTrue, reason: 'end is debounced');
      await tester.pump(const Duration(milliseconds: 300));
      expect(GlassScrollActivity.scrolling.value, isFalse);
    });
  });

  group('ambient background ticker', () {
    Widget host({bool tickers = true, Widget? child}) => MaterialApp(
      theme: _theme(),
      home: TickerMode(
        enabled: tickers,
        child: AmbientBackground(child: child),
      ),
    );

    _AmbientProbe probe(WidgetTester tester) => _AmbientProbe(tester.state(find.byType(AmbientBackground)));

    testWidgets('ticks while visible', (tester) async {
      await tester.pumpWidget(host());
      expect(probe(tester).ticking, isTrue);
    });

    testWidgets('does not tick when its route is obscured (TickerMode off)', (tester) async {
      await tester.pumpWidget(host(tickers: false));
      expect(probe(tester).ticking, isFalse);
      await tester.pumpWidget(host(tickers: true));
      expect(probe(tester).ticking, isTrue);
    });

    testWidgets('does not tick when animations are disabled', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: _theme(),
          builder: (context, child) =>
              MediaQuery(data: MediaQuery.of(context).copyWith(disableAnimations: true), child: child!),
          home: const AmbientBackground(),
        ),
      );
      expect(probe(tester).ticking, isFalse);
    });

    testWidgets('restarting the ticker after animations were re-enabled keeps drifting', (tester) async {
      Widget app({required bool disable}) => MaterialApp(
        theme: _theme(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: disable),
          child: child!,
        ),
        home: const AmbientBackground(),
      );
      await tester.pumpWidget(app(disable: false));
      await tester.pump(const Duration(seconds: 30));
      await tester.pumpWidget(app(disable: true));
      expect(probe(tester).ticking, isFalse);
      await tester.pumpWidget(app(disable: false));
      expect(probe(tester).ticking, isTrue);
      final before = probe(tester).phase;
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      final after = probe(tester).phase;
      expect(after, greaterThan(before), reason: 'the field moves again right after the restart, not 30 s later');
      expect(after - before, lessThanOrEqualTo(0.2), reason: 'and does not jump');
    });

    testWidgets('hiding the route right after a scroll keeps the drift stopped', (tester) async {
      Widget app({required bool visible}) => MaterialApp(
        theme: _theme(),
        home: TickerMode(
          enabled: visible,
          child: AmbientBackground(
            child: ListView(key: const ValueKey('list'), children: const [SizedBox(height: 5000)]),
          ),
        ),
      );
      await tester.pumpWidget(app(visible: true));
      final gesture = await tester.startGesture(tester.getCenter(find.byKey(const ValueKey('list'))));
      await gesture.moveBy(const Offset(0, -80));
      await gesture.up();
      await tester.pump();
      await tester.pumpWidget(app(visible: false));
      final frozen = probe(tester).phase;
      await tester.pump(const Duration(seconds: 1));
      expect(probe(tester).ticking, isFalse, reason: 'obscured route must not tick after the scroll debounce');
      expect(probe(tester).phase, frozen, reason: 'the field did not move while hidden');
      await tester.pumpWidget(app(visible: true));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(probe(tester).phase - frozen, lessThanOrEqualTo(0.2), reason: 'no jump when it becomes visible again');
    });

    testWidgets('a scroll that never reports its end does not freeze the drift', (tester) async {
      await tester.pumpWidget(
        host(
          child: ListView(key: const ValueKey('list'), children: const [SizedBox(height: 5000)]),
        ),
      );
      final gesture = await tester.startGesture(tester.getCenter(find.byKey(const ValueKey('list'))));
      await gesture.moveBy(const Offset(0, -80));
      await tester.pump();
      expect(probe(tester).ticking, isFalse);
      // Finger stays down, no more notifications: the timer alone releases the freeze.
      await tester.pump(const Duration(seconds: 1));
      expect(probe(tester).ticking, isTrue);
      await gesture.up();
      await tester.pump();
    });

    testWidgets('freezes while the content scrolls and resumes after it settles', (tester) async {
      await tester.pumpWidget(
        host(
          child: ListView(key: const ValueKey('list'), children: const [SizedBox(height: 5000)]),
        ),
      );
      expect(probe(tester).ticking, isTrue);

      final gesture = await tester.startGesture(tester.getCenter(find.byKey(const ValueKey('list'))));
      await gesture.moveBy(const Offset(0, -80));
      await tester.pump();
      expect(probe(tester).ticking, isFalse, reason: 'no background repaint during a scroll');

      await gesture.up();
      await tester.pump(const Duration(milliseconds: 100));
      expect(probe(tester).ticking, isFalse, reason: 'resume is debounced');
      await tester.pump(const Duration(seconds: 1));
      expect(probe(tester).ticking, isTrue);
    });
  });
}

class _AmbientProbe {
  _AmbientProbe(this.state);
  final State state;
  bool get ticking => (state as dynamic).isDrifting as bool;
  double get phase => (state as dynamic).phase as double;
}
