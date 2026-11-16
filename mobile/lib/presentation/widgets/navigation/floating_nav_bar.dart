import 'package:flutter/material.dart';
import 'package:immich_mobile/presentation/widgets/common/press_scale.dart';
import 'package:immich_mobile/theme/premium_tokens.dart';
import 'package:immich_mobile/theme/solid/solid.dart';

class FloatingNavItem {
  const FloatingNavItem({required this.label, required this.icon, required this.selectedIcon, this.enabled = true});

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final bool enabled;
}

/// Solid, fully rounded tab bar that floats above the content, after the AIOStreams mobile nav.
///
/// Equal width tabs show the icon above a tiny label. The active tab sits on a white 10% pill
/// that slides between tabs, inactive tabs use the muted gray. The bar slides off the bottom
/// edge while [visible] is false (the shell hides it on scroll down).
class FloatingNavBar extends StatelessWidget {
  const FloatingNavBar({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
    this.visible = true,
  });

  final List<FloatingNavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final bool visible;

  /// Key of the pill behind the active tab.
  @visibleForTesting
  static const activePillKey = ValueKey<String>('nav_active_pill');

  /// Maximum width of the bar (28rem).
  static const double maxWidth = 448;

  /// Height of the bar content: 6 px padding around a tab of icon plus 0.65rem label.
  static const double barHeight = 62;

  /// Distance from the screen edges (px-3).
  static const double edgeMargin = 12;

  static const double _padding = 6;
  static const double _gap = 4;

  @override
  Widget build(BuildContext context) {
    final tokens = context.solid;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final reduced = PremiumMotion.reduced(context);
    final duration = reduced ? Duration.zero : SolidTokens.duration;

    return SizedBox(
      height: barHeight + edgeMargin + bottomInset,
      child: Padding(
        padding: EdgeInsets.fromLTRB(edgeMargin, 0, edgeMargin, edgeMargin + bottomInset),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: maxWidth),
            // translateY 100% on hide, 200 ms ease-out.
            child: AnimatedSlide(
              offset: visible ? Offset.zero : const Offset(0, 1.6),
              duration: duration,
              curve: SolidTokens.curve,
              child: RepaintBoundary(
                child: SolidSurface(
                  radius: SolidTokens.radiusPill,
                  floating: true,
                  padding: const EdgeInsets.all(_padding),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final count = items.length;
                      final tabWidth = (constraints.maxWidth - _gap * (count - 1)) / count;
                      return SizedBox(
                        height: barHeight - _padding * 2 - 2,
                        child: Stack(
                          children: [
                            AnimatedPositioned(
                              duration: duration,
                              curve: SolidTokens.curve,
                              left: selectedIndex * (tabWidth + _gap),
                              width: tabWidth,
                              top: 0,
                              bottom: 0,
                              child: DecoratedBox(
                                key: activePillKey,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.10),
                                  borderRadius: BorderRadius.circular(SolidTokens.radiusPill),
                                ),
                              ),
                            ),
                            for (var i = 0; i < count; i++)
                              Positioned(
                                left: i * (tabWidth + _gap),
                                width: tabWidth,
                                top: 0,
                                bottom: 0,
                                child: _NavTab(
                                  item: items[i],
                                  selected: i == selectedIndex,
                                  activeColor: tokens.inkStrong,
                                  inactiveColor: tokens.inactive,
                                  duration: duration,
                                  onTap: () => onSelected(i),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavTab extends StatelessWidget {
  const _NavTab({
    required this.item,
    required this.selected,
    required this.activeColor,
    required this.inactiveColor,
    required this.duration,
    required this.onTap,
  });

  final FloatingNavItem item;
  final bool selected;
  final Color activeColor;
  final Color inactiveColor;
  final Duration duration;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? activeColor : inactiveColor;
    // 0.65rem label, medium weight.
    final label = Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 10.4, fontWeight: FontWeight.w500);

    return Semantics(
      button: true,
      selected: selected,
      enabled: item.enabled,
      label: item.label,
      excludeSemantics: true,
      onTap: item.enabled ? onTap : null,
      child: PressScale(
        enabled: item.enabled,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: item.enabled ? onTap : null,
          child: Opacity(
            opacity: item.enabled ? 1 : 0.38,
            child: Center(
              child: TweenAnimationBuilder<Color?>(
                tween: ColorTween(end: color),
                duration: duration,
                curve: SolidTokens.curve,
                builder: (context, animated, _) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(selected ? item.selectedIcon : item.icon, size: 22, color: animated),
                    const SizedBox(height: 2),
                    Text(
                      item.label,
                      style: label?.copyWith(color: animated),
                      textScaler: MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.15),
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
