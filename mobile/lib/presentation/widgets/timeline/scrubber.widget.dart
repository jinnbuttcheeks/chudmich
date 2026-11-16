import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:immich_mobile/constants/constants.dart';
import 'package:immich_mobile/domain/models/timeline.model.dart';
import 'package:immich_mobile/extensions/build_context_extensions.dart';
import 'package:immich_mobile/extensions/datetime_extensions.dart';
import 'package:immich_mobile/presentation/widgets/timeline/constants.dart';
import 'package:immich_mobile/presentation/widgets/timeline/segment.model.dart';
import 'package:immich_mobile/presentation/widgets/timeline/timeline.state.dart';
import 'package:immich_mobile/providers/haptic_feedback.provider.dart';
import 'package:immich_mobile/theme/glass/glass.dart';
import 'package:intl/intl.dart' hide TextDirection;

part 'scrubber.widget.freezed.dart';

/// A widget that will display a BoxScrollView with a ScrollThumb that can be dragged
/// for quick navigation of the BoxScrollView.
class Scrubber extends ConsumerStatefulWidget {
  /// The view that will be scrolled with the scroll thumb
  final CustomScrollView child;

  /// The segments of the timeline
  final List<Segment> layoutSegments;

  final double timelineHeight;

  final double topPadding;

  final double bottomPadding;

  final double? monthSegmentSnappingOffset;

  final bool snapToMonth;

  /// Whether an app bar is present, affects coordinate calculations
  final bool hasAppBar;

  Scrubber({
    super.key,
    required this.layoutSegments,
    required this.timelineHeight,
    this.topPadding = 0,
    this.bottomPadding = 0,
    this.monthSegmentSnappingOffset,
    this.snapToMonth = true,
    this.hasAppBar = true,
    required this.child,
  }) : assert(child.scrollDirection == Axis.vertical);

  @override
  ConsumerState createState() => ScrubberState();
}

List<_Segment> _buildSegments({required List<Segment> layoutSegments, required double timelineHeight}) {
  const double offsetThreshold = 40.0;

  final segments = <_Segment>[];
  if (layoutSegments.isEmpty || layoutSegments.first.bucket is! TimeBucket) {
    return [];
  }

  final formatter = DateFormat.yMMM(resolvedDateTimeLocale());
  DateTime? lastDate;
  double lastOffset = -offsetThreshold;
  for (final layoutSegment in layoutSegments) {
    final scrollPercentage = layoutSegment.startOffset / layoutSegments.last.endOffset;
    final startOffset = scrollPercentage * timelineHeight;

    final date = (layoutSegment.bucket as TimeBucket).date;
    final label = formatter.format(date);

    final showSegment = lastOffset + offsetThreshold <= startOffset && (lastDate == null || date.year != lastDate.year);

    segments.add(_Segment(date: date, startOffset: startOffset, scrollLabel: label, showSegment: showSegment));
    lastDate = date;
    if (showSegment) {
      lastOffset = startOffset;
    }
  }

  return segments;
}

class ScrubberState extends ConsumerState<Scrubber> with TickerProviderStateMixin {
  String? _lastLabel;
  double _thumbTopOffset = 0.0;
  bool _isDragging = false;
  List<_Segment> _segments = [];
  int _monthCount = 0;

  late AnimationController _thumbAnimationController;
  Timer? _fadeOutTimer;
  late Animation<double> _thumbAnimation;

  late AnimationController _labelAnimationController;
  late Animation<double> _labelAnimation;

  double get _scrubberHeight => widget.timelineHeight - widget.topPadding - widget.bottomPadding;

  late ScrollController _scrollController;

  double get _currentOffset {
    if (_scrollController.hasClients != true) {
      return 0.0;
    }

    return _scrollController.offset * _scrubberHeight / _scrollController.position.maxScrollExtent;
  }

  @override
  void initState() {
    super.initState();
    _isDragging = false;
    _segments = _buildSegments(layoutSegments: widget.layoutSegments, timelineHeight: _scrubberHeight);
    _thumbAnimationController = AnimationController(vsync: this, duration: kTimelineScrubberFadeInDuration);
    _thumbAnimation = CurvedAnimation(parent: _thumbAnimationController, curve: Curves.fastEaseInToSlowEaseOut);
    _labelAnimationController = AnimationController(vsync: this, duration: kTimelineScrubberFadeInDuration);
    _monthCount = getMonthCount();

    _labelAnimation = CurvedAnimation(parent: _labelAnimationController, curve: Curves.fastOutSlowIn);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scrollController = PrimaryScrollController.of(context);
  }

