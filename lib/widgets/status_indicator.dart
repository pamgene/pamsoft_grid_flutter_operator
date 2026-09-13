import 'package:flutter/material.dart';
import 'package:pamsoft_grid_flutter_operator/core/theme/app_colors.dart';
import 'package:pamsoft_grid_flutter_operator/core/theme/app_spacing.dart';
import 'package:pamsoft_grid_flutter_operator/models/enums.dart';

/// Status of the current grid: a square and the word for it.
///
/// - Not viewed: blue outline. Hollow and blue so it stands apart from the
///   grey images and the grey chrome; until 0.0.10 an unopened grid was
///   painted the same green as a checked one.
/// - Viewed: success green (#047857), filled.
/// - Modified: warning amber (#B45309), filled.
///
/// The word is there so the meaning does not ride on colour alone.
class StatusIndicator extends StatelessWidget {
  final GridStatus status;

  /// Show the word next to the square (the header does; tight spots may not).
  final bool withLabel;

  const StatusIndicator({
    super.key,
    required this.status,
    this.withLabel = true,
  });

  static String labelFor(GridStatus status) {
    switch (status) {
      case GridStatus.unviewed:
        return 'Not viewed';
      case GridStatus.processed:
        return 'Viewed';
      case GridStatus.modified:
        return 'Modified';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final todo = isDark ? AppColors.linkDark : AppColors.primaryLighter;

    final BoxDecoration decoration;
    switch (status) {
      case GridStatus.unviewed:
        decoration = BoxDecoration(
          border: Border.all(color: todo, width: 2),
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        );
      case GridStatus.processed:
        decoration = BoxDecoration(
          color: AppColors.success,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        );
      case GridStatus.modified:
        decoration = BoxDecoration(
          color: AppColors.warning,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        );
    }

    final square = Container(width: 14, height: 14, decoration: decoration);
    if (!withLabel) return square;

    return Tooltip(
      message: status == GridStatus.unviewed
          ? 'This grid image has not been opened in this session'
          : status == GridStatus.processed
          ? 'Opened in this session and left as the algorithm placed it'
          : 'Changed by you in this session',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          square,
          const SizedBox(width: 6),
          Text(
            labelFor(status),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
