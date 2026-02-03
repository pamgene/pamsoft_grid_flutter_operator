import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pamsoft_grid_flutter_operator/core/theme/app_spacing.dart';
import 'package:pamsoft_grid_flutter_operator/providers/theme_provider.dart';

/// Left panel header with accent background.
///
/// Contains:
/// - App icon (click to expand when collapsed)
/// - App title (hidden when collapsed)
/// - Theme toggle (hidden when collapsed)
/// - Collapse chevron (always visible when expanded)
class LeftPanelHeader extends StatelessWidget {
  final String appTitle;
  final IconData appIcon;
  final bool isCollapsed;
  final VoidCallback onToggleCollapse;
  final VoidCallback? onIconTap;

  const LeftPanelHeader({
    super.key,
    required this.appTitle,
    required this.appIcon,
    required this.isCollapsed,
    required this.onToggleCollapse,
    this.onIconTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final themeProvider = context.watch<ThemeProvider>();
    final isDarkMode = themeProvider.isDarkMode;

    return Container(
      height: AppSpacing.headerHeight,
      color: colorScheme.primary,
      padding: EdgeInsets.symmetric(
        horizontal: isCollapsed ? 0 : AppSpacing.sm,
      ),
      child: isCollapsed
          ? _buildCollapsedHeader(colorScheme)
          : _buildExpandedHeader(colorScheme, isDarkMode, themeProvider),
    );
  }

  Widget _buildCollapsedHeader(ColorScheme colorScheme) {
    return Center(
      child: GestureDetector(
        onTap: onIconTap,
        child: Icon(
          appIcon,
          color: colorScheme.onPrimary,
          size: 22,
        ),
      ),
    );
  }

  Widget _buildExpandedHeader(ColorScheme colorScheme, bool isDarkMode, ThemeProvider themeProvider) {
    return Row(
      children: [
        // App Icon
        GestureDetector(
          onTap: onIconTap,
          child: Icon(
            appIcon,
            color: colorScheme.onPrimary,
            size: 22,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),

        // App Title
        Expanded(
          child: Text(
            appTitle,
            style: TextStyle(
              color: colorScheme.onPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),

        // Theme Toggle
        IconButton(
          icon: Icon(
            isDarkMode ? Icons.wb_sunny : Icons.nightlight_round,
            color: colorScheme.onPrimary,
            size: 20,
          ),
          onPressed: () => themeProvider.toggleTheme(),
          tooltip: isDarkMode ? 'Switch to light mode' : 'Switch to dark mode',
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(
            minWidth: 36,
            minHeight: 36,
          ),
        ),

        // Collapse Chevron
        IconButton(
          icon: Icon(
            Icons.chevron_left,
            color: colorScheme.onPrimary,
            size: 20,
          ),
          onPressed: onToggleCollapse,
          tooltip: 'Collapse panel',
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(
            minWidth: 36,
            minHeight: 36,
          ),
        ),
      ],
    );
  }
}
