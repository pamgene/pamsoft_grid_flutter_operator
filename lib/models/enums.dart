/// Status of a grid image in the QC workflow.
enum GridStatus {
  /// Not opened yet in this session (blue outline). Until 0.0.10 such grids
  /// were shown as [processed], i.e. green, before anyone had looked.
  unviewed,

  /// Opened and left as the algorithm placed it (green indicator).
  processed,

  /// Modified by the user (amber indicator).
  modified,
}
