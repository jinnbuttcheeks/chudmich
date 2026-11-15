import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:immich_mobile/presentation/widgets/common/press_scale.dart';
import 'package:immich_mobile/theme/premium_tokens.dart';

class FloatingNavItem {
  const FloatingNavItem({required this.label, required this.icon, required this.selectedIcon, this.enabled = true});

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final bool enabled;
}

/// Pill shaped tab bar that floats above the content.
///
/// A single spring driven position value (a fractional tab index) feeds every
/// visual: the active pill stretches between tabs, the active tab grows to show
/// its label and the icons cross fade. Because the position is physical, a new
/// tap during a transition re-targets the spring and keeps its velocity.
class FloatingNavBar extends StatefulWidget {
  const FloatingNavBar({super.key, required this.items, required this.selectedIndex, required this.onSelected});

  final List<FloatingNavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  /// How much wider the active tab is than an inactive one (in inactive tab units).
  static const double activeExtraWeight = 1.35;

  /// Left offsets and widths of every tab for a fractional [position].
  ///
  /// The sum of all widths is always [totalWidth]; the active tab borrows space
  /// evenly from the others, so the layout is continuous while the pill moves.
  static List<({double left, double width})> layout({
    required int count,
    required double position,
    required double totalWidth,
    double extra = activeExtraWeight,
  }) {
    final weights = List.generate(count, (i) => 1 + extra * emphasis(i, position));
    final unit = totalWidth / weights.fold<double>(0, (a, b) => a + b);
    var left = 0.0;
    return [
      for (final w in weights)
        (() {
          final rect = (left: left, width: w * unit);
          left += w * unit;
          return rect;
        })(),
    ];
  }

  /// 1 when [position] is exactly on [index], falling to 0 one tab away.
  static double emphasis(int index, double position) => (1 - (index - position).abs()).clamp(0.0, 1.0);

  @override
  State<FloatingNavBar> createState() => _FloatingNavBarState();
}

class _FloatingNavBarState extends State<FloatingNavBar> with TickerProviderStateMixin {
  static final _spring = SpringDescription.withDampingRatio(mass: 1, stiffness: 480, ratio: 0.8);

  late final AnimationController _position = AnimationController.unbounded(
    vsync: this,
    value: widget.selectedIndex.toDouble(),
  );
  late final AnimationController _entrance = AnimationController(vsync: this, duration: PremiumMotion.slow);
  late final CurvedAnimation _entranceCurve = CurvedAnimation(parent: _entrance, curve: PremiumMotion.gentle);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_entrance.value == 0 && !_entrance.isAnimating) {
      if (PremiumMotion.reduced(context)) {
        _entrance.value = 1;
      } else {
        _entrance.forward();
      }
    }
  }

  @override
  void didUpdateWidget(FloatingNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex == widget.selectedIndex) {
      return;
    }
    final target = widget.selectedIndex.toDouble();
    if (PremiumMotion.reduced(context)) {
      _position.value = target;
      return;
    }
    // Hand the current velocity to the new spring so interrupted taps stay fluid.
    _position.animateWith(SpringSimulation(_spring, _position.value, target, _position.velocity));
  }

  @override
  void dispose() {
    _position.dispose();
    _entranceCurve.dispose();
    _entrance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.premium;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final entrance = _entranceCurve;

    return SizedBox(
      height: PremiumTokens.navBarHeight + PremiumTokens.navBarGap + bottomInset,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          PremiumTokens.navBarHorizontalMargin,
          0,
          PremiumTokens.navBarHorizontalMargin,
          PremiumTokens.navBarGap + bottomInset,
        ),
        child: AnimatedBuilder(
          animation: entrance,
          builder: (context, child) {
            final t = entrance.value;
            return Opacity(
              opacity: t.clamp(0.0, 1.0),
              child: Transform.translate(offset: Offset(0, (1 - t) * 28), child: child),
            );
          },
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(PremiumTokens.radiusPill),
              boxShadow: [BoxShadow(color: tokens.floatingShadow, blurRadius: 28, offset: const Offset(0, 10))],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(PremiumTokens.radiusPill),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: PremiumTokens.blurSigma, sigmaY: PremiumTokens.blurSigma),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: tokens.floatingSurface,
                    borderRadius: BorderRadius.circular(PremiumTokens.radiusPill),
                    border: Border.all(color: tokens.floatingBorder, width: 0.8),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(PremiumTokens.space1 + 2),
                    child: LayoutBuilder(
                      builder: (context, constraints) => AnimatedBuilder(
                        animation: _position,
                        builder: (context, _) => _buildTabs(context, constraints.maxWidth, tokens),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabs(BuildContext context, double width, PremiumTokens tokens) {
    final count = widget.items.length;
    final position = _position.value.clamp(0.0, count - 1.0);
    final rects = FloatingNavBar.layout(count: count, position: position, totalWidth: width);

    final lower = position.floor();
    final upper = position.ceil();
    final frac = position - lower;
    final pillLeft = ui.lerpDouble(rects[lower].left, rects[upper].left, frac)!;
    final pillWidth = ui.lerpDouble(rects[lower].width, rects[upper].width, frac)!;
    const height = PremiumTokens.navBarHeight - (PremiumTokens.space1 + 2) * 2;

    return SizedBox(
      height: height,
      child: Stack(
        children: [
          Positioned(
            left: pillLeft,
            width: pillWidth,
            top: 0,
            bottom: 0,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: tokens.activePill,
                borderRadius: BorderRadius.circular(PremiumTokens.radiusPill),
              ),
            ),
          ),
          for (var i = 0; i < count; i++)
            Positioned(
              left: rects[i].left,
              width: rects[i].width,
              top: 0,
              bottom: 0,
              child: _NavTab(
                item: widget.items[i],
                emphasis: FloatingNavBar.emphasis(i, position),
                selected: i == widget.selectedIndex,
                tokens: tokens,
                onTap: () => widget.onSelected(i),
              ),
            ),
        ],
      ),
    );
  }
}

class _NavTab extends StatelessWidget {
  const _NavTab({
    required this.item,
    required this.emphasis,
    required this.selected,
    required this.tokens,
    required this.onTap,
  });

  final FloatingNavItem item;
  final double emphasis;
  final bool selected;
  final PremiumTokens tokens;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = Color.lerp(tokens.inactiveIcon, tokens.onActivePill, emphasis)!;
    final label = Theme.of(context).textTheme.labelLarge?.copyWith(color: color, fontWeight: FontWeight.w600);

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
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Opacity(
                          opacity: 1 - emphasis,
                          child: Icon(item.icon, color: color),
                        ),
                        Opacity(
                          opacity: emphasis,
                          child: Icon(item.selectedIcon, color: color),
                        ),
                      ],
                    ),
                    ClipRect(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        widthFactor: emphasis,
                        child: Opacity(
                          opacity: emphasis * emphasis,
                          child: Padding(
                            padding: const EdgeInsets.only(left: PremiumTokens.space2 - 2),
                            child: Text(item.label, style: label, maxLines: 1, softWrap: false),
                          ),
                        ),
                      ),
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
