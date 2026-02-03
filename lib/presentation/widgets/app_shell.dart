import 'package:flutter/material.dart';
import 'package:pamsoft_grid_flutter_operator/core/theme/app_spacing.dart';
import 'package:pamsoft_grid_flutter_operator/presentation/widgets/left_panel/left_panel.dart';
import 'package:pamsoft_grid_flutter_operator/presentation/widgets/top_bar.dart';

/// Tercen app shell - the overall frame for all Tercen Flutter apps.
///
/// Implements the app-frame.md pattern with:
/// - Left panel (collapsible)
/// - Optional top bar (hidden when embedded in Data Step)
/// - Main content area
class AppShell extends StatefulWidget {
  final String appTitle;
  final IconData appIcon;
  final List<LeftPanelSection> sections;
  final Widget content;
  final VoidCallback? onClose;

  const AppShell({
    super.key,
    required this.appTitle,
    required this.appIcon,
    required this.sections,
    required this.content,
    this.onClose,
  });

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  bool _isCollapsed = false;
  double _panelWidth = AppSpacing.panelWidth;

  /// Check if running inside a Tercen Data Step
  bool get _isInDataStep {
    return Uri.base.queryParameters.containsKey('taskId');
  }

  /// Show top bar when NOT embedded
  bool get _shouldShowTopBar => !_isInDataStep;

  void _toggleCollapse() {
    setState(() {
      _isCollapsed = !_isCollapsed;
    });
  }

  void _onPanelResize(double delta) {
    setState(() {
      _panelWidth = (_panelWidth + delta).clamp(
        AppSpacing.panelMinWidth,
        AppSpacing.panelMaxWidth,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerHighest,
      body: Row(
        children: [
          // Left Panel
          LeftPanel(
            appTitle: widget.appTitle,
            appIcon: widget.appIcon,
            sections: widget.sections,
            isCollapsed: _isCollapsed,
            width: _panelWidth,
            onToggleCollapse: _toggleCollapse,
            onResize: _onPanelResize,
          ),

          // Main Panel
          Expanded(
            child: Column(
              children: [
                // Top Bar (conditional)
                if (_shouldShowTopBar)
                  TopBar(onClose: widget.onClose),

                // Main Content
                Expanded(
                  child: Container(
                    color: colorScheme.surfaceContainerHighest,
                    child: widget.content,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
