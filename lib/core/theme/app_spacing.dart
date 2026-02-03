/// Tercen Design System spacing constants.
///
/// Base grid: 8px
/// All values reference design-tokens.md
class AppSpacing {
  AppSpacing._();

  // Core spacing scale (8px base grid)
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;

  // Component heights
  static const double controlHeightSmall = 28.0;
  static const double controlHeightDefault = 36.0;
  static const double controlHeightLarge = 44.0;

  // Panel dimensions
  static const double panelWidth = 280.0;
  static const double panelMinWidth = 280.0;
  static const double panelMaxWidth = 400.0;
  static const double panelCollapsedWidth = 48.0;

  // Header dimensions
  static const double headerHeight = 48.0;
  static const double topBarHeight = 48.0;

  // Border radius
  static const double radiusSm = 4.0;
  static const double radiusMd = 8.0;
  static const double radiusLg = 12.0;
  static const double radiusXl = 16.0;
  static const double radiusFull = 9999.0;

  // Table/Grid
  static const double gridCellGap = 4.0;
  static const double tableRowHeightCompact = 32.0;
  static const double tableRowHeightDefault = 40.0;
  static const double tableRowHeightComfortable = 48.0;
  static const double tableCellPaddingCompact = 12.0;
  static const double tableCellPaddingComfortable = 16.0;

  // Animation durations (milliseconds)
  static const int transitionFast = 150;
  static const int transitionBase = 200;
  static const int transitionSlow = 300;
}
