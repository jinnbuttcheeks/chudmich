import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:immich_mobile/theme/glass/glass_light.dart';
import 'package:immich_mobile/theme/glass/glass_math.dart';
import 'package:immich_mobile/theme/glass/glass_scroll_activity.dart';
import 'package:immich_mobile/theme/glass/glass_tokens.dart';

/// Liquid glass material.
///
/// Layers, bottom to top: soft outer shadow (outside the shape only), blurred
/// and saturation-boosted backdrop, translucent theme tint, inner glow lit from
/// the current light direction, and a specular rim that is brightest where the
/// light comes from. The shape is a continuous-corner rounded superellipse.
///
/// Backdrop blur is expensive, so surfaces take a slot from [GlassLayerBudget]
/// (4 by default). When none is free, or the surface is not visible, or the
/// platform asks for high contrast, it renders as fake glass: the same
/// layers with a denser tint and no [BackdropFilter].
class GlassSurface extends StatefulWidget {
  const GlassSurface({
    super.key,
    required this.child,
    this.variant = GlassVariant.regular,
    this.radius = 24,
    this.padding,
    this.essential = false,
    this.blur = true,
    this.shadow = true,
    this.tint,
    this.budget,
    this.scrollAware = false,
    this.activity,
  });

  final Widget child;
  final GlassVariant variant;
  final double radius;
  final EdgeInsetsGeometry? padding;

  /// Sheets and dialogs are essential: they always blur.
  final bool essential;

  /// False forces fake glass (use inside scrolling grids and lists).
  final bool blur;

  final bool shadow;

  /// Overrides the theme tint (for example to colour a button).
  final Color? tint;

  /// Test hook; defaults to [GlassLayerBudget.shared].
  final GlassLayerBudget? budget;

  /// Swaps the live blur for fake glass while a vertical scrollable moves
  /// ([GlassScrollActivity]). Use for surfaces that float over a scrolling grid.
  final bool scrollAware;

  /// Test hook for the scroll signal; defaults to [GlassScrollActivity.scrolling].
  final ValueListenable<bool>? activity;

  @override
  State<GlassSurface> createState() => _GlassSurfaceState();
}

class _GlassSurfaceState extends State<GlassSurface> {
  bool _blurring = false;
  GlassLayerBudget get _budget => widget.budget ?? GlassLayerBudget.shared;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateBudget();
  }

  @override
  void didUpdateWidget(GlassSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.budget != widget.budget) {
      (oldWidget.budget ?? GlassLayerBudget.shared).release(this);
    }
    _updateBudget();
  }

  void _updateBudget() {
    final visible = TickerMode.valuesOf(context).enabled;
    final contrast = MediaQuery.maybeHighContrastOf(context) ?? false;
    final want = widget.blur && visible && !contrast;
    final next = want && _budget.tryAcquire(this, essential: widget.essential);
    if (!next) {
      _budget.release(this);
    }
    _blurring = next;
  }

  @override
  void dispose() {
    _budget.release(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.scrollAware) {
      return GlassScrollGate(activity: widget.activity, builder: (context, fake) => _buildGlass(context, fake));
    }
    return _buildGlass(context, 0);
  }

  /// [fake] 0 is the live material, 1 is fake glass (no backdrop filter).
  Widget _buildGlass(BuildContext context, double fake) {
    final tokens = context.glass;
    final spec = GlassSpec.of(widget.variant, tokens.brightness);
    final light = GlassLightScope.of(context);
    final radius = BorderRadius.circular(widget.radius);
    final painter = _GlassPainter(
      tokens: tokens,
      spec: spec,
      radius: widget.radius,
      light: light,
      blurring: _blurring,
      fake: fake,
      tint: widget.tint,
    );

    Widget body = CustomPaint(
      painter: painter,
      foregroundPainter: _RimPainter(tokens: tokens, spec: spec, radius: widget.radius, light: light),
      child: widget.padding == null ? widget.child : Padding(padding: widget.padding!, child: widget.child),
    );

    body = ClipRSuperellipse(
      borderRadius: radius,
      child: BackdropFilter(enabled: _blurring && fake < 1, filter: GlassMath.backdropFilter(spec), child: body),
    );

    return RepaintBoundary(
      child: CustomPaint(
        painter: widget.shadow ? _ShadowPainter(spec: spec, radius: widget.radius, dark: tokens.isDark) : null,
        child: body,
      ),
    );
  }
}

Path _shapePath(Rect rect, double radius) =>
    RoundedSuperellipseBorder(borderRadius: BorderRadius.circular(radius)).getOuterPath(rect);

class _ShadowPainter extends CustomPainter {
  _ShadowPainter({required this.spec, required this.radius, required this.dark});

  final GlassSpec spec;
  final double radius;
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final path = _shapePath(rect, radius);
    canvas.save();
    // Shadow only outside the glass so it never muddies the refracted backdrop.
    canvas.clipPath(Path.combine(PathOperation.difference, Path()..addRect(rect.inflate(spec.shadowBlur * 3)), path));
    canvas.drawPath(
      path.shift(Offset(0, spec.shadowBlur * 0.35)),
      Paint()
        ..color = Colors.black.withValues(alpha: spec.shadowAlpha)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, spec.shadowBlur / 2),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_ShadowPainter old) => old.spec != spec || old.radius != radius || old.dark != dark;
}

