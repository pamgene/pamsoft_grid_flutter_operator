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
    final rowMidpoint = (config.gridRows - 1) / 2;
    final colMidpoint = (config.gridCols - 1) / 2;

    final fiducials = <FiducialPosition>[];

    // Generate 14x14 peptide grid using configuration-based positioning
    for (int row = 0; row < config.gridRows; row++) {
      for (int col = 0; col < config.gridCols; col++) {
        // Calculate position relative to center
        final baseX = config.centerX + config.spotPitch * (col - colMidpoint);
        final baseY = config.centerY + config.spotPitch * (row - rowMidpoint);

        // Add small random offset to simulate algorithm fit (reduced variance)
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

    // Add reference fiducials around edges (positioned relative to grid)
    final refPositions = [
      (row: -1, col: -1),
      (row: -2, col: -1),
      (row: -3, col: -1),
      (row: -1, col: config.gridCols),
      (row: -2, col: config.gridCols),
      (row: -3, col: config.gridCols),
      (row: config.gridRows, col: -1),
      (row: config.gridRows, col: config.gridCols),
    ];

    for (int i = 0; i < refPositions.length; i++) {
      final ref = refPositions[i];
      final baseX = config.centerX + config.spotPitch * (ref.col - colMidpoint);
      final baseY = config.centerY + config.spotPitch * (ref.row - rowMidpoint);

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
    final rowMidpoint = (config.gridRows - 1) / 2;
    final colMidpoint = (config.gridCols - 1) / 2;

    // Return grid based purely on control file (no algorithm offsets)
    final fiducials = <FiducialPosition>[];

    for (int row = 0; row < config.gridRows; row++) {
      for (int col = 0; col < config.gridCols; col++) {
        final baseX = config.centerX + config.spotPitch * (col - colMidpoint);
        final baseY = config.centerY + config.spotPitch * (row - rowMidpoint);

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

    // Add reference fiducials
    final refPositions = [
      (row: -1, col: -1),
      (row: -2, col: -1),
      (row: -3, col: -1),
      (row: -1, col: config.gridCols),
      (row: -2, col: config.gridCols),
      (row: -3, col: config.gridCols),
      (row: config.gridRows, col: -1),
      (row: config.gridRows, col: config.gridCols),
    ];

    for (int i = 0; i < refPositions.length; i++) {
      final ref = refPositions[i];
      final baseX = config.centerX + config.spotPitch * (ref.col - colMidpoint);
      final baseY = config.centerY + config.spotPitch * (ref.row - rowMidpoint);

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
}
