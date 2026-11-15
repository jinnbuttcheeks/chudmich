import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:immich_mobile/theme/glass/glass_tokens.dart';

/// Slowly drifting gradient field that glass has something to refract.
///
/// Three large radial blobs derived from the primary colour move on
/// incommensurate sine paths over a deep canvas gradient. The field repaints at
/// about 20 fps (it moves a few pixels per second, so more frames are invisible
/// cost), stops while its route is hidden ([TickerMode]) and is static when the
/// user disabled animations.
class AmbientBackground extends StatefulWidget {
  const AmbientBackground({super.key, this.child, this.intensity = 1.0});

  final Widget? child;

  /// Global switch for the drift animation. Tests turn it off so that
  /// `pumpAndSettle` can settle; the field is then painted once, static.
  static bool animationsEnabled = true;

  /// Scales blob opacity; 0 hides the blobs.
  final double intensity;

  /// Phase of the field at [seconds] of animation. Pure so it can be tested.
  static ({Offset a, Offset b, Offset c}) blobCentres(double seconds) {
    double wave(double speed, double phase) => math.sin(seconds * speed + phase);
    return (
      a: Offset(0.15 + 0.12 * wave(0.11, 0), 0.10 + 0.08 * wave(0.09, 1.3)),
      b: Offset(0.88 + 0.08 * wave(0.07, 2.1), 0.42 + 0.14 * wave(0.10, 0.4)),
      c: Offset(0.30 + 0.14 * wave(0.08, 4.2), 0.92 + 0.06 * wave(0.12, 2.8)),
    );
  }

  @override
  State<AmbientBackground> createState() => _AmbientBackgroundState();
}

class _AmbientBackgroundState extends State<AmbientBackground> with SingleTickerProviderStateMixin {
  static const _frame = Duration(milliseconds: 48);

  final ValueNotifier<double> _seconds = ValueNotifier<double>(8);
  late final Ticker _ticker = createTicker(_onTick);
  Duration _last = Duration.zero;
  bool _animate = true;

  void _onTick(Duration elapsed) {
    if (elapsed - _last < _frame) {
      return;
    }
    _last = elapsed;
    _seconds.value = 8 + elapsed.inMilliseconds / 1000;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _animate = AmbientBackground.animationsEnabled && !(MediaQuery.maybeDisableAnimationsOf(context) ?? false);
    if (_animate && !_ticker.isActive) {
      _ticker.start();
    } else if (!_animate && _ticker.isActive) {
      _ticker.stop();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _seconds.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.glass;
    return Stack(
      fit: StackFit.expand,
      children: [
        RepaintBoundary(
          child: CustomPaint(
            painter: _AmbientPainter(tokens: tokens, seconds: _seconds, intensity: widget.intensity),
            size: Size.infinite,
          ),
        ),
        if (widget.child != null) widget.child!,
      ],
    );
  }
}

class _AmbientPainter extends CustomPainter {
  _AmbientPainter({required this.tokens, required this.seconds, required this.intensity}) : super(repaint: seconds);

  final GlassTokens tokens;
  final ValueListenable<double> seconds;
  final double intensity;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [tokens.canvas, tokens.canvasDeep],
        ).createShader(rect),
    );
    if (intensity <= 0) {
      return;
    }
    final centres = AmbientBackground.blobCentres(seconds.value);
    final longest = size.longestSide;
    void blob(Offset unit, Color color, double radiusFactor) {
      final centre = Offset(unit.dx * size.width, unit.dy * size.height);
      final radius = longest * radiusFactor;
      canvas.drawCircle(
        centre,
        radius,
        Paint()
          ..shader = RadialGradient(
            colors: [
              color.withValues(alpha: color.a * intensity),
              color.withValues(alpha: 0),
            ],
          ).createShader(Rect.fromCircle(center: centre, radius: radius)),
      );
    }

    blob(centres.a, tokens.blobA, 0.62);
    blob(centres.b, tokens.blobB, 0.55);
    blob(centres.c, tokens.blobC, 0.60);
  }

  @override
  bool shouldRepaint(_AmbientPainter old) => old.tokens != tokens || old.intensity != intensity;
}
