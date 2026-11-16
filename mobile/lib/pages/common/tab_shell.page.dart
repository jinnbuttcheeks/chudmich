import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:immich_mobile/constants/constants.dart';
import 'package:immich_mobile/domain/models/events.model.dart';
import 'package:immich_mobile/domain/utils/event_stream.dart';
import 'package:immich_mobile/extensions/build_context_extensions.dart';
import 'package:immich_mobile/generated/translations.g.dart';
import 'package:immich_mobile/presentation/pages/search/paginated_search.provider.dart';
import 'package:immich_mobile/presentation/widgets/navigation/floating_nav_bar.dart';
import 'package:immich_mobile/providers/haptic_feedback.provider.dart';
import 'package:immich_mobile/providers/infrastructure/album.provider.dart';
import 'package:immich_mobile/providers/infrastructure/memory.provider.dart';
import 'package:immich_mobile/providers/infrastructure/readonly_mode.provider.dart';
import 'package:immich_mobile/providers/search/search_input_focus.provider.dart';
import 'package:immich_mobile/providers/tab.provider.dart';
import 'package:immich_mobile/routing/router.dart';
import 'package:immich_mobile/theme/premium_tokens.dart';

@RoutePage()
class TabShellPage extends ConsumerStatefulWidget {
  const TabShellPage({super.key});

  @override
  ConsumerState<TabShellPage> createState() => _TabShellPageState();
}

class _TabShellPageState extends ConsumerState<TabShellPage> {
  /// False while the user scrolls down: the floating bar slides away, and returns on scroll up.
  final ValueNotifier<bool> _navVisible = ValueNotifier(true);

  @override
  void dispose() {
    _navVisible.dispose();
    super.dispose();
  }

