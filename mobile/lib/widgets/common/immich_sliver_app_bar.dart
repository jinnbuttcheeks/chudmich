import 'dart:async';
import 'dart:math' as math;

import 'package:auto_route/auto_route.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:immich_mobile/extensions/build_context_extensions.dart';
import 'package:immich_mobile/generated/translations.g.dart';
import 'package:immich_mobile/models/server_info/server_info.model.dart';
import 'package:immich_mobile/providers/backup/backup.provider.dart';
import 'package:immich_mobile/providers/cast.provider.dart';
import 'package:immich_mobile/providers/infrastructure/readonly_mode.provider.dart';
import 'package:immich_mobile/providers/infrastructure/settings.provider.dart';
import 'package:immich_mobile/providers/server_info.provider.dart';
import 'package:immich_mobile/providers/sync_status.provider.dart';
import 'package:immich_mobile/providers/timeline/multiselect.provider.dart';
import 'package:immich_mobile/providers/user.provider.dart';
import 'package:immich_mobile/routing/router.dart';
import 'package:immich_mobile/theme/glass/glass.dart';
import 'package:immich_mobile/widgets/asset_viewer/cast_dialog.dart';
import 'package:immich_mobile/widgets/common/app_bar_dialog/app_bar_dialog.dart';
import 'package:immich_mobile/widgets/common/user_circle_avatar.dart';

class ImmichSliverAppBar extends ConsumerWidget {
  final List<Widget>? actions;
  final bool showUploadButton;
  final bool floating;
  final bool pinned;
  final bool snap;
  final Widget? title;
  final double? expandedHeight;

  /// When set, the bar shows this as a large display title that collapses into
  /// the glass toolbar while scrolling. Requires [pinned].
  final String? largeTitle;

  const ImmichSliverAppBar({
    super.key,
    this.actions,
    this.showUploadButton = true,
    this.floating = true,
    this.pinned = false,
    this.snap = true,
    this.title,
    this.expandedHeight,
    this.largeTitle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCasting = ref.watch(castProvider.select((c) => c.isCasting));
    final isReadonlyModeEnabled = ref.watch(readonlyModeProvider);
    final isMultiSelectEnabled = ref.watch(multiSelectProvider.select((s) => s.isEnabled));

    return SliverIgnorePointer(
      ignoring: isMultiSelectEnabled,
      sliver: SliverAnimatedOpacity(
        duration: Durations.medium1,
        opacity: isMultiSelectEnabled ? 0 : 1,
        sliver: SliverAppBar(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          floating: floating,
          pinned: pinned,
          snap: snap,
          expandedHeight: largeTitle == null ? expandedHeight : (expandedHeight ?? _kLargeTitleExtent),
          flexibleSpace: _GlassAppBarBackground(largeTitle: largeTitle, pinned: pinned),
          automaticallyImplyLeading: false,
          centerTitle: false,
          title: largeTitle != null ? null : (title ?? const _ImmichLogoWithText()),
          actions: [
            const _SyncStatusIndicator(),
            if (isCasting && !isReadonlyModeEnabled)
              IconButton(
                onPressed: () => showDialog(context: context, builder: (context) => const CastDialog()),
                icon: Icon(isCasting ? Icons.cast_connected_rounded : Icons.cast_rounded),
              ),
            ...?actions,
            if (showUploadButton && !isReadonlyModeEnabled) const _BackupIndicator(),
            const _ProfileIndicator(),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }
}

const double _kLargeTitleExtent = kToolbarHeight + 62;

/// Flexible space of the glass app bar: glass condenses in as the content
/// scrolls under it and a large title collapses into the toolbar.
class _GlassAppBarBackground extends StatelessWidget {
  const _GlassAppBarBackground({required this.largeTitle, required this.pinned});

  final String? largeTitle;
  final bool pinned;

  @override
  Widget build(BuildContext context) {
    final settings = context.dependOnInheritedWidgetOfExactType<FlexibleSpaceBarSettings>();
    final tokens = context.glass;
    var collapse = pinned ? 0.0 : 1.0;
    if (settings != null && settings.maxExtent > settings.minExtent) {
      collapse = (1 - (settings.currentExtent - settings.minExtent) / (settings.maxExtent - settings.minExtent)).clamp(
        0.0,
        1.0,
      );
    } else if (pinned) {
      collapse = 1;
    }
    final title = largeTitle;
    // Large titles collapse; a plain pinned bar condenses as soon as content scrolls under it.
    final condense = title == null ? (pinned ? collapse : 1.0) : Curves.easeOut.transform(collapse);
    final top = MediaQuery.paddingOf(context).top;
    return Stack(
      fit: StackFit.expand,
      children: [
        GlassBar(condense: condense),
        if (title != null)
          Positioned(
            left: 20,
            right: 96,
            bottom: 10,
            child: Opacity(
              opacity: (1 - collapse * 1.6).clamp(0.0, 1.0),
              child: Transform.scale(
                scale: 1 - 0.16 * collapse,
                alignment: Alignment.bottomLeft,
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(color: tokens.ink, height: 1.05),
                ),
              ),
            ),
          ),
        if (title != null)
          Positioned(
            left: 20,
            top: top,
            height: kToolbarHeight,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Opacity(
                opacity: ((collapse - 0.55) / 0.45).clamp(0.0, 1.0),
                child: Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: tokens.ink)),
              ),
            ),
          ),
      ],
    );
  }
}

class _ImmichLogoWithText extends StatelessWidget {
  const _ImmichLogoWithText();

