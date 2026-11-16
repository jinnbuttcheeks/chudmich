import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:immich_mobile/presentation/widgets/asset_viewer/bottom_bar.widget.dart';
import 'package:immich_mobile/providers/asset_viewer/asset_viewer.provider.dart';
import 'package:immich_mobile/theme/solid/solid.dart';

class ViewerBottomAppBar extends ConsumerWidget {
  const ViewerBottomAppBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showingControls = ref.watch(assetViewerProvider.select((s) => s.showingControls));
    final double backgroundOpacity = ref.watch(assetViewerProvider.select((s) => s.backgroundOpacity));

    return SolidReveal(visible: showingControls, opacity: backgroundOpacity, child: const ViewerBottomBar());
  }
}
