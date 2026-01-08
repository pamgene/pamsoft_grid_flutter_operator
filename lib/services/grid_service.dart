import 'package:pamsoft_grid_flutter_operator/models/grid_data.dart';
import 'package:pamsoft_grid_flutter_operator/models/enums.dart';

/// Abstract interface for grid service.
///
/// Provides methods to load, modify, and process grid coordinates.
abstract class GridService {
  /// Loads grid data for a specific grid image.
  ///
  /// Returns fitted grid coordinates from the algorithm (mock data in v0.1.0).
  Future<GridData> loadGridData(String gridImageId);

  /// Saves adjusted grid coordinates.
  ///
  /// [gridImageId] - The grid image identifier.
  /// [gridData] - The adjusted grid data.
  Future<void> saveGridAdjustments(String gridImageId, GridData gridData);

  /// Loads the default grid from control file.
  ///
  /// Used when user clicks "New Grid" to reset to original positions.
  Future<GridData> loadDefaultGrid();

  /// Runs the grid processing algorithm (mock: 5-second delay).
  ///
  /// [gridImageId] - The grid image to process.
  /// Returns processed grid data.
  Future<GridData> runGridProcessing(String gridImageId);

  /// Gets the current status for a grid image.
  ///
  /// Returns [GridStatus.processed] (green) or [GridStatus.modified] (yellow).
  GridStatus getGridStatus(String gridImageId);

  /// Updates the status for a grid image.
  void setGridStatus(String gridImageId, GridStatus status);
}