  bool _onScroll(UserScrollNotification n) {
    if (n.depth != 0 || n.metrics.axis != Axis.vertical) {
      return false;
    }
    if (n.direction == ScrollDirection.reverse) {
      _navVisible.value = false;
    } else if (n.direction == ScrollDirection.forward || n.metrics.extentBefore == 0) {
      _navVisible.value = true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final isScreenLandscape = context.orientation == Orientation.landscape;
    final isReadonlyModeEnabled = ref.watch(readonlyModeProvider);

    final navigationItems = [
      FloatingNavItem(label: context.t.photos, icon: Icons.photo_library_outlined, selectedIcon: Icons.photo_library),
      FloatingNavItem(
        label: context.t.search,
        icon: Icons.search_rounded,
        selectedIcon: Icons.search,
        enabled: !isReadonlyModeEnabled,
      ),
      FloatingNavItem(
        label: context.t.albums,
        icon: Icons.photo_album_outlined,
        selectedIcon: Icons.photo_album_rounded,
        enabled: !isReadonlyModeEnabled,
      ),
      FloatingNavItem(
        label: context.t.library$,
        icon: Icons.space_dashboard_outlined,
        selectedIcon: Icons.space_dashboard_rounded,
        enabled: !isReadonlyModeEnabled,
      ),
    ];

    Widget navigationRail(TabsRouter tabsRouter) {
      return NavigationRail(
        destinations: navigationItems
            .map(
              (e) => NavigationRailDestination(
                icon: Icon(e.icon),
                label: Text(e.label),
                selectedIcon: Icon(e.selectedIcon, color: context.primaryColor),
                disabled: !e.enabled,
              ),
            )
            .toList(),
        onDestinationSelected: (index) => _onNavigationSelected(tabsRouter, index, ref),
        selectedIndex: tabsRouter.activeIndex,
        labelType: NavigationRailLabelType.all,
        groupAlignment: 0.0,
      );
    }

    return AutoTabsRouter(
      routes: const [MainTimelineRoute(), SearchRoute(), AlbumsRoute(), LibraryRoute()],
      duration: PremiumMotion.medium,
      transitionBuilder: (context, child, animation) {
        if (PremiumMotion.reduced(context)) {
          return FadeTransition(opacity: animation, child: child);
        }
        // Fade plus a small rise that eases with a spring; the outgoing tab just fades.
        return FadeTransition(
          opacity: animation,
          child: AnimatedBuilder(
            animation: animation,
            builder: (context, child) => Transform.translate(
              offset: Offset(0, (1 - PremiumMotion.standard.transform(animation.value)) * 14),
              child: child,
            ),
            child: child,
          ),
        );
      },
      builder: (context, child) {
        final tabsRouter = AutoTabsRouter.of(context);
        return PopScope(
          canPop: tabsRouter.activeIndex == 0,
          onPopInvokedWithResult: (didPop, _) => !didPop ? tabsRouter.setActiveIndex(0) : null,
          child: Scaffold(
            resizeToAvoidBottomInset: false,
            // Content scrolls behind the floating bar; MediaQuery bottom padding grows by the bar's height.
            extendBody: true,
            body: NotificationListener<UserScrollNotification>(
              onNotification: _onScroll,
              child: isScreenLandscape
                  ? Row(
                      children: [
                        navigationRail(tabsRouter),
                        const VerticalDivider(),
                        Expanded(child: child),
                      ],
                    )
                  : child,
            ),
            bottomNavigationBar: _BottomNavigationBar(
              tabsRouter: tabsRouter,
              items: navigationItems,
              visible: _navVisible,
            ),
          ),
        );
      },
    );
  }
}

void _onNavigationSelected(TabsRouter router, int index, WidgetRef ref) {
  // On Photos page menu tapped
  if (router.activeIndex == kPhotoTabIndex && index == kPhotoTabIndex) {
    EventStream.shared.emit(const ScrollToTopEvent());
  }

  if (index == kPhotoTabIndex) {
    ref.invalidate(memoryLaneProvider);
  }

  if (router.activeIndex != kSearchTabIndex && index == kSearchTabIndex) {
    ref.read(searchPreFilterProvider.notifier).clear();
  }

  // On Search page tapped
  if (router.activeIndex == kSearchTabIndex && index == kSearchTabIndex) {
    ref.read(searchInputFocusProvider).requestFocus();
  }

  // Album page
  if (index == kAlbumTabIndex) {
    unawaited(ref.read(remoteAlbumProvider.notifier).refresh());
  }

  ref.read(hapticFeedbackProvider.notifier).selectionClick();
  router.setActiveIndex(index);
  ref.read(tabProvider.notifier).state = TabEnum.values[index];
}

class _BottomNavigationBar extends ConsumerStatefulWidget {
  const _BottomNavigationBar({required this.tabsRouter, required this.items, required this.visible});

  final List<FloatingNavItem> items;
  final TabsRouter tabsRouter;
  final ValueListenable<bool> visible;

  @override
  ConsumerState createState() => _BottomNavigationBarState();
}

class _BottomNavigationBarState extends ConsumerState<_BottomNavigationBar> {
  bool hideNavigationBar = false;
  StreamSubscription? _eventSubscription;

  @override
  void initState() {
    super.initState();
    _eventSubscription = EventStream.shared.listen<MultiSelectToggleEvent>(_onEvent);
  }

  void _onEvent(MultiSelectToggleEvent event) {
    setState(() {
      hideNavigationBar = event.isEnabled;
    });
  }

  @override
  void dispose() {
    unawaited(_eventSubscription?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isScreenLandscape = context.orientation == Orientation.landscape;

    if (isScreenLandscape || hideNavigationBar) {
      return const SizedBox.shrink();
    }

    return ValueListenableBuilder<bool>(
      valueListenable: widget.visible,
      builder: (context, visible, _) => FloatingNavBar(
        items: widget.items,
        selectedIndex: widget.tabsRouter.activeIndex,
        visible: visible,
        onSelected: (index) => _onNavigationSelected(widget.tabsRouter, index, ref),
      ),
    );
  }
}
