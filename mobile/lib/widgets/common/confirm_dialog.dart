import 'package:flutter/material.dart';
import 'package:immich_mobile/extensions/build_context_extensions.dart';
import 'package:immich_mobile/generated/translations.g.dart';
import 'package:immich_mobile/theme/solid/solid.dart';

class ConfirmDialog extends StatelessWidget {
  final Function? onOk;
  final String title;
  final String content;
  final String? cancel;
  final String? ok;

  const ConfirmDialog({super.key, this.onOk, required this.title, required this.content, this.cancel, this.ok});

  @override
  Widget build(BuildContext context) {
    void onOkPressed() {
      onOk?.call();
      context.pop(true);
    }

    final tokens = context.solid;
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      child: SolidSurface(
        radius: 32,
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: context.textTheme.titleMedium?.copyWith(color: tokens.ink, fontSize: 20)),
            const SizedBox(height: 10),
            Text(content, style: context.textTheme.bodyMedium?.copyWith(color: tokens.mutedStrong)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => context.pop(false),
                  child: Text(
                    cancel ?? context.t.cancel,
                    style: TextStyle(color: context.primaryColor, fontWeight: FontWeight.bold),
                  ),
                ),
                TextButton(
                  onPressed: onOkPressed,
                  child: Text(
                    ok ?? context.t.backup_controller_page_background_battery_info_ok,
                    style: TextStyle(color: context.colorScheme.error, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
