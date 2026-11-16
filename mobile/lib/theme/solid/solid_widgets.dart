import 'package:flutter/material.dart';
import 'package:immich_mobile/presentation/widgets/common/press_scale.dart';
import 'package:immich_mobile/theme/premium_tokens.dart';
import 'package:immich_mobile/theme/solid/solid_surface.dart';
import 'package:immich_mobile/theme/solid/solid_tokens.dart';

/// Round icon button (back, close, actions). Over photos pass [SolidTokens.overPhoto] as [fill].
class SolidIconButton extends StatelessWidget {
  const SolidIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.size = 44,
    this.iconSize = 22,
    this.color,
    this.fill,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final double size;
  final double iconSize;
  final Color? color;

  /// Overrides the fill, for example a scrim color over photos.
  final Color? fill;

  @override
  Widget build(BuildContext context) {
    final tokens = context.solid;
    final button = PressScale(
      enabled: onPressed != null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        child: SolidSurface(
          radius: size / 2,
          color: fill ?? tokens.panel,
          bordered: fill == null,
          child: SizedBox.square(
            dimension: size,
            child: Icon(
              icon,
              size: iconSize,
              color: (color ?? tokens.inkStrong).withValues(alpha: onPressed == null ? 0.4 : 1),
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

/// Button with an optional leading icon. [prominent] is the primary action: accent fill at about 70%
/// with a lighter accent border and white text.
class SolidButton extends StatelessWidget {
  const SolidButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.prominent = false,
    this.expand = false,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool prominent;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final tokens = context.solid;
    final fg = prominent ? Colors.white : tokens.ink;
    final text = Theme.of(context).textTheme.labelLarge?.copyWith(color: fg, fontWeight: FontWeight.w600, fontSize: 15);
    final surface = prominent
        ? DecoratedBox(
            decoration: BoxDecoration(
              color: tokens.accentFill,
              borderRadius: BorderRadius.circular(SolidTokens.radius),
              border: Border.all(color: tokens.accentBorder),
            ),
            child: _content(fg, text),
          )
        : SolidSurface(radius: SolidTokens.radius, color: tokens.panel, child: _content(fg, text));
    return PressScale(
      enabled: onPressed != null,
      child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: onPressed, child: surface),
    );
  }

  Widget _content(Color fg, TextStyle? text) => Padding(
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
  );
}

/// Selectable pill chip. Selected is the white pill with dark text of the AIOStreams pill tabs; the
/// others sit on the deep panel.
class SolidChip extends StatelessWidget {
  const SolidChip({super.key, required this.label, required this.selected, required this.onTap, this.icon});

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final tokens = context.solid;
    final fg = selected ? (tokens.isDark ? Colors.black : Colors.white) : tokens.inactive;
    return PressScale(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: PremiumMotion.resolve(context, SolidTokens.duration),
          curve: SolidTokens.curve,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: BoxDecoration(
            color: selected ? tokens.inkStrong : tokens.panel,
            borderRadius: BorderRadius.circular(SolidTokens.radiusPill),
            border: selected ? null : Border.fromBorderSide(tokens.hairline),
          ),
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
        ),
      ),
    );
  }
}

/// Rounded icon badge used in grouped settings rows and dashboard cards: a flat tint of [color] with
/// the icon in that color.
class SolidIconBadge extends StatelessWidget {
  const SolidIconBadge({super.key, required this.icon, this.color, this.size = 34});

  final IconData icon;
  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final base = color ?? context.solid.accent;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: base.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(SolidTokens.radius),
      ),
      child: SizedBox.square(
        dimension: size,
        child: Icon(icon, size: size * 0.56, color: base),
      ),
    );
  }
}

/// Group of rows on one bordered card.
class SolidGroup extends StatelessWidget {
  const SolidGroup({super.key, required this.children, this.header, this.footer, this.margin});

  final List<Widget> children;
  final String? header;
  final String? footer;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final tokens = context.solid;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: margin ?? const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (header != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
              child: Text(
                header!,
                style: textTheme.labelMedium?.copyWith(color: tokens.mutedStrong, fontWeight: FontWeight.w600),
              ),
            ),
          SolidSurface(
            clip: true,
            child: Column(
              children: [
                for (var i = 0; i < children.length; i++) ...[
                  if (i > 0) Divider(height: 1, thickness: 1, indent: 62, color: tokens.border),
                  children[i],
                ],
              ],
            ),
          ),
          if (footer != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
              child: Text(footer!, style: textTheme.bodySmall?.copyWith(color: tokens.muted)),
            ),
        ],
      ),
    );
  }
}

/// Row in a [SolidGroup].
class SolidGroupTile extends StatelessWidget {
  const SolidGroupTile({
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
    final tokens = context.solid;
    final textTheme = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            if (leading != null || icon != null) ...[
              leading ?? SolidIconBadge(icon: icon!, color: iconColor),
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
                      child: Text(subtitle!, style: textTheme.bodySmall?.copyWith(color: tokens.muted)),
                    ),
                ],
              ),
            ),
            if (trailing != null)
              trailing!
            else if (onTap != null)
              Icon(Icons.chevron_right_rounded, color: tokens.muted),
          ],
        ),
      ),
    );
  }
}

/// Slides [child] in and out by [offset] and fades it while [visible] flips: 200 ms ease-out, like the
/// AIOStreams nav. The ticker only runs while animating, and the child paints without an opacity layer
/// once it is fully shown. Instant when the user disabled animations.
class SolidReveal extends StatefulWidget {
  const SolidReveal({
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
  State<SolidReveal> createState() => _SolidRevealState();
}

class _SolidRevealState extends State<SolidReveal> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: SolidTokens.duration,
    value: widget.visible ? 1 : 0,
  );
  late final CurvedAnimation _curve = CurvedAnimation(parent: _controller, curve: SolidTokens.curve);

  @override
  void didUpdateWidget(SolidReveal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.visible == widget.visible) {
      return;
    }
    if (PremiumMotion.reduced(context)) {
      _controller.value = widget.visible ? 1 : 0;
    } else if (widget.visible) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _curve.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !widget.visible,
      child: AnimatedBuilder(
        animation: _curve,
        child: widget.child,
        builder: (context, child) {
          final t = _curve.value;
          if (t <= 0.001 && !widget.visible) {
            return const SizedBox.shrink();
          }
          final alpha = (t * widget.opacity).clamp(0.0, 1.0);
          final moved = t >= 1 ? child! : Transform.translate(offset: widget.offset * (1 - t), child: child);
          return alpha >= 1 ? moved : Opacity(opacity: alpha, child: moved);
        },
      ),
    );
  }
}
