import 'dart:async';

import 'package:flutter/material.dart';
import 'package:immich_mobile/domain/models/asset/base_asset.model.dart';
import 'package:immich_mobile/domain/services/timeline.service.dart';
import 'package:immich_mobile/presentation/widgets/asset_viewer/asset_preload_window.dart';
import 'package:immich_mobile/presentation/widgets/images/image_provider.dart';

class AssetPreloader {
  static final _dummyListener = ImageStreamListener((image, _) => image.dispose());

  /// Wait after a page change before starting preload requests, so a fast
  /// flick through several assets does not start requests that are cancelled
  /// right away. Short enough to beat a typical swipe-to-swipe interval.
  static const Duration debounce = Duration(milliseconds: 150);

  final TimelineService timelineService;
  final bool Function() mounted;

  Timer? _timer;
  int? _lastIndex;
  final Map<String, ImageStream> _streams = {};

  AssetPreloader({required this.timelineService, required this.mounted});

  /// Preloads assets around [index] with the current thumbnail size.
  void preload(int index, Size size, {Size? thumbnailSize}) {
    final lastIndex = _lastIndex;
    final direction = lastIndex == null ? 0 : (index - lastIndex).sign;
    _lastIndex = index;

    unawaited(timelineService.preloadAssets(index));
    _timer?.cancel();
    _timer = Timer(debounce, () async {
      if (!mounted()) {
        return;
      }
      final wanted = AssetPreloadWindow.indices(index: index, total: timelineService.totalAssets, direction: direction);
      final assets = await Future.wait(wanted.map(timelineService.getAssetAsync));
      if (!mounted()) {
        return;
      }

      // Keyed by asset (not index) so a timeline reload that shifts indices never reuses a stale stream.
      final wantedAssets = {for (final asset in assets.nonNulls) asset.heroTag: asset};
      for (final stale in _streams.keys.where((key) => !wantedAssets.containsKey(key)).toList()) {
        _streams.remove(stale)?.removeListener(_dummyListener);
      }
      for (final entry in wantedAssets.entries) {
        _streams.putIfAbsent(entry.key, () => _resolveImage(entry.value, size, thumbnailSize));
      }
    });
  }

  ImageStream _resolveImage(BaseAsset asset, Size size, Size? thumbnailSize) {
    return getFullImageProvider(asset, size: size, remoteThumbnailSize: thumbnailSize).resolve(ImageConfiguration.empty)
      ..addListener(_dummyListener);
  }

  void dispose() {
    _timer?.cancel();
    for (final stream in _streams.values) {
      stream.removeListener(_dummyListener);
    }
    _streams.clear();
  }
}
