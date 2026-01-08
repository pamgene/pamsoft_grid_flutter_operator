/// Represents a single fiducial position in the grid.
class FiducialPosition {
  /// Unique identifier for this fiducial.
  final String id;

  /// Row in the grid (-ve for reference fiducials).
  final int row;

  /// Column in the grid (-ve for reference fiducials).
  final int col;

  /// Base X coordinate (pixels).
  final double baseX;

  /// Base Y coordinate (pixels).
  final double baseY;

  /// Whether this is a reference fiducial (vs peptide spot).
  final bool isReference;

  /// Individual offset from base position (for individual dragging).
  double individualOffsetX;
  double individualOffsetY;

  FiducialPosition({
    required this.id,
    required this.row,
    required this.col,
    required this.baseX,
    required this.baseY,
    this.isReference = false,
    this.individualOffsetX = 0,
    this.individualOffsetY = 0,
  });

  /// Creates a copy with updated position.
  FiducialPosition copyWith({
    double? baseX,
    double? baseY,
    double? individualOffsetX,
    double? individualOffsetY,
  }) {
    return FiducialPosition(
      id: id,
      row: row,
      col: col,
      baseX: baseX ?? this.baseX,
      baseY: baseY ?? this.baseY,
      isReference: isReference,
      individualOffsetX: individualOffsetX ?? this.individualOffsetX,
      individualOffsetY: individualOffsetY ?? this.individualOffsetY,
    );
  }

  /// Gets the X position including individual offset.
  double get x => baseX + individualOffsetX;

  /// Gets the Y position including individual offset.
  double get y => baseY + individualOffsetY;
}
