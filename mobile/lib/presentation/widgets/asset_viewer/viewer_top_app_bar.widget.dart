import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:immich_mobile/data/store.dart';
import 'package:immich_mobile/domain/models/asset/base_asset.model.dart';
import 'package:immich_mobile/extensions/build_context_extensions.dart';
import 'package:immich_mobile/extensions/datetime_extensions.dart';
import 'package:immich_mobile/presentation/actions/action.widget.dart';
import 'package:immich_mobile/presentation/actions/favorite.action.dart';
import 'package:immich_mobile/presentation/widgets/action_buttons/motion_photo_action_button.widget.dart';
import 'package:immich_mobile/presentation/widgets/asset_viewer/viewer_kebab_menu.widget.dart';
import 'package:immich_mobile/providers/asset_viewer/asset_viewer.provider.dart';
import 'package:immich_mobile/providers/infrastructure/asset_viewer/asset.provider.dart';
import 'package:immich_mobile/providers/infrastructure/current_album.provider.dart';
import 'package:immich_mobile/providers/infrastructure/readonly_mode.provider.dart';
import 'package:immich_mobile/providers/routes.provider.dart';
import 'package:immich_mobile/routing/router.dart';
import 'package:immich_mobile/theme/glass/glass.dart';
import 'package:immich_mobile/utils/timezone.dart';
import 'package:immich_ui/immich_ui.dart';

class ViewerTopAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const ViewerTopAppBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asset = ref.watch(assetViewerProvider.select((s) => s.currentAsset));
    if (asset == null) {
      return const SizedBox.shrink();
    }

    final album = ref.watch(currentRemoteAlbumProvider);

    final isInLockedView = ref.watch(inLockedViewProvider);
    final isReadonlyModeEnabled = ref.watch(readonlyModeProvider);

    final showingDetails = ref.watch(assetViewerProvider.select((state) => state.showingDetails));

    if (album != null && album.isActivityEnabled && album.isShared && asset is RemoteAsset) {
      ref.watch(Store.activity.list(album.id, assetId: asset.id));
    }

    final showingControls = ref.watch(assetViewerProvider.select((s) => s.showingControls));
    final double backgroundOpacity = ref.watch(assetViewerProvider.select((s) => s.backgroundOpacity));

    final originalTheme = context.themeData;

    final actions = <Widget>[
      if (asset.isMotionPhoto) const MotionPhotoActionButton(iconOnly: true),
      if (album != null && album.isActivityEnabled && album.isShared)
        IconButton(
          icon: const Icon(Icons.chat_outlined),
          onPressed: () {
            unawaited(
              context.router.push(
                ActivitiesRoute(album: album, assetId: asset is RemoteAsset ? asset.id : null, assetName: asset.name),
              ),
            );
          },
        ),

      const ActionIconButton(action: FavoriteAction(source: .viewer)),

      ImmichColorOverride(color: null, child: ViewerKebabMenu(originalTheme: originalTheme)),
    ];

    final lockedViewActions = <Widget>[ViewerKebabMenu(originalTheme: originalTheme)];

    return GlassReveal(
      visible: showingControls,
      opacity: backgroundOpacity,
      offset: const Offset(0, -20),
      child: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: showingDetails
                      ? null
                      : const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.black38, Colors.black12, Colors.transparent],
                          stops: [0.0, 0.6, 1.0],
                        ),
                ),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: SizedBox(
              height: preferredSize.height,
              child: Theme(
                data: context.themeData.copyWith(iconTheme: const IconThemeData(size: 22, color: Colors.white)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: NavigationToolbar(
                    centerMiddle: true,
                    leading: const _AppBarBackButton(),
                    middle: showingDetails ? null : _AssetInfoTitle(asset: asset),
                    trailing: !showingDetails && !isReadonlyModeEnabled
                        ? GlassSurface(
                            variant: GlassVariant.thin,
                            tint: GlassTokens.overPhoto,
                            radius: 26,
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: ImmichColorOverride(
                              color: Colors.white,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: isInLockedView ? lockedViewActions : actions,
                              ),
                            ),
                          )
                        : null,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(68.0);
}

class _AppBarBackButton extends ConsumerWidget {
  const _AppBarBackButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showingDetails = ref.watch(assetViewerProvider.select((state) => state.showingDetails));
    return GlassIconButton(
      icon: Icons.arrow_back_rounded,
      onPressed: context.maybePop,
      tint: showingDetails ? null : GlassTokens.overPhoto,
      color: showingDetails ? null : Colors.white,
      blur: false,
    );
  }
}

class _AssetInfoTitle extends ConsumerWidget {
  final BaseAsset asset;

  const _AssetInfoTitle({required this.asset});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exifInfo = ref.watch(assetExifProvider(asset)).valueOrNull;
    final alwaysUse24HourFormat = MediaQuery.alwaysUse24HourFormatOf(context);

    final (dateTime, _) = resolveAssetDateTime(asset, exifInfo);

    final dateFormatted = dateTime.formatDate();
    final timeFormatted = dateTime.formatTime(alwaysUse24HourFormat: alwaysUse24HourFormat);

    return GlassSurface(
      variant: GlassVariant.thin,
      tint: GlassTokens.overPhoto,
      blur: false,
      shadow: false,
      radius: 20,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            dateFormatted,
            style: context.textTheme.labelLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
          ),
          Text(timeFormatted, style: context.textTheme.labelSmall?.copyWith(color: Colors.white70)),
        ],
      ),
    );
  }
}
