import 'package:flutter/material.dart';
import 'package:pamsoft_grid_flutter_operator/models/enums.dart';
import 'package:pamsoft_grid_flutter_operator/utils/constants.dart';

/// Status indicator widget showing green (processed) or yellow (modified).
class StatusIndicator extends StatelessWidget {
  final GridStatus status;

  const StatusIndicator({
    super.key,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppConstants.statusIndicatorSize,
      height: AppConstants.statusIndicatorSize,
      decoration: BoxDecoration(
        color: status == GridStatus.processed
            ? AppConstants.statusProcessedColor
            : AppConstants.statusModifiedColor,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
