import 'package:flutter/widgets.dart';
import 'package:immich_mobile/theme/glass/glass_math.dart';

/// Direction of the virtual light that the specular rim of every glass surface
/// reacts to. Updating [light] only repaints the thin rim of glass surfaces.
class GlassLightScope extends InheritedNotifier<ValueNotifier<Offset>> {
  const GlassLightScope({super.key, required ValueNotifier<Offset> light, required super.child})
    : super(notifier: light);

  static final ValueNotifier<Offset> _resting = ValueNotifier<Offset>(GlassMath.restingLight);

  /// The light of the nearest scope, or a resting light when there is none.
  static ValueNotifier<Offset> of(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<GlassLightScope>();
    return scope?.notifier ?? _resting;
  }
}

/// Feeds a [GlassLightScope] with scroll movement: the highlight slides slowly
/// along the rim while the user scrolls, so glass reads as a lit, curved object.
class GlassLightScrollDriver extends StatefulWidget {
  const GlassLightScrollDriver({super.key, required this.child, this.axisDepth = 0});

  final Widget child;

  /// Notification depth to listen to (0 = the nearest scrollable).
  final int axisDepth;

  @override
  State<GlassLightScrollDriver> createState() => _GlassLightScrollDriverState();
}

class _GlassLightScrollDriverState extends State<GlassLightScrollDriver> {
  final ValueNotifier<Offset> _light = ValueNotifier<Offset>(GlassMath.restingLight);

  bool _onScroll(ScrollNotification notification) {
    if (notification.depth != widget.axisDepth || notification is! ScrollUpdateNotification) {
      return false;
    }
    final target = GlassMath.lightFromScroll(notification.metrics.pixels);
    // Ignore sub-pixel changes: nothing visible would move.
    if ((target - _light.value).distance > 0.004) {
      _light.value = target;
    }
    return false;
  }

  @override
  void dispose() {
    _light.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GlassLightScope(
      light: _light,
      child: NotificationListener<ScrollNotification>(onNotification: _onScroll, child: widget.child),
    );
  }
}