class _GlassPainter extends CustomPainter {
  _GlassPainter({
    required this.tokens,
    required this.spec,
    required this.radius,
    required this.light,
    required this.blurring,
    required this.tint,
    this.fake = 0,
  }) : super(repaint: light);

  final GlassTokens tokens;
  final GlassSpec spec;
  final double radius;
  final ValueListenable<Offset> light;
  final bool blurring;
  final double fake;
  final Color? tint;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final path = _shapePath(rect, radius);
    final base = tint ?? tokens.tint;
    final alpha = blurring ? lerpDouble(spec.tintAlpha, spec.fallbackTintAlpha, fake)! : spec.fallbackTintAlpha;
    canvas.drawPath(path, Paint()..color = base.withValues(alpha: alpha));

    // Vertical sheen: the upper half is slightly brighter, like curved glass.
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            tokens.highlight.withValues(alpha: spec.glowAlpha * 0.55),
            tokens.highlight.withValues(alpha: 0),
            tokens.accent.withValues(alpha: tokens.isDark ? 0.05 : 0.03),
          ],
          stops: const [0, 0.55, 1],
        ).createShader(rect),
    );

    // Inner glow, centred towards the light.
    final l = light.value;
    canvas.drawPath(
      path,
      Paint()
        ..shader = RadialGradient(
          center: Alignment(l.dx * 0.9, l.dy * 0.9),
          radius: 1.0,
          colors: [
            tokens.highlight.withValues(alpha: spec.glowAlpha),
            tokens.highlight.withValues(alpha: 0),
          ],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_GlassPainter old) =>
      old.tokens != tokens ||
      old.spec != spec ||
      old.radius != radius ||
      old.blurring != blurring ||
      old.fake != fake ||
      old.tint != tint;
}

class _RimPainter extends CustomPainter {
  _RimPainter({required this.tokens, required this.spec, required this.radius, required this.light})
    : super(repaint: light);

  final GlassTokens tokens;
  final GlassSpec spec;
  final double radius;
  final ValueListenable<Offset> light;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final align = GlassMath.rimAlignment(light.value);
    final c = tokens.highlight;
    final path = _shapePath(rect.deflate(0.5), radius);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..shader = LinearGradient(
          begin: align.begin,
          end: align.end,
          colors: [
            c.withValues(alpha: spec.rimAlpha),
            c.withValues(alpha: spec.rimAlpha * 0.22),
            c.withValues(alpha: spec.rimAlpha * 0.06),
            c.withValues(alpha: spec.rimAlpha * GlassMath.farGlint),
          ],
          stops: const [0, 0.32, 0.68, 1],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_RimPainter old) => old.tokens != tokens || old.spec != spec || old.radius != radius;
}

/// Full-width glass strip for app bars and bottom bars. [condense] (0..1)
/// fades the material in as content scrolls under it: at 0 the bar is clear,
/// at 1 it is full glass with a rim line on the [edge] facing the content.
class GlassBar extends StatefulWidget {
  const GlassBar({
    super.key,
    this.condense = 1,
    this.edge = Alignment.bottomCenter,
    this.variant = GlassVariant.regular,
    this.budget,
    this.activity,
    this.child,
  });

  final double condense;

  /// Side that carries the hairline (bottom for top bars, top for bottom bars).
  final Alignment edge;
  final GlassVariant variant;
  final GlassLayerBudget? budget;

  /// Test hook for the scroll signal; defaults to [GlassScrollActivity.scrolling].
  final ValueListenable<bool>? activity;
  final Widget? child;

  @override
  State<GlassBar> createState() => _GlassBarState();
}

class _GlassBarState extends State<GlassBar> {
  bool _slot = false;
  GlassLayerBudget get _budget => widget.budget ?? GlassLayerBudget.shared;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _update();
  }

  @override
  void didUpdateWidget(GlassBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    _update();
  }

  void _update() {
    // A clear bar does not need a layer; only take a slot once it condenses.
    final want = widget.condense > 0.02 && TickerMode.valuesOf(context).enabled;
    _slot = want && _budget.tryAcquire(this);
    if (!_slot) {
      _budget.release(this);
    }
  }

  @override
  void dispose() {
    _budget.release(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Bars float over the scrolling content: they are static glass while it moves.
    return GlassScrollGate(activity: widget.activity, builder: _buildBar);
  }

  Widget _buildBar(BuildContext context, double fake) {
    final tokens = context.glass;
    final spec = GlassSpec.of(widget.variant, tokens.brightness);
    final t = widget.condense.clamp(0.0, 1.0);
    final alpha = (_slot ? lerpDouble(spec.tintAlpha, spec.fallbackTintAlpha, fake)! : spec.fallbackTintAlpha) * t;
    return RepaintBoundary(
      child: ClipRect(
        child: BackdropFilter(
          enabled: _slot && fake < 1,
          filter: GlassMath.backdropFilter(spec),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: tokens.tint.withValues(alpha: alpha),
              border: Border(
                bottom: widget.edge.y > 0
                    ? BorderSide(color: tokens.highlight.withValues(alpha: spec.rimAlpha * 0.35 * t), width: 0.7)
                    : BorderSide.none,
                top: widget.edge.y < 0
                    ? BorderSide(color: tokens.highlight.withValues(alpha: spec.rimAlpha * 0.5 * t), width: 0.7)
                    : BorderSide.none,
              ),
            ),
            child: widget.child ?? const SizedBox.expand(),
          ),
        ),
      ),
    );
  }
}
