import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:immich_mobile/domain/models/asset/base_asset.model.dart';
import 'package:immich_mobile/domain/models/timeline.model.dart';
import 'package:immich_mobile/extensions/build_context_extensions.dart';
import 'package:immich_mobile/extensions/datetime_extensions.dart';
import 'package:immich_mobile/extensions/theme_extensions.dart';
import 'package:immich_mobile/generated/translations.g.dart';
import 'package:immich_mobile/providers/haptic_feedback.provider.dart';
import 'package:immich_mobile/providers/infrastructure/readonly_mode.provider.dart';
import 'package:immich_mobile/providers/infrastructure/timeline.provider.dart';
import 'package:immich_mobile/providers/timeline/multiselect.provider.dart';
import 'package:immich_mobile/theme/glass/glass.dart';

class TimelineHeader extends HookWidget {
  final Bucket bucket;
  final HeaderType header;
  final double height;
  final int assetOffset;

  const TimelineHeader({
    super.key,
    required this.bucket,
    required this.header,
    required this.height,
    required this.assetOffset,
  });

  /// Month name without the year; the year is typeset separately as secondary text.
  String _monthName(DateTime date) => DateFormat.MMMM(resolvedDateTimeLocale()).format(date);

  String _formatDay(DateTime date) {
    final formatter = DateFormat.MMMEd(resolvedDateTimeLocale());
    return formatter.format(date);
  }

  @override
  Widget build(BuildContext context) {
    if (bucket is! TimeBucket || header == HeaderType.none) {
      return const SizedBox.shrink();
    }

    final tokens = context.glass;
    final date = (bucket as TimeBucket).date;
    final isMonthHeader = header == HeaderType.month || header == HeaderType.monthAndDay;
    final isDayHeader = header == HeaderType.day || header == HeaderType.monthAndDay;
    final textTheme = context.textTheme;

    return Padding(
      padding: EdgeInsets.only(top: isMonthHeader ? 8.0 : 0.0, left: 16.0, right: 8.0),
      child: SizedBox(
        height: height,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (isMonthHeader)
              Row(
                children: [
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Flexible(
                          child: Text(
                            toBeginningOfSentenceCase(_monthName(date)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.headlineMedium?.copyWith(color: tokens.ink, height: 1.1),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          date.year.toString(),
                          style: textTheme.titleMedium?.copyWith(
                            color: tokens.inkSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (header != HeaderType.monthAndDay) _BulkSelectIconButton(bucket: bucket, assetOffset: assetOffset),
                ],
              ),
            if (isMonthHeader && !isDayHeader)
              Padding(
                padding: const EdgeInsets.only(bottom: 10, top: 1),
                child: Text(
                  context.t.items_count(count: bucket.assetCount),
                  style: textTheme.labelMedium?.copyWith(color: tokens.inkSecondary),
                ),
              ),
            if (isDayHeader)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 16,
                      decoration: BoxDecoration(color: tokens.accent, borderRadius: BorderRadius.circular(2)),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      toBeginningOfSentenceCase(_formatDay(date)),
                      style: textTheme.titleSmall?.copyWith(color: tokens.ink, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      context.t.items_count(count: bucket.assetCount),
                      style: textTheme.labelMedium?.copyWith(color: tokens.inkSecondary),
                    ),
                    const Spacer(),
                    _BulkSelectIconButton(bucket: bucket, assetOffset: assetOffset),
                  ],
                ),
              ),
            if (isDayHeader) const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}

class _BulkSelectIconButton extends ConsumerWidget {
  final Bucket bucket;
  final int assetOffset;

  const _BulkSelectIconButton({required this.bucket, required this.assetOffset});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    List<BaseAsset> bucketAssets;
    try {
      bucketAssets = ref.watch(timelineServiceProvider).getAssets(assetOffset, bucket.assetCount);
    } catch (e) {
      bucketAssets = <BaseAsset>[];
    }

    final isReadonlyModeEnabled = ref.watch(readonlyModeProvider);
    final isAllSelected = ref.watch(
      multiSelectProvider.select(
        (state) => bucketAssets.isNotEmpty && bucketAssets.every(state.selectedAssets.contains),
      ),
    );

    return isReadonlyModeEnabled
        ? const SizedBox.shrink()
        : IconButton(
            onPressed: () {
              unawaited(ref.read(multiSelectProvider.notifier).toggleBucketSelection(assetOffset, bucket.assetCount));
              ref.read(hapticFeedbackProvider.notifier).heavyImpact();
            },
            icon: isAllSelected
                ? Icon(Icons.check_circle_rounded, size: 26, color: context.primaryColor)
                : Icon(Icons.check_circle_outline_rounded, size: 26, color: context.colorScheme.onSurfaceSecondary),
          );
  }
}
