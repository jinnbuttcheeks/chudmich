import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:immich_mobile/presentation/widgets/common/press_scale.dart';
import 'package:immich_mobile/theme/glass/glass_math.dart';
import 'package:immich_mobile/theme/glass/glass_surface.dart';
import 'package:immich_mobile/theme/glass/glass_tokens.dart';
import 'package:immich_mobile/theme/premium_tokens.dart';

/// Round glass button for icons (back, close, actions floating over photos).
class GlassIconButton extends StatelessWidget {
  const GlassIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.size = 44,
    this.iconSize = 22,
    this.color,
    this.tint,
    this.blur = true,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final double size;
  final double iconSize;
  final Color? color;

  /// Overrides the glass tint, for example dark glass over photos.
  final Color? tint;
  final bool blur;

  @override
  Widget build(BuildContext context) {
    final tokens = context.glass;
    final button = PressScale(
      enabled: onPressed != null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        child: GlassSurface(
          variant: GlassVariant.thin,
          radius: size / 2,
          blur: blur,
          shadow: blur,
          tint: tint,
          child: SizedBox.square(
            dimension: size,
            child: Icon(
              icon,
              size: iconSize,
              color: (color ?? tokens.ink).withValues(alpha: onPressed == null ? 0.4 : 1),
            ),
          ),
        ),
      ),
    );
    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: tooltip,
      excludeSemantics: tooltip != null,
      child: tooltip == null ? button : Tooltip(message: tooltip, child: button),
    );
  }
}

/// Pill shaped glass button with an optional leading icon. [prominent] tints
/// the glass with the accent colour for the primary action of a screen.
class GlassButton extends StatelessWidget {
  const GlassButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.prominent = false,
    this.blur = true,
    this.expand = false,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool prominent;
  final bool blur;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final tokens = context.glass;
    final fg = prominent ? (tokens.isDark ? Colors.black : Colors.white) : tokens.ink;
    final text = Theme.of(context).textTheme.labelLarge?.copyWith(color: fg, fontWeight: FontWeight.w600, fontSize: 15);
    return PressScale(
      enabled: onPressed != null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        child: GlassSurface(
          variant: GlassVariant.thin,
          radius: 999,
          blur: blur,
          tint: prominent ? tokens.accent : null,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          child: Row(
            mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[Icon(icon, size: 20, color: fg), const SizedBox(width: 8)],
              Flexible(
                child: Text(label, style: text, maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Selectable glass chip. Selection springs the accent fill in. Chips live in
/// scrolling rows, so they use fake glass (no backdrop filter) by design.
class GlassChip extends StatelessWidget {
  const GlassChip({super.key, required this.label, required this.selected, required this.onTap, this.icon});

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final tokens = context.glass;
    final duration = PremiumMotion.resolve(context, PremiumMotion.medium);
    return PressScale(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(end: selected ? 1 : 0),
          duration: duration,
          curve: PremiumMotion.standard,
          builder: (context, t, _) {
            final fg = Color.lerp(tokens.ink, tokens.isDark ? Colors.black : Colors.white, t.clamp(0.0, 1.0))!;
            return GlassSurface(
              variant: GlassVariant.thin,
              radius: 999,
              blur: false,
              shadow: false,
              tint: Color.lerp(tokens.tint, tokens.accent, t.clamp(0.0, 1.0)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[Icon(icon, size: 18, color: fg), const SizedBox(width: 6)],
                  Text(
                    label,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(color: fg, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Rounded icon badge used in grouped settings rows and dashboard cards.
class GlassIconBadge extends StatelessWidget {
  const GlassIconBadge({super.key, required this.icon, this.color, this.size = 34});

  final IconData icon;
  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final base = color ?? context.glass.accent;
    return DecoratedBox(
      decoration: ShapeDecoration(
        shape: RoundedSuperellipseBorder(borderRadius: BorderRadius.circular(size * 0.3)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color.lerp(base, Colors.white, 0.28)!, base],
        ),
      ),
      child: SizedBox.square(
        dimension: size,
        child: Icon(icon, size: size * 0.56, color: Colors.white),
      ),
    );
  }
}

/// Inset group of rows on one glass card (iOS settings style).
class GlassGroup extends StatelessWidget {
  const GlassGroup({super.key, required this.children, this.header, this.footer, this.margin});

  final List<Widget> children;
  final String? header;
  final String? footer;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final tokens = context.glass;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: margin ?? const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (header != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                header!,
                style: textTheme.labelMedium?.copyWith(color: tokens.inkSecondary, fontWeight: FontWeight.w600),
              ),
            ),
          GlassSurface(
            blur: false,
            shadow: false,
            radius: 24,
            child: Column(
              children: [
                for (var i = 0; i < children.length; i++) ...[
                  if (i > 0)
                    Divider(height: 0.5, thickness: 0.5, indent: 62, color: tokens.ink.withValues(alpha: 0.08)),
                  children[i],
                ],
              ],
            ),
          ),
          if (footer != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text(footer!, style: textTheme.bodySmall?.copyWith(color: tokens.inkSecondary)),
            ),
        ],
      ),
    );
  }
}

/// Row in a [GlassGroup].
class GlassGroupTile extends StatelessWidget {
  const GlassGroupTile({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.iconColor,
    this.leading,
    this.trailing,
    this.onTap,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final Color? iconColor;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.glass;
    final textTheme = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            if (leading != null || icon != null) ...[
              leading ?? GlassIconBadge(icon: icon!, color: iconColor),
              const SizedBox(width: 14),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: textTheme.bodyLarge?.copyWith(color: tokens.ink, fontWeight: FontWeight.w500),
                  ),
                  if (subtitle != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(subtitle!, style: textTheme.bodySmall?.copyWith(color: tokens.inkSecondary)),
                    ),
                ],
              ),
            ),
            if (trailing != null)
              trailing!
            else if (onTap != null)
              Icon(Icons.chevron_right_rounded, color: tokens.inkSecondary),
          ],
        ),
      ),
    );
  }
}

