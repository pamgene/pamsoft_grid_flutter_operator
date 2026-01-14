/// Configuration parameters for grid positioning and rendering.
///
/// Based on Pamgene/Pamstation equipment parameters:
/// - Evolve3: spotPitch = 17.0 pixels
/// - Evolve2: spotPitch = 21.5 pixels
class GridConfiguration {
  /// Distance between spot centers in pixels.
  /// This is the fundamental spacing parameter.
  final double spotPitch;

  /// Size factor for rendering spots (0.0 to 1.0).
  /// Rendered diameter = spotPitch * spotSize
  final double spotSize;

  /// Number of rows in the peptide grid.
  final int gridRows;

  /// Number of columns in the peptide grid.
  final int gridCols;

  /// X coordinate of grid center on the image (in image pixels).
  final double centerX;

  /// Y coordinate of grid center on the image (in image pixels).
  final double centerY;

  /// Grid rotation angle in radians.
  double rotation;

  /// Original image width (before display scaling).
  final double imageWidth;

  /// Original image height (before display scaling).
  final double imageHeight;

  GridConfiguration({
    required this.spotPitch,
    this.spotSize = 0.66,
    this.gridRows = 14,
    this.gridCols = 14,
    required this.centerX,
    required this.centerY,
    this.rotation = 0.0,
    required this.imageWidth,
    required this.imageHeight,
  });

  /// Calculates the rendered spot radius.
  double get spotRadius => (spotPitch * spotSize) / 2;

  /// Calculates the rendered spot diameter.
  double get spotDiameter => spotPitch * spotSize;

  /// Creates a copy with updated values.
  GridConfiguration copyWith({
    double? spotPitch,
    double? spotSize,
    int? gridRows,
    int? gridCols,
    double? centerX,
    double? centerY,
    double? rotation,
    double? imageWidth,
    double? imageHeight,
  }) {
    return GridConfiguration(
      spotPitch: spotPitch ?? this.spotPitch,
      spotSize: spotSize ?? this.spotSize,
      gridRows: gridRows ?? this.gridRows,
      gridCols: gridCols ?? this.gridCols,
      centerX: centerX ?? this.centerX,
      centerY: centerY ?? this.centerY,
      rotation: rotation ?? this.rotation,
      imageWidth: imageWidth ?? this.imageWidth,
      imageHeight: imageHeight ?? this.imageHeight,
    );
  }

  /// Creates default configuration for Evolve3 equipment.
  factory GridConfiguration.evolve3({
    required double imageWidth,
    required double imageHeight,
  }) {
    return GridConfiguration(
      spotPitch: 17.0,
      spotSize: 0.66,
      gridRows: 14,
      gridCols: 14,
      centerX: imageWidth / 2,
      centerY: imageHeight / 2,
      imageWidth: imageWidth,
      imageHeight: imageHeight,
    );
  }

  /// Creates default configuration for Evolve2 equipment.
  factory GridConfiguration.evolve2({
    required double imageWidth,
    required double imageHeight,
  }) {
    return GridConfiguration(
      spotPitch: 21.5,
      spotSize: 0.66,
      gridRows: 14,
      gridCols: 14,
      centerX: imageWidth / 2,
      centerY: imageHeight / 2,
      imageWidth: imageWidth,
      imageHeight: imageHeight,
    );
  }
}
