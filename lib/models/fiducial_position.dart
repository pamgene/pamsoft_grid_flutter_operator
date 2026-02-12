/// Represents a single fiducial position in the grid.
class FiducialPosition {
  /// Unique identifier for this fiducial.
  final String id;

  /// Original Tercen .ci column index (identifies this spot in the cross-tab).
  final int ci;

  /// Image name this spot belongs to (from Tercen column metadata).
  final String imageName;

  /// Grid image name used for positioning this spot (from Tercen column metadata).
  final String grdImageNameUsed;

  /// Row in the grid (-ve for reference fiducials).
  final int row;

  /// Column in the grid (-ve for reference fiducials).
  final int col;

  /// Base X coordinate (pixels) - from algorithm or input data.
  final double baseX;

  /// Base Y coordinate (pixels) - from algorithm or input data.
  final double baseY;

  /// Spot diameter for rendering (from input data).
  final double diameter;

  /// Whether this is a reference fiducial (vs peptide spot).
  final bool isReference;

  /// Whether this spot is marked as "bad" (quality flag).
  final bool isBad;

  /// Whether this spot is marked as "empty".
  final bool isEmpty;

  /// Whether this position was manually adjusted.
  bool isManual;

  /// Individual X offset from base position (for individual dragging).
  double individualOffsetX;

  /// Individual Y offset from base position (for individual dragging).
  double individualOffsetY;

  FiducialPosition({
    required this.id,
    this.ci = 0,
    this.imageName = '',
    this.grdImageNameUsed = '',
    required this.row,
    required this.col,
    required this.baseX,
    required this.baseY,
    this.diameter = 0.0,
    this.isReference = false,
    this.isBad = false,
    this.isEmpty = false,
    this.isManual = false,
    this.individualOffsetX = 0,
    this.individualOffsetY = 0,
  });

  /// Creates a copy with updated position.
  FiducialPosition copyWith({
    double? baseX,
    double? baseY,
    double? diameter,
    bool? isBad,
    bool? isEmpty,
    bool? isManual,
    double? individualOffsetX,
    double? individualOffsetY,
  }) {
    return FiducialPosition(
      id: id,
      ci: ci,
      imageName: imageName,
      grdImageNameUsed: grdImageNameUsed,
      row: row,
      col: col,
      baseX: baseX ?? this.baseX,
      baseY: baseY ?? this.baseY,
      diameter: diameter ?? this.diameter,
      isReference: isReference,
      isBad: isBad ?? this.isBad,
      isEmpty: isEmpty ?? this.isEmpty,
      isManual: isManual ?? this.isManual,
      individualOffsetX: individualOffsetX ?? this.individualOffsetX,
      individualOffsetY: individualOffsetY ?? this.individualOffsetY,
    );
  }

  /// Gets the X position including individual offset.
  double get x => baseX + individualOffsetX;

  /// Gets the Y position including individual offset.
  double get y => baseY + individualOffsetY;

  /// Gets the spot radius for rendering.
  double get radius => diameter / 2;
}