  @override
  void didUpdateWidget(covariant Scrubber oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.layoutSegments.lastOrNull?.endOffset != widget.layoutSegments.lastOrNull?.endOffset) {
      _segments = _buildSegments(layoutSegments: widget.layoutSegments, timelineHeight: _scrubberHeight);
      _monthCount = getMonthCount();
    }
  }

  @override
  void dispose() {
    _thumbAnimationController.dispose();
    _labelAnimationController.dispose();
    _fadeOutTimer?.cancel();
    super.dispose();
  }

  void _resetThumbTimer() {
    _fadeOutTimer?.cancel();
    _fadeOutTimer = Timer(kTimelineScrubberFadeOutDuration, () {
      unawaited(_thumbAnimationController.reverse());
      _fadeOutTimer = null;
    });
  }

  int getMonthCount() {
    return _segments.map((e) => "${e.date.month}_${e.date.year}").toSet().length;
  }

  bool _onScrollNotification(ScrollNotification notification) {
    if (_isDragging) {
      // If the user is dragging the thumb, we don't want to update the position
      return false;
    }

    if (notification is ScrollStartNotification || notification is ScrollUpdateNotification) {
      ref.read(timelineStateProvider.notifier).setScrolling(true);
    } else if (notification is ScrollEndNotification) {
      ref.read(timelineStateProvider.notifier).setScrolling(false);
    }

    setState(() {
      if (notification is ScrollUpdateNotification) {
        _thumbTopOffset = _currentOffset;
        if (_labelAnimation.status != AnimationStatus.reverse) {
          unawaited(_labelAnimationController.reverse());
        }
        if (_thumbAnimationController.status != AnimationStatus.forward) {
          unawaited(_thumbAnimationController.forward());
        }
      }
      _resetThumbTimer();
    });

    return false;
  }

  void _onDragStart(DragStartDetails _) {
    setState(() {
      _isDragging = true;
      unawaited(_labelAnimationController.forward());
      _fadeOutTimer?.cancel();
      _lastLabel = null;
    });
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (!_isDragging) {
      return;
    }

    if (_scrubberHeight <= 0) {
      return;
    }

    if (_thumbAnimationController.status != AnimationStatus.forward) {
      unawaited(_thumbAnimationController.forward());
    }

    final dragPosition = _calculateDragPosition(details);
    final nearestMonthSegment = _findNearestMonthSegment(dragPosition);

    if (nearestMonthSegment != null) {
      final label = nearestMonthSegment.scrollLabel;
      if (_lastLabel != label) {
        ref.read(hapticFeedbackProvider.notifier).selectionClick();
        _lastLabel = label;
      }
    }

    if (_monthCount < kMinMonthsToEnableScrubberSnap || !widget.snapToMonth) {
      // If there are less than kMinMonthsToEnableScrubberSnap months, we don't need to snap to segments
      setState(() {
        _thumbTopOffset = dragPosition;
        _scrollController.jumpTo((dragPosition / _scrubberHeight) * _scrollController.position.maxScrollExtent);
      });
    } else if (nearestMonthSegment != null) {
      _snapToSegment(nearestMonthSegment);
    }
  }

  /// Calculate the drag position relative to the scrubber area
  ///
  /// This method converts the global drag coordinates from the gesture detector
  /// into a position relative to the scrubber's active area (excluding padding).
  ///
  /// The scrubber has padding at the top and bottom, so we need to:
  /// 1. Calculate the actual draggable area (timelineHeight - topPadding - bottomPadding)
  /// 2. Convert the global Y position to a position within this draggable area
  /// 3. Clamp the result to ensure it stays within bounds (0 to dragAreaHeight)
  ///
  /// Example:
  /// - If timelineHeight = 800, topPadding = 50, bottomPadding = 50
  /// - Then dragAreaHeight = 700 (the actual scrubber area)
  /// - If user drags to global Y position that's 100 pixels from the top
  /// - The relative position would be 100 - 50 = 50 (50 pixels into the scrubber area)
  double _calculateDragPosition(DragUpdateDetails details) {
    if (widget.hasAppBar) {
      final dragAreaTop = widget.topPadding;
      final dragAreaBottom = widget.timelineHeight - widget.bottomPadding;
      final dragAreaHeight = dragAreaBottom - dragAreaTop;

      final relativePosition = details.globalPosition.dy - dragAreaTop;

      // Make sure the position stays within the scrubber's bounds
      return relativePosition.clamp(0.0, dragAreaHeight);
    }

    // Get the local position relative to the gesture detector
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      final localPosition = renderBox.globalToLocal(details.globalPosition);
      return localPosition.dy.clamp(0.0, _scrubberHeight);
    }

    // Fallback to current logic if render box is not available
    final dragAreaTop = widget.topPadding;
    final relativePosition = details.globalPosition.dy - dragAreaTop;
    return relativePosition.clamp(0.0, _scrubberHeight);
  }

  /// Find the segment closest to the given position
  _Segment? _findNearestMonthSegment(double position) {
    _Segment? nearestSegment;
    double minDistance = double.infinity;

    for (final segment in _segments) {
      final distance = (segment.startOffset - position).abs();
      if (distance < minDistance) {
        minDistance = distance;
        nearestSegment = segment;
      }
    }

    return nearestSegment;
  }

  /// Snap the scrubber thumb and scroll view to the given segment
  void _snapToSegment(_Segment segment) {
    setState(() {
      _thumbTopOffset = segment.startOffset;

      final layoutSegmentIndex = _findLayoutSegmentIndex(segment);

      if (layoutSegmentIndex >= 0) {
        _scrollToLayoutSegment(layoutSegmentIndex);
      }
    });
  }

  int _findLayoutSegmentIndex(_Segment segment) {
    return widget.layoutSegments.indexWhere((layoutSegment) {
      final bucket = layoutSegment.bucket as TimeBucket;
      return bucket.date.year == segment.date.year && bucket.date.month == segment.date.month;
    });
  }

  void _scrollToLayoutSegment(int layoutSegmentIndex) {
    final layoutSegment = widget.layoutSegments[layoutSegmentIndex];
    final maxScrollExtent = _scrollController.position.maxScrollExtent;
    final viewportHeight = _scrollController.position.viewportDimension;

    final targetScrollOffset = layoutSegment.startOffset;
    final centeredOffset = targetScrollOffset - (viewportHeight / 4) + 100 + (widget.monthSegmentSnappingOffset ?? 0.0);

    _scrollController.jumpTo(centeredOffset.clamp(0.0, maxScrollExtent));
  }

  void _onDragEnd(DragEndDetails _) {
    unawaited(_labelAnimationController.reverse());
    setState(() {
      _isDragging = false;
    });

    _resetThumbTimer();
  }

  @override
  Widget build(BuildContext ctx) {
    Text? label;
    if (_scrollController.hasClients == true) {
      // Cache to avoid multiple calls to [_currentOffset]
      final scrollOffset = _currentOffset;
      final labelText =
          _segments.lastWhereOrNull((segment) => segment.startOffset <= scrollOffset)?.scrollLabel ??
          _segments.firstOrNull?.scrollLabel;
      label = labelText != null
          ? Text(
              labelText,
              style: ctx.textTheme.titleMedium?.copyWith(color: ctx.glass.ink, fontWeight: FontWeight.w700),
            )
          : null;
    }

    return NotificationListener<ScrollNotification>(
      onNotification: _onScrollNotification,
      child: Stack(
        children: [
          RepaintBoundary(child: widget.child),
          // Scroll Segments - wrapped in RepaintBoundary for better performance
          RepaintBoundary(
            child: _SegmentsLayer(
              key: ValueKey('segments_${_isDragging}_${_segments.length}'),
              segments: _segments,
              topPadding: widget.topPadding,
              isDragging: _isDragging,
            ),
          ),
          if (_scrollController.hasClients && _scrollController.position.maxScrollExtent > 0)
            PositionedDirectional(
              top: _thumbTopOffset + widget.topPadding,
              end: 0,
              child: RepaintBoundary(
                child: GestureDetector(
                  onVerticalDragStart: _onDragStart,
                  onVerticalDragUpdate: _onDragUpdate,
                  onVerticalDragEnd: _onDragEnd,
                  child: _Scrubber(thumbAnimation: _thumbAnimation, labelAnimation: _labelAnimation, label: label),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SegmentsLayer extends StatelessWidget {
  final List<_Segment> segments;
  final double topPadding;
  final bool isDragging;

  const _SegmentsLayer({super.key, required this.segments, required this.topPadding, required this.isDragging});

  @override
  Widget build(BuildContext context) {
    return Visibility(
      visible: isDragging,
      child: Stack(
        children: segments
            .where((segment) => segment.showSegment)
            .map(
              (segment) => PositionedDirectional(
                key: ValueKey('segment_${segment.date.millisecondsSinceEpoch}'),
                top: topPadding + segment.startOffset,
                end: 100,
                child: RepaintBoundary(child: _SegmentWidget(segment)),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _SegmentWidget extends StatelessWidget {
  final _Segment _segment;

  const _SegmentWidget(this._segment);

  @override
  Widget build(BuildContext context) {
    final tokens = context.glass;
    return IgnorePointer(
      child: Padding(
        padding: const EdgeInsets.only(right: 40.0),
        child: GlassSurface(
          variant: GlassVariant.thin,
          blur: false,
          shadow: false,
          radius: 14,
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4),
          child: Text(
            _segment.date.year.toString(),
            style: context.textTheme.labelMedium?.copyWith(
              fontFamily: "GoogleSansCode",
              fontWeight: FontWeight.w600,
              color: tokens.ink,
            ),
          ),
        ),
      ),
    );
  }
}

class _ScrollLabel extends StatelessWidget {
  final Text label;
  final Animation<double> animation;

  const _ScrollLabel({required this.label, required this.animation});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.92, end: 1).animate(animation),
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: GlassSurface(
              variant: GlassVariant.thick,
              // Moves with the grid under the finger: dense static glass, never a live blur.
              blur: false,
              radius: 22,
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
              child: label,
            ),
          ),
        ),
      ),
    );
  }
}

class _Scrubber extends StatelessWidget {
  final Text? label;
  final Animation<double> thumbAnimation;
  final Animation<double> labelAnimation;

  const _Scrubber({this.label, required this.thumbAnimation, required this.labelAnimation});

  @override
  Widget build(BuildContext context) {
    return _SlideFadeTransition(
      animation: thumbAnimation,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (label != null) _ScrollLabel(label: label!, animation: labelAnimation),
          const ScrubberHandle(),
        ],
      ),
    );
  }
}

/// The round glass thumb with its arrows.
@visibleForTesting
class ScrubberHandle extends StatelessWidget {
  const ScrubberHandle({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.glass;
    return Padding(
      padding: const EdgeInsets.only(right: 4.0),
      child: CustomPaint(
        key: ScrubberArrowPainter.paintKey,
        foregroundPainter: ScrubberArrowPainter(tokens.ink),
        child: const GlassSurface(
          key: ScrubberArrowPainter.handleKey,
          variant: GlassVariant.regular,
          blur: false,
          radius: 16,
          child: SizedBox(width: 32, height: kScrubberThumbHeight),
        ),
      ),
    );
  }
}

/// Draws the up/down arrows of the scrubber handle. Pure geometry in [glyphs]
/// so the centring can be tested; no text or font is involved, so text scale
/// cannot move the arrows.
class ScrubberArrowPainter extends CustomPainter {
  final Color color;

  const ScrubberArrowPainter(this.color);

  @visibleForTesting
  static const paintKey = ValueKey<String>('scrubber_arrows');

  @visibleForTesting
  static const handleKey = ValueKey<String>('scrubber_handle');

  static const double glyphWidth = 12.0;
  static const double glyphHeight = 8.0;

  /// Gap between the two triangle bases is twice this value.
  static const double glyphGap = 2.0;

  /// Outlines of the up and down arrows for a handle of [size].
  static List<Path> glyphs(Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    return [
      _trianglePath(Offset(cx, cy - glyphGap), isUp: true),
      _trianglePath(Offset(cx, cy + glyphGap), isUp: false),
    ];
  }

  @override
  bool shouldRepaint(covariant ScrubberArrowPainter oldDelegate) => oldDelegate.color != color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    for (final glyph in glyphs(size)) {
      canvas.drawPath(glyph, paint);
    }
  }

  /// Triangle with its base centred on [baseCentre], pointing up or down.
  static Path _trianglePath(Offset baseCentre, {required bool isUp}) {
    final left = baseCentre.dx - glyphWidth / 2;
    return Path()
      ..moveTo(left, baseCentre.dy)
      ..lineTo(left + glyphWidth, baseCentre.dy)
      ..lineTo(baseCentre.dx, isUp ? baseCentre.dy - glyphHeight : baseCentre.dy + glyphHeight)
      ..close();
  }
}

class _SlideFadeTransition extends StatelessWidget {
  final Animation<double> _animation;
  final Widget _child;

  const _SlideFadeTransition({required this._animation, required this._child});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) => _animation.value == 0.0 ? const SizedBox() : child!,
      child: SlideTransition(
        position: Tween(begin: const Offset(0.3, 0.0), end: Offset.zero).animate(_animation),
        child: FadeTransition(opacity: _animation, child: _child),
      ),
    );
  }
}

@freezed
abstract class _Segment with _$Segment {
  const factory _Segment({
    required DateTime date,
    required double startOffset,
    required String scrollLabel,
    @Default(false) bool showSegment,
  }) = __Segment;
}
