import 'dart:math';
import 'package:pamsoft_grid_flutter_operator/models/grid_data.dart';
import 'package:pamsoft_grid_flutter_operator/models/grid_configuration.dart';
import 'package:pamsoft_grid_flutter_operator/models/fiducial_position.dart';
import 'package:pamsoft_grid_flutter_operator/models/enums.dart';
import 'package:pamsoft_grid_flutter_operator/services/grid_service.dart';
import 'package:pamsoft_grid_flutter_operator/utils/constants.dart';

/// Mock implementation of GridService for development and testing.
class MockGridService implements GridService {
  final Map<String, GridData> _gridDataCache = {};
  final Map<String, GridStatus> _statusCache = {};
  final Random _random = Random(42); // Seeded for consistency

  /// Creates a default grid configuration for the current image dimensions.
  /// Uses Evolve3 parameters by default.
  GridConfiguration _createDefaultConfiguration() {
    return GridConfiguration.evolve3(
      imageWidth: AppConstants.imageOriginalWidth,
      imageHeight: AppConstants.imageOriginalHeight,
    );
  }

  @override
  Future<GridData> loadGridData(String gridImageId) async {
    await Future.delayed(const Duration(milliseconds: 200));

    if (_gridDataCache.containsKey(gridImageId)) {
      return _gridDataCache[gridImageId]!;
    }

    // Generate mock fitted grid (control file + small random offsets)
    final gridData = _generateMockFittedGrid(gridImageId);
    _gridDataCache[gridImageId] = gridData;
    _statusCache[gridImageId] = GridStatus.processed;

    return gridData;
  }

  GridData _generateMockFittedGrid(String gridImageId) {
    final config = _createDefaultConfiguration();
    final fiducials = <FiducialPosition>[];

    // Reference fiducials from Array Layout file:
    // Left group (⊢ "right tack" shape): rows -1,-3,-5 at col -1, plus row -3 at col -2
    // Right group (⌐ "backwards L" shape): rows -2,-4,-6 at col -20, plus row -6 at col -19
    final refPositions = [
      (row: -1, col: -1),
      (row: -3, col: -1),
      (row: -5, col: -1),
      (row: -3, col: -2),
      (row: -2, col: -20),
      (row: -4, col: -20),
      (row: -6, col: -20),
      (row: -6, col: -19),
    ];

    // Calculate reference fiducials' OWN midpoint (matching Shiny algorithm exactly)
    // Reference rows abs: [1,3,5,3,2,4,6,6] -> min=1, max=6 -> rmp = 1 + (6-1)/2 = 3.5
    // Reference cols abs: [1,1,1,2,20,20,20,19] -> min=1, max=20 -> cmp = 1 + (20-1)/2 = 10.5
    const refRowMidpoint = 3.5;
    const refColMidpoint = 10.5;

    // Shiny algorithm for references (before final swap):
    // x = imCenter.x + spotPitch*(absRow - rmp) + 1
    // y = imCenter.y + spotPitch*(absCol - cmp) + 1
    // Then final: display_x = y, display_y = x (swap)
    //
    // Since Flutter doesn't transpose the image, we need to account for this.
    // Shiny uses swapped dimensions: imCenter.x = 413/2, imCenter.y = 552/2
    // Flutter uses normal: centerX = 552/2 = 276, centerY = 413/2 = 206.5
    //
    // After working through the math, for non-transposed display:
    // We use col for X position, row for Y position (no swap needed)
    for (int i = 0; i < refPositions.length; i++) {
      final ref = refPositions[i];
      final absRow = ref.row.abs();
      final absCol = ref.col.abs();

      // Position relative to reference group's own midpoint, then center on image
      final baseX = config.centerX + config.spotPitch * (absCol - refColMidpoint);
      final baseY = config.centerY + config.spotPitch * (absRow - refRowMidpoint);

      fiducials.add(FiducialPosition(
        id: 'ref_$i',
        row: ref.row,
        col: ref.col,
        baseX: baseX,
        baseY: baseY,
        diameter: config.spotDiameter,
        isReference: true,
      ));
    }

    // Peptide grid midpoint (14x14 grid, indices 0-13)
    // rmp = 0 + (13-0)/2 = 6.5, cmp = 0 + (13-0)/2 = 6.5
    final peptideRowMidpoint = (config.gridRows - 1) / 2;
    final peptideColMidpoint = (config.gridCols - 1) / 2;

    // Generate 14x14 peptide grid
    for (int row = 0; row < config.gridRows; row++) {
      for (int col = 0; col < config.gridCols; col++) {
        final baseX = config.centerX + config.spotPitch * (col - peptideColMidpoint);
        final baseY = config.centerY + config.spotPitch * (row - peptideRowMidpoint);

        // Add small random offset to simulate algorithm fit
        final offsetX = (_random.nextDouble() - 0.5) * 2;
        final offsetY = (_random.nextDouble() - 0.5) * 2;

        fiducials.add(FiducialPosition(
          id: 'peptide_${row}_$col',
          row: row,
          col: col,
          baseX: baseX + offsetX,
          baseY: baseY + offsetY,
          diameter: config.spotDiameter,
          isReference: false,
        ));
      }
    }

    return GridData(
      gridImageId: gridImageId,
      configuration: config,
      fiducials: fiducials,
      globalOffsetX: 0,
      globalOffsetY: 0,
    );
  }

