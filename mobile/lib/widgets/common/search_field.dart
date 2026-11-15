import 'package:flutter/material.dart';
import 'package:immich_mobile/extensions/build_context_extensions.dart';
import 'package:immich_mobile/extensions/theme_extensions.dart';
import 'package:immich_mobile/theme/glass/glass.dart';

class SearchField extends StatelessWidget {
  const SearchField({
    super.key,
    required this.hintText,
    this.autofocus = false,
    this.controller,
    this.focusNode,
    this.onChanged,
    this.onSubmitted,
    this.onTapOutside,
    this.contentPadding = const EdgeInsets.only(left: 24),
    this.prefixIcon,
    this.suffixIcon,
    this.filled = false,
    this.blur = false,
  });

  final FocusNode? focusNode;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final void Function(PointerDownEvent)? onTapOutside;
  final TextEditingController? controller;
  final String hintText;
  final EdgeInsetsGeometry contentPadding;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool autofocus;
  final bool filled;

  /// Whether the glass behind the field blurs its backdrop (uses a layer from the glass budget).
  final bool blur;

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      blur: blur,
      shadow: blur,
      radius: 24,
      child: TextField(
        controller: controller,
        autofocus: autofocus,
        focusNode: focusNode,
        onChanged: onChanged,
        onTapOutside: onTapOutside ?? (_) => focusNode?.unfocus(),
        onSubmitted: onSubmitted,
        decoration: InputDecoration(
          contentPadding: contentPadding,
          filled: filled,
          fillColor: context.primaryColor.withValues(alpha: 0.1),
          hintStyle: context.textTheme.bodyLarge?.copyWith(color: context.themeData.colorScheme.onSurfaceSecondary),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          prefixIcon: prefixIcon,
          suffixIcon: suffixIcon,
          hintText: hintText,
        ),
      ),
    );
  }
}
