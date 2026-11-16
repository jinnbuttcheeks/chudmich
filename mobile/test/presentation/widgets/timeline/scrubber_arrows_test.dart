import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:immich_mobile/presentation/widgets/timeline/scrubber.widget.dart';
import 'package:immich_mobile/theme/solid/solid_tokens.dart';

void main() {
  Widget host({required Brightness brightness, required double textScale}) {
    final scheme = ColorScheme.fromSeed(seedColor: const Color(0xFF4250AF), brightness: brightness);
    return MaterialApp(
      theme: ThemeData(colorScheme: scheme, extensions: [SolidTokens.fromScheme(scheme)]),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: const Scaffold(
        body: Align(alignment: Alignment.topRight, child: ScrubberHandle()),
      ),
    );
  }

  for (final brightness in Brightness.values) {
    for (final scale in [1.0, 1.3, 2.0]) {
      testWidgets('arrows are centred in the handle (${brightness.name}, text scale $scale)', (tester) async {
        await tester.pumpWidget(host(brightness: brightness, textScale: scale));

        final handle = tester.getRect(find.byKey(ScrubberArrowPainter.handleKey));
        final painter = tester.widget<CustomPaint>(find.byKey(ScrubberArrowPainter.paintKey)).foregroundPainter!;
        expect(painter, isA<ScrubberArrowPainter>());

        final glyphs = ScrubberArrowPainter.glyphs(handle.size).map((p) => p.getBounds().shift(handle.topLeft));
        final union = glyphs.reduce((a, b) => a.expandToInclude(b));

        expect(union.center.dx, closeTo(handle.center.dx, 0.5), reason: 'horizontal centre');
        expect(union.center.dy, closeTo(handle.center.dy, 0.5), reason: 'vertical centre');
        for (final glyph in glyphs) {
          expect(glyph.center.dx, closeTo(handle.center.dx, 0.5), reason: 'each arrow is centred horizontally');
        }
        expect(handle.size, const Size(32, 48), reason: 'handle size does not follow text scale');
      });
    }
  }
}
