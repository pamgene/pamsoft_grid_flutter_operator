import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;
import 'package:pamsoft_grid_flutter_operator/core/theme/app_spacing.dart';

/// Top bar shown when app is NOT embedded in a Data Step.
///
/// Contains:
/// - Context badge (left)
/// - Close button (right)
class TopBar extends StatelessWidget {
  final VoidCallback? onClose;

  const TopBar({
    super.key,
    this.onClose,
  });

  void _handleClose() {
    if (onClose != null) {
      onClose!();
    } else {
      // Default: close the browser window/tab
      web.window.close();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      height: AppSpacing.topBarHeight,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(
        children: [
          // Context badge
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Text(
              'FULL SCREEN MODE',
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          const Spacer(),

          // Close button (always visible)
          IconButton(
            icon: Icon(
              Icons.close,
              color: colorScheme.onSurfaceVariant,
            ),
            onPressed: _handleClose,
            tooltip: 'Close',
            iconSize: 20,
          ),
        ],
      ),
    );
  }
}
