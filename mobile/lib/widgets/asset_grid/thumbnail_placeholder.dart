import 'package:flutter/material.dart';
import 'package:immich_mobile/theme/premium_tokens.dart';

class ThumbnailPlaceholder extends StatelessWidget {
  final EdgeInsets margin;
  final double width;
  final double height;

  const ThumbnailPlaceholder({super.key, this.margin = EdgeInsets.zero, this.width = 250, this.height = 250});

  @override
  Widget build(BuildContext context) {
    final tokens = context.premium;
    final gradientColors = [tokens.skeletonHighlight, tokens.skeletonBase];

    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradientColors, begin: Alignment.topCenter, end: Alignment.bottomCenter),
      ),
    );
  }
}
