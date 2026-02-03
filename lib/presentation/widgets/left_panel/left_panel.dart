import 'package:flutter/material.dart';
import 'package:pamsoft_grid_flutter_operator/core/theme/app_spacing.dart';
import 'left_panel_header.dart';
import 'left_panel_section.dart';

export 'left_panel_section.dart' show LeftPanelSection;

/// Tercen left panel component.
///
/// Implements the left-panel.md pattern with:
/// - Accent-colored header with app icon, title, theme toggle, collapse chevron
/// - Scrollable sections with UPPERCASE labels
/// - Collapsible to 48px icon strip
/// - Drag-to-resize right edge
class LeftPanel extends StatefulWidget {
  final String appTitle;
  final IconData appIcon;
  final List<LeftPanelSection> sections;
  final bool isCollapsed;
  final double width;
  final VoidCallback onToggleCollapse;
  final ValueChanged<double> onResize;

  const LeftPanel({
    super.key,
    required this.appTitle,
    required this.appIcon,
    required this.sections,
    required this.isCollapsed,
    required this.width,
    required this.onToggleCollapse,
    required this.onResize,
  });

  @override
  State<LeftPanel> createState() => _LeftPanelState();
}

class _LeftPanelState extends State<LeftPanel> {
  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _sectionKeys = {};
  bool _isResizeHovered = false;

  @override
  void initState() {
    super.initState();
    // Create keys for each section
    for (var i = 0; i < widget.sections.length; i++) {
      _sectionKeys[widget.sections[i].label] = GlobalKey();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onSectionIconTap(String sectionLabel) {
    if (widget.isCollapsed) {
      // Expand panel
      widget.onToggleCollapse();

      // After animation completes, scroll to section
      Future.delayed(
        const Duration(milliseconds: AppSpacing.transitionBase),
        () {
          final key = _sectionKeys[sectionLabel];
          if (key?.currentContext != null) {
            Scrollable.ensureVisible(
              key!.currentContext!,
              duration: const Duration(milliseconds: AppSpacing.transitionSlow),
              curve: Curves.easeInOut,
            );
          }
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Main panel content
        AnimatedContainer(
          duration: const Duration(milliseconds: AppSpacing.transitionBase),
          width: widget.isCollapsed
              ? AppSpacing.panelCollapsedWidth
              : widget.width,
          decoration: BoxDecoration(
            color: colorScheme.surface,
            border: Border(
              right: BorderSide(color: colorScheme.outlineVariant),
            ),
          ),
          child: Column(
            children: [
              // Header
              LeftPanelHeader(
                appTitle: widget.appTitle,
                appIcon: widget.appIcon,
                isCollapsed: widget.isCollapsed,
                onToggleCollapse: widget.onToggleCollapse,
                onIconTap: widget.isCollapsed ? widget.onToggleCollapse : null,
              ),

              // Content area
              Expanded(
                child: widget.isCollapsed
                    ? _buildCollapsedIconStrip(colorScheme)
                    : _buildExpandedContent(),
              ),

              // Footer (collapse chevron when collapsed)
              if (widget.isCollapsed) _buildCollapseFooter(colorScheme),
            ],
          ),
        ),

        // Resize handle (only when expanded)
        if (!widget.isCollapsed) _buildResizeHandle(colorScheme),
      ],
    );
  }

  Widget _buildResizeHandle(ColorScheme colorScheme) {
    return MouseRegion(
      cursor: SystemMouseCursors.resizeColumn,
      onEnter: (_) => setState(() => _isResizeHovered = true),
      onExit: (_) => setState(() => _isResizeHovered = false),
      child: GestureDetector(
        onHorizontalDragUpdate: (details) {
          widget.onResize(details.delta.dx);
        },
        child: Container(
          width: 8,
          color: Colors.transparent,
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: _isResizeHovered ? 4 : 1,
              color: _isResizeHovered
                  ? colorScheme.primary
                  : colorScheme.outlineVariant,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedContent() {
    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.zero,
      itemCount: widget.sections.length,
      itemBuilder: (context, index) {
        final section = widget.sections[index];
        return KeyedSubtree(
          key: _sectionKeys[section.label],
          child: section,
        );
      },
    );
  }

  Widget _buildCollapsedIconStrip(ColorScheme colorScheme) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      itemCount: widget.sections.length,
      itemBuilder: (context, index) {
        final section = widget.sections[index];
        return Tooltip(
          message: section.label,
          preferBelow: false,
          child: InkWell(
            onTap: () => _onSectionIconTap(section.label),
            child: Container(
              width: AppSpacing.panelCollapsedWidth,
              height: AppSpacing.panelCollapsedWidth,
              alignment: Alignment.center,
              child: Icon(
                section.icon,
                size: 18,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCollapseFooter(ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      child: InkWell(
        onTap: widget.onToggleCollapse,
        child: Container(
          width: AppSpacing.panelCollapsedWidth,
          height: AppSpacing.panelCollapsedWidth,
          alignment: Alignment.center,
          child: Icon(
            Icons.chevron_right,
            color: colorScheme.onSurfaceVariant,
            size: 20,
          ),
        ),
      ),
    );
  }
}
