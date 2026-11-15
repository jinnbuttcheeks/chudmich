import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:immich_mobile/theme/glass/ambient_background.dart';
import 'package:logging/logging.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  Logger.root.level = Level.OFF;
  // The drifting background schedules frames forever, which would stop pumpAndSettle.
  AmbientBackground.animationsEnabled = false;
  EasyLocalization.logger.enableBuildModes = [];
  // ignore: banned-usage
  debugPrint = (String? message, {int? wrapWidth}) {};
  return testMain();
}
