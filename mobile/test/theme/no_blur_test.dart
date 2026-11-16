import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Upstream (pre fork) blur that stays: static, decorative and never over video or the viewer chrome.
const _upstreamAllowlist = {
  'lib/widgets/asset_viewer/animated_play_pause.dart',
  'lib/presentation/widgets/slideshow/slideshow_slide.widget.dart',
  'lib/presentation/widgets/memory/memory_card.widget.dart',
};

void main() {
  test('no live blur anywhere in lib, apart from the upstream allowlist', () {
    final blur = RegExp(r'BackdropFilter|ImageFilter\.blur');
    final offenders = <String>[];
    for (final file in Directory('lib').listSync(recursive: true).whereType<File>()) {
      final path = file.path.replaceAll(r'\', '/');
      if (!path.endsWith('.dart') || _upstreamAllowlist.contains(path)) {
        continue;
      }
      if (blur.hasMatch(file.readAsStringSync())) {
        offenders.add(path);
      }
    }
    expect(offenders, isEmpty);
  });

  test('viewer chrome and video code never use blur', () {
    final blur = RegExp(r'BackdropFilter|ImageFilter|ImageFiltered');
    final dirs = ['lib/presentation/widgets/asset_viewer', 'lib/widgets/asset_viewer/video'];
    for (final dir in dirs.where((d) => Directory(d).existsSync())) {
      for (final file in Directory(dir).listSync(recursive: true).whereType<File>()) {
        expect(blur.hasMatch(file.readAsStringSync()), isFalse, reason: file.path);
      }
    }
  });
}
