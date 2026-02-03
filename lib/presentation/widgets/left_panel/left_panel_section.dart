import 'package:flutter/material.dart';
import 'package:pamsoft_grid_flutter_operator/core/theme/app_spacing.dart';

/// A section within the left panel.
///
/// Each section has:
/// - Icon (shown in collapsed state)
/// - UPPERCASE label
/// - Content
class LeftPanelSection extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget content;

  const LeftPanelSection({
    super.key,
    required this.icon,
    required this.label,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Section Header
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            border: Border(
              bottom: BorderSide(color: colorScheme.outlineVariant),
            ),
          ),
          clipBehavior: Clip.hardEdge,
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Hide content during collapse animation when width is too narrow
              if (constraints.maxWidth < 50) {
                return const SizedBox.shrink();
              }
              return Row(
                children: [
                  Icon(
                    icon,
                    size: 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      label.toUpperCase(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              );
            },
          ),
        ),

        // Section Content
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: content,
        ),
      ],
    );
  }
}
