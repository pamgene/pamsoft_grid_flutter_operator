/// Where the reviewer stands: how many grid images there are, how many were
/// opened, how many were changed. Pure, so the header line, the line under
/// the finish button and the finish confirmation all say the same thing.
///
/// "Viewed" means the grid image was opened in this session. Nothing
/// stronger is available: the app has no per-grid approval, and adding one
/// would cost a click on every grid.
class ReviewProgress {
  /// Grid images in the step (distinct `grdImageNameUsed`).
  final int total;

  /// Grid images opened, changed or not.
  final int viewed;

  /// Grid images the user changed. Always counted among [viewed].
  final int modified;

  const ReviewProgress({
    required this.total,
    required this.viewed,
    required this.modified,
  });

  int get unopened => (total - viewed).clamp(0, total);
  bool get allViewed => total > 0 && unopened == 0;

  static String _grids(int n) => '$n grid${n == 1 ? '' : 's'}';

  /// Header line. [currentIndex] is zero-based.
  String headerLine(int currentIndex) {
    if (total == 0) return 'No grid images';
    final parts = <String>[
      'Grid ${currentIndex + 1} of $total',
      '$viewed viewed',
      '$modified modified',
    ];
    if (unopened > 0) parts.add('$unopened not yet opened');
    return parts.join('  ·  ');
  }

  /// Line under the finish button while it is ready.
  String readyLine() {
    if (modified == 0 && unopened == 0) {
      return 'All grids opened, none modified. Finishing accepts the automatic grids as they are.';
    }
    final parts = <String>[
      modified == 0 ? 'No grid modified' : '${_grids(modified)} modified',
    ];
    if (unopened > 0) parts.add('$unopened not yet opened');
    return parts.join('  ·  ');
  }

  /// Whether Save and finish should ask first.
  bool get needsConfirmation => unopened > 0;

  String get confirmationTitle => 'Finish with unopened grids?';

  String get confirmationBody =>
      '$unopened of $total grids have not been opened. '
      'Their automatic grids will be saved as they are.';
}
