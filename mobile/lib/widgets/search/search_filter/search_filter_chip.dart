import 'package:flutter/material.dart';
import 'package:immich_mobile/extensions/build_context_extensions.dart';
import 'package:immich_mobile/presentation/widgets/common/press_scale.dart';
import 'package:immich_mobile/theme/solid/solid.dart';

class SearchFilterChip extends StatelessWidget {
  final String label;
  final Function() onTap;
  final Widget? currentFilter;
  final IconData icon;

  const SearchFilterChip({super.key, required this.label, required this.onTap, required this.icon, this.currentFilter});

  @override
  Widget build(BuildContext context) {
    final tokens = context.solid;
    final active = currentFilter != null;
    final fg = active ? (tokens.isDark ? Colors.black : Colors.white) : tokens.ink;
    return Padding(
      padding: const EdgeInsets.only(right: 8, top: 4, bottom: 4),
      child: PressScale(
        child: GestureDetector(
          onTap: onTap,
          child: SolidSurface(
            floating: false,
            radius: 999,
            color: active ? tokens.accent : null,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
            child: Row(
              children: [
                Icon(icon, size: 18, color: fg),
                const SizedBox(width: 6.0),
                if (active)
                  DefaultTextStyle.merge(
                    style: TextStyle(color: fg, fontWeight: FontWeight.w600),
                    child: currentFilter!,
                  )
                else
                  Text(
                    label,
                    style: context.textTheme.labelLarge?.copyWith(color: fg, fontWeight: FontWeight.w500),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
