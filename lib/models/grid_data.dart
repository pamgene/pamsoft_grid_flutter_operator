import 'package:pamsoft_grid_flutter_operator/models/fiducial_position.dart';

/// Contains all grid data for a single grid image.
class GridData {
  /// The grid image this data belongs to.
  final String gridImageId;

  /// All fiducial positions in the grid.
  final List<FiducialPosition> fiducials;

  /// Global X offset (for whole-grid dragging).
  double globalOffsetX;

  /// Global Y offset (for whole-grid dragging).
  double globalOffsetY;

  GridData({
    required this.gridImageId,
    required this.fiducials,
    this.globalOffsetX = 0,
    this.globalOffsetY = 0,
  });

  /// Creates a deep copy of the grid data.
  GridData copyWith({
    String? gridImageId,
    List<FiducialPosition>? fiducials,
    double? globalOffsetX,
    double? globalOffsetY,
  }) {
    return GridData(
      gridImageId: gridImageId ?? this.gridImageId,
      fiducials: fiducials ?? this.fiducials.map((f) => f.copyWith()).toList(),
      globalOffsetX: globalOffsetX ?? this.globalOffsetX,
      globalOffsetY: globalOffsetY ?? this.globalOffsetY,
    );
  }

  /// Gets the number of peptide spots.
  int get peptideCount => fiducials.where((f) => !f.isReference).length;

  /// Gets the number of reference fiducials.
  int get referenceCount => fiducials.where((f) => f.isReference).length;
}
