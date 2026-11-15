import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:immich_mobile/extensions/build_context_extensions.dart';
import 'package:immich_mobile/theme/glass/glass.dart';

enum ToastType { info, success, error }

class ImmichToast {
  static void show({
    required BuildContext context,
    required String msg,
    ToastType toastType = ToastType.info,
    ToastGravity gravity = ToastGravity.BOTTOM,
    int durationInSecond = 3,
  }) {
    final fToast = FToast();
    fToast.init(context);

    Color getColor(ToastType type, BuildContext context) => switch (type) {
      ToastType.info => context.primaryColor,
      ToastType.success => const Color.fromARGB(255, 78, 140, 124),
      ToastType.error => const Color.fromARGB(255, 220, 48, 85),
    };

    Icon getIcon(ToastType type) => switch (type) {
      ToastType.info => Icon(Icons.info_outline_rounded, color: context.primaryColor),
      ToastType.success => const Icon(Icons.check_circle_rounded, color: Color.fromARGB(255, 78, 140, 124)),
      ToastType.error => const Icon(Icons.error_outline_rounded, color: Color.fromARGB(255, 240, 162, 156)),
    };

    fToast.showToast(
      child: GlassSurface(
        essential: true,
        radius: 24,
        padding: const EdgeInsets.symmetric(horizontal: 22.0, vertical: 13.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            getIcon(toastType),
            const SizedBox(width: 12.0),
            Flexible(
              child: Text(
                msg,
                style: TextStyle(color: getColor(toastType, context), fontWeight: FontWeight.w600, fontSize: 14),
              ),
            ),
          ],
        ),
      ),
      positionedToastBuilder: (context, child, gravity) {
        final isTop = gravity == ToastGravity.TOP;
        return Positioned(
          top: isTop ? 150 : null,
          bottom: isTop ? null : 150 + MediaQuery.of(context).viewInsets.bottom,
          left: MediaQuery.of(context).size.width / 2 - 150,
          right: MediaQuery.of(context).size.width / 2 - 150,
          child: IgnorePointer(child: child),
        );
      },
      gravity: gravity,
      toastDuration: Duration(seconds: durationInSecond),
    );
  }
}
