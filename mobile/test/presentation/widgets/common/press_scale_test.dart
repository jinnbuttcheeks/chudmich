import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:immich_mobile/presentation/widgets/common/press_scale.dart';
import 'package:immich_mobile/theme/premium_tokens.dart';

Widget _host({bool reduceMotion = false}) => MaterialApp(
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: reduceMotion),
    child: const Center(
      child: PressScale(
        child: SizedBox(
          key: Key('tile'),
          width: 100,
          height: 100,
          child: ColoredBox(color: Colors.red),
        ),
      ),
    ),
  ),
);

double _scale(WidgetTester tester) => tester
    .widget<ScaleTransition>(find.descendant(of: find.byType(PressScale), matching: find.byType(ScaleTransition)))
    .scale
    .value;

void main() {
  testWidgets('shrinks after a hold and springs back on release', (tester) async {
    await tester.pumpWidget(_host());
    final gesture = await tester.startGesture(tester.getCenter(find.byKey(const Key('tile'))));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(PremiumMotion.fast);
    await tester.pump(PremiumMotion.fast);
    expect(_scale(tester), closeTo(PremiumTokens.pressedScale, 0.005));

    await gesture.up();
    await tester.pumpAndSettle();
    expect(_scale(tester), 1.0);
  });

  testWidgets('does not shrink when the pointer is dragged (scrolling)', (tester) async {
    await tester.pumpWidget(_host());
    final gesture = await tester.startGesture(tester.getCenter(find.byKey(const Key('tile'))));
    await gesture.moveBy(const Offset(0, 40));
    await tester.pump(const Duration(milliseconds: 200));
    expect(_scale(tester), 1.0);
    await gesture.up();
  });

  testWidgets('stays at full size when motion is reduced', (tester) async {
    await tester.pumpWidget(_host(reduceMotion: true));
    final gesture = await tester.startGesture(tester.getCenter(find.byKey(const Key('tile'))));
    await tester.pump(const Duration(milliseconds: 300));
    expect(_scale(tester), 1.0);
    await gesture.up();
  });
}
