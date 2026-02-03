import 'package:flutter/material.dart';
import 'package:pamsoft_grid_flutter_operator/core/theme/app_colors.dart';
import 'package:pamsoft_grid_flutter_operator/core/theme/app_spacing.dart';
import 'package:pamsoft_grid_flutter_operator/models/enums.dart';

/// Status indicator widget showing green (processed) or amber (modified).
///
/// Uses Tercen semantic colours:
/// - Processed: success green (#047857)
/// - Modified: warning amber (#B45309)
class StatusIndicator extends StatelessWidget {
  final GridStatus status;

  const StatusIndicator({
    super.key,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: status == GridStatus.processed
            ? AppColors.success
            : AppColors.warning,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
    );
  }
}