/// Springs [child] in and out: it fades and slides by [offset] while [visible]
/// flips. Interruptible (the spring restarts from the current value and keeps
/// its velocity) and instant when the user disabled animations.
class GlassReveal extends StatefulWidget {
  const GlassReveal({
    super.key,
    required this.visible,
    required this.child,
    this.offset = const Offset(0, 24),
    this.opacity = 1,
  });

  final bool visible;
  final Widget child;

  /// Where the child rests while hidden, relative to its place when shown.
  final Offset offset;

  /// Extra opacity factor, for example while dragging a viewer away.
  final double opacity;

  @override
  State<GlassReveal> createState() => _GlassRevealState();
}

class _GlassRevealState extends State<GlassReveal> with SingleTickerProviderStateMixin {
  static final _spring = SpringDescription.withDampingRatio(mass: 1, stiffness: 420, ratio: 0.86);

  late final AnimationController _controller = AnimationController.unbounded(
    vsync: this,
    value: widget.visible ? 1 : 0,
  );

  @override
  void didUpdateWidget(GlassReveal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.visible == widget.visible) {
      return;
    }
    final target = widget.visible ? 1.0 : 0.0;
    if (PremiumMotion.reduced(context)) {
      _controller.value = target;
    } else {
      _controller.animateWith(SpringSimulation(_spring, _controller.value, target, _controller.velocity));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !widget.visible,
      child: AnimatedBuilder(
        animation: _controller,
        child: widget.child,
        builder: (context, child) {
          final t = _controller.value;
          if (t <= 0.001 && !widget.visible) {
            return const SizedBox.shrink();
          }
          return Opacity(
            opacity: (t * widget.opacity).clamp(0.0, 1.0),
            child: Transform.translate(offset: widget.offset * (1 - t), child: child),
          );
        },
      ),
    );
  }
}
