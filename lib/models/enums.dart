/// Status of a grid image in the QC workflow.
enum GridStatus {
  /// Grid has been processed (shown as green indicator)
  processed,

  /// Grid has been modified but not yet processed (shown as yellow indicator)
  modified,
}
