import 'package:flutter/foundation.dart';
import 'package:pamsoft_grid_flutter_operator/models/grid_data.dart';
import 'package:pamsoft_grid_flutter_operator/models/enums.dart';
import 'package:pamsoft_grid_flutter_operator/utils/block_slice.dart';

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
  /// [GridStatus.unviewed] until the grid has been loaded once, then
  /// [GridStatus.processed] (green) or [GridStatus.modified] (amber).
  GridStatus getGridStatus(String gridImageId);

  /// Updates the status for a grid image.
  void setGridStatus(String gridImageId, GridStatus status);

  /// Number of grid images the user has modified in this session.
  int get modifiedCount;

  /// Number of grid images opened in this session, modified or not.
  int get viewedCount;

  /// Saves all grid data to Tercen as an operator result.
  ///
  /// [allGridImageIds] - All grid image IDs in the experiment.
  /// Loads any unvisited grids, builds the output table, and saves via ctx.saveTable().
  Future<void> saveAllGrids(List<String> allGridImageIds);

  /// Progress of the one-off load of the whole crosstab, for a determinate
  /// bar. `null` before it starts; [LoadProgress.isComplete] once it is done.
  ValueListenable<LoadProgress?> get loadProgress;

  /// Progress of [saveAllGrids] while it runs, `null` otherwise.
  ValueListenable<LoadProgress?> get saveProgress;

  /// After [saveAllGrids], waits for the platform to mark the step's task
  /// complete. Returns true when the task reached Done, false when it failed
  /// or [timeout] elapsed first. Implementations without a task return true.
  Future<bool> waitForTaskCompletion({Duration timeout});
}
