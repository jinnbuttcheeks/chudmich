import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:immich_mobile/theme/glass/glass_tokens.dart';
import 'package:immich_mobile/widgets/common/immich_sliver_app_bar.dart';

void main() {
  const title = 'Library';

  Widget host(double extent) {
    return MaterialApp(
      theme: ThemeData(extensions: [GlassTokens.fromScheme(const ColorScheme.dark())]),
      home: Scaffold(
        body: SizedBox(
          height: 118,
          child: FlexibleSpaceBarSettings(
            toolbarOpacity: 1,
            minExtent: 56,
            maxExtent: 118,
            currentExtent: extent,
            child: const GlassAppBarBackground(largeTitle: title, pinned: true),
          ),
        ),
      ),
    );
  }

  testWidgets('the large title is announced once, whether the bar is expanded or collapsed', (tester) async {
    final handle = tester.ensureSemantics();
    for (final extent in [118.0, 56.0]) {
      // A fresh tree per extent: debugSemantics of a render object that was excluded later can be stale.
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(host(extent));
      expect(find.bySemanticsLabel(title), findsOneWidget, reason: 'extent $extent');
    }
    handle.dispose();
  });

  testWidgets('both titles are announced while the bar is in the cross-fade', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(host(81));
    expect(find.bySemanticsLabel(title), findsNWidgets(2));
    handle.dispose();
  });
}