  @override
  Widget build(BuildContext context) => AnimatedOpacity(
    opacity: IconTheme.of(context).opacity ?? 1,
    duration: kThemeChangeDuration,
    child: SvgPicture.asset(
      context.isDarkTheme ? 'assets/immich-logo-inline-dark.svg' : 'assets/immich-logo-inline-light.svg',
      height: 40,
    ),
  );
}

class _ProfileIndicator extends ConsumerWidget {
  const _ProfileIndicator();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final bool versionWarningPresent = ref.watch(versionWarningPresentProvider(user));
    final serverInfoState = ref.watch(serverInfoProvider);

    const widgetSize = 32.0;

    // TODO: remove this when update Flutter version newer than 3.35.7
    final isIpad = defaultTargetPlatform == TargetPlatform.iOS && !context.isMobile;

    void toggleReadonlyMode() {
      final isReadonlyModeEnabled = ref.read(readonlyModeProvider);
      ref.read(readonlyModeProvider.notifier).toggleReadonlyMode();

      context.scaffoldMessenger.showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 2),
          content: Text(
            isReadonlyModeEnabled ? context.t.readonly_mode_disabled : context.t.readonly_mode_enabled,
            style: context.textTheme.bodyLarge?.copyWith(color: context.primaryColor),
          ),
        ),
      );
    }

    return IconButton(
      onPressed: () => showDialog(
        context: context,
        useRootNavigator: false,
        barrierDismissible: !isIpad,
        builder: (ctx) => const ImmichAppBarDialog(),
      ),
      onLongPress: () => toggleReadonlyMode(),
      icon: Badge(
        label: _BadgeLabel(
          Icon(
            Icons.info,
            color: serverInfoState.versionStatus == VersionStatus.error
                ? context.colorScheme.error
                : context.primaryColor,
            size: widgetSize / 2 - 3,
            semanticLabel: context.t.new_version_available,
          ),
        ),
        backgroundColor: Colors.transparent,
        alignment: Alignment.bottomRight,
        isLabelVisible: versionWarningPresent,
        offset: const Offset(-2, -12),
        child: user == null
            ? const Icon(Icons.face_outlined, size: widgetSize)
            : Semantics(
                label: context.t.logged_in_as(user: user.name),
                child: AbsorbPointer(
                  child: Builder(
                    builder: (context) => UserCircleAvatar(
                      size: 34,
                      user: user,
                      opacity: IconTheme.of(context).opacity ?? 1,
                      hasBorder: true,
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

const double _kBadgeWidgetSize = 30.0;

class _BackupIndicator extends ConsumerWidget {
  const _BackupIndicator();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final backupEnabled = ref.watch(appConfigProvider.select((c) => c.backup.enabled));
    final hasError = ref.watch(backupProvider.select((state) => state.error != BackupError.none));
    final isUploading = ref.watch(backupProvider.select((state) => state.uploadItems.isNotEmpty));
    final indicatorIcon = _getBackupBadgeIcon(
      context,
      backupEnabled: backupEnabled,
      hasError: hasError,
      isUploading: isUploading,
    );

    return IconButton(
      onPressed: () => context.pushRoute(const BackupRoute()),
      icon: Badge(
        label: indicatorIcon,
        backgroundColor: Colors.transparent,
        alignment: Alignment.bottomRight,
        isLabelVisible: indicatorIcon != null,
        offset: const Offset(-2, -12),
        child: Icon(Icons.backup_rounded, size: _kBadgeWidgetSize, color: context.primaryColor),
      ),
    );
  }

  Widget? _getBackupBadgeIcon(
    BuildContext context, {
    required bool backupEnabled,
    required bool hasError,
    required bool isUploading,
  }) {
    final isDarkTheme = context.isDarkTheme;
    final iconColor = isDarkTheme ? Colors.white : Colors.black;

    if (!backupEnabled) {
      return _BadgeLabel(
        Icon(
          Icons.cloud_off_rounded,
          size: 9,
          color: iconColor,
          semanticLabel: context.t.backup_controller_page_backup,
        ),
      );
    }

    if (hasError) {
      return _BadgeLabel(
        Icon(
          Icons.warning_rounded,
          size: 12,
          color: context.colorScheme.error,
          semanticLabel: context.t.backup_controller_page_backup,
        ),
        backgroundColor: context.colorScheme.errorContainer,
      );
    }

    if (isUploading) {
      return _BadgeLabel(
        Container(
          padding: const EdgeInsets.all(3.5),
          child: Theme(
            data: context.themeData.copyWith(
              progressIndicatorTheme: context.themeData.progressIndicatorTheme.copyWith(year2023: true),
            ),
            child: CircularProgressIndicator(
              strokeWidth: 2,
              strokeCap: StrokeCap.round,
              valueColor: AlwaysStoppedAnimation<Color>(iconColor),
              semanticsLabel: context.t.backup_controller_page_backup,
            ),
          ),
        ),
      );
    }

    return _BadgeLabel(
      Icon(Icons.check_outlined, size: 9, color: iconColor, semanticLabel: context.t.backup_controller_page_backup),
    );
  }
}

class _BadgeLabel extends StatelessWidget {
  final Widget indicator;
  final Color? backgroundColor;

  const _BadgeLabel(this.indicator, {this.backgroundColor});

  @override
  Widget build(BuildContext context) {
    final opacity = IconTheme.of(context).opacity ?? 1;

    return Container(
      width: _kBadgeWidgetSize / 2,
      height: _kBadgeWidgetSize / 2,
      decoration: BoxDecoration(
        color: (backgroundColor ?? context.colorScheme.surfaceContainer).withValues(alpha: opacity),
        border: Border.all(color: context.colorScheme.outline.withValues(alpha: .3 * opacity)),
        borderRadius: BorderRadius.circular(_kBadgeWidgetSize / 2),
      ),
      child: indicator,
    );
  }
}

class _SyncStatusIndicator extends ConsumerStatefulWidget {
  const _SyncStatusIndicator();

  @override
  ConsumerState<_SyncStatusIndicator> createState() => _SyncStatusIndicatorState();
}

class _SyncStatusIndicatorState extends ConsumerState<_SyncStatusIndicator> with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _dismissalController;
  late Animation<double> _rotationAnimation;
  late Animation<double> _dismissalAnimation;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(duration: const Duration(seconds: 2), vsync: this);
    _dismissalController = AnimationController(duration: const Duration(milliseconds: 300), vsync: this);
    _rotationAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_rotationController);
    _dismissalAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _dismissalController, curve: Curves.easeOutQuart));
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _dismissalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final syncStatus = ref.watch(syncStatusProvider);
    final isSyncing = syncStatus.isRemoteSyncing || syncStatus.isLocalSyncing;

    // Control animations based on sync status
    if (isSyncing) {
      if (!_rotationController.isAnimating) {
        unawaited(_rotationController.repeat());
      }
      _dismissalController.reset();
    } else {
      _rotationController.stop();
      if (_dismissalController.status == AnimationStatus.dismissed) {
        unawaited(_dismissalController.forward());
      }
    }

    // Don't show anything if not syncing and dismissal animation is complete
    if (!isSyncing && _dismissalController.status == AnimationStatus.completed) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.all(8),
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: IconTheme.of(context).opacity ?? 1),
        duration: kThemeChangeDuration,
        builder: (context, opacity, child) {
          return AnimatedBuilder(
            animation: Listenable.merge([_rotationAnimation, _dismissalAnimation]),
            builder: (context, child) {
              final dismissalValue = isSyncing ? 1.0 : _dismissalAnimation.value;
              return IconTheme(
                data: IconTheme.of(context).copyWith(opacity: opacity * dismissalValue),
                child: Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..scaleByDouble(dismissalValue, dismissalValue, dismissalValue, 1.0)
                    ..rotateZ(-_rotationAnimation.value * 2 * math.pi),
                  child: const Icon(Icons.sync),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