  @override
  Future<void> saveGridAdjustments(String gridImageId, GridData gridData) async {
    await Future.delayed(const Duration(milliseconds: 100));
    _gridDataCache[gridImageId] = gridData;
    _statusCache[gridImageId] = GridStatus.modified;
  }

  @override
  Future<GridData> loadDefaultGrid() async {
    await Future.delayed(const Duration(milliseconds: 200));

    final config = _createDefaultConfiguration();
    final fiducials = <FiducialPosition>[];

    // Reference fiducials (same positioning as _generateMockFittedGrid)
    final refPositions = [
      (row: -1, col: -1),
      (row: -3, col: -1),
      (row: -5, col: -1),
      (row: -3, col: -2),
      (row: -2, col: -20),
      (row: -4, col: -20),
      (row: -6, col: -20),
      (row: -6, col: -19),
    ];

    // Reference group's own midpoint
    const refRowMidpoint = 3.5;
    const refColMidpoint = 10.5;

    for (int i = 0; i < refPositions.length; i++) {
      final ref = refPositions[i];
      final absRow = ref.row.abs();
      final absCol = ref.col.abs();

      final baseX = config.centerX + config.spotPitch * (absCol - refColMidpoint);
      final baseY = config.centerY + config.spotPitch * (absRow - refRowMidpoint);

      fiducials.add(FiducialPosition(
        id: 'ref_$i',
        row: ref.row,
        col: ref.col,
        baseX: baseX,
        baseY: baseY,
        diameter: config.spotDiameter,
        isReference: true,
      ));
    }

    // Peptide grid midpoint
    final peptideRowMidpoint = (config.gridRows - 1) / 2;
    final peptideColMidpoint = (config.gridCols - 1) / 2;

    // Generate 14x14 peptide grid (no random offsets for default)
    for (int row = 0; row < config.gridRows; row++) {
      for (int col = 0; col < config.gridCols; col++) {
        final baseX = config.centerX + config.spotPitch * (col - peptideColMidpoint);
        final baseY = config.centerY + config.spotPitch * (row - peptideRowMidpoint);

        fiducials.add(FiducialPosition(
          id: 'peptide_${row}_$col',
          row: row,
          col: col,
          baseX: baseX,
          baseY: baseY,
          diameter: config.spotDiameter,
          isReference: false,
        ));
      }
    }

    return GridData(
      gridImageId: 'default',
      configuration: config,
      fiducials: fiducials,
      globalOffsetX: 0,
      globalOffsetY: 0,
    );
  }

  @override
  Future<GridData> runGridProcessing(String gridImageId) async {
    // Simulate 5-second processing delay
    await Future.delayed(const Duration(seconds: 5));

    // Mark as processed
    _statusCache[gridImageId] = GridStatus.processed;

    // Return current grid data (with adjustments applied)
    return _gridDataCache[gridImageId] ?? await loadGridData(gridImageId);
  }

  @override
  GridStatus getGridStatus(String gridImageId) {
    return _statusCache[gridImageId] ?? GridStatus.processed;
  }

  @override
  void setGridStatus(String gridImageId, GridStatus status) {
    _statusCache[gridImageId] = status;
  }

  @override
  Future<void> saveAllGrids(List<String> allGridImageIds) async {
    // Mock: no-op (CSV export handled separately)
    print('MockGridService.saveAllGrids: no-op');
  }
}
