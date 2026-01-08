import 'dart:math';
import 'package:pamsoft_grid_flutter_operator/models/grid_data.dart';
import 'package:pamsoft_grid_flutter_operator/models/fiducial_position.dart';
import 'package:pamsoft_grid_flutter_operator/models/enums.dart';
import 'package:pamsoft_grid_flutter_operator/services/grid_service.dart';
import 'package:pamsoft_grid_flutter_operator/utils/constants.dart';

/// Mock implementation of GridService for development and testing.
class MockGridService implements GridService {
  final Map<String, GridData> _gridDataCache = {};
  final Map<String, GridStatus> _statusCache = {};
  final Random _random = Random(42); // Seeded for consistency

  // Control file grid structure (14x14 peptides + 8 reference fiducials)
  static const int gridRows = 14;
  static const int gridCols = 14;

  // Calculate grid dimensions based on display container size
  // The grid should be centered and sized to match the visible peptide array
  static double get _containerWidth => AppConstants.imageContainerWidth;
  static double get _containerHeight => AppConstants.imageContainerHeight;

  // Grid cell spacing - uniform for square grid
  // Y-axis reduced by 10% from previous, X-axis matches Y-axis for square grid
  static double get _cellSpacing => (_containerHeight * 0.54) / gridRows; // 0.60 * 0.90 = 0.54
  static double get _cellWidth => _cellSpacing;
  static double get _cellHeight => _cellSpacing;

  // Grid starting position - centered in the container
  static double get _gridOffsetX => (_containerWidth - (gridCols * _cellWidth)) / 2;
  static double get _gridOffsetY => (_containerHeight - (gridRows * _cellHeight)) / 2;

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
    final fiducials = <FiducialPosition>[];

    // Generate 14x14 peptide grid
    for (int row = 0; row < gridRows; row++) {
      for (int col = 0; col < gridCols; col++) {
        final baseX = _gridOffsetX + (col * _cellWidth);
        final baseY = _gridOffsetY + (row * _cellHeight);

        // Add small random offset to simulate algorithm fit (reduced variance)
        final offsetX = (_random.nextDouble() - 0.5) * 2;
        final offsetY = (_random.nextDouble() - 0.5) * 2;

        fiducials.add(FiducialPosition(
          id: 'peptide_${row}_$col',
          row: row,
          col: col,
          baseX: baseX + offsetX,
          baseY: baseY + offsetY,
          isReference: false,
        ));
      }
    }

    // Add reference fiducials around edges (positioned relative to grid)
    final refPositions = [
      (row: -1, col: -1),
      (row: -2, col: -1),
      (row: -3, col: -1),
      (row: -1, col: 14),
      (row: -2, col: 14),
      (row: -3, col: 14),
      (row: 14, col: -1),
      (row: 14, col: 14),
    ];

    for (int i = 0; i < refPositions.length; i++) {
      final ref = refPositions[i];
      final baseX = _gridOffsetX + (ref.col * _cellWidth);
      final baseY = _gridOffsetY + (ref.row * _cellHeight);

      fiducials.add(FiducialPosition(
        id: 'ref_$i',
        row: ref.row,
        col: ref.col,
        baseX: baseX,
        baseY: baseY,
        isReference: true,
      ));
    }

    return GridData(
      gridImageId: gridImageId,
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

    // Return grid based purely on control file (no algorithm offsets)
    final fiducials = <FiducialPosition>[];

    for (int row = 0; row < gridRows; row++) {
      for (int col = 0; col < gridCols; col++) {
        fiducials.add(FiducialPosition(
          id: 'peptide_${row}_$col',
          row: row,
          col: col,
          baseX: _gridOffsetX + (col * _cellWidth),
          baseY: _gridOffsetY + (row * _cellHeight),
          isReference: false,
        ));
      }
    }

    // Add reference fiducials
    final refPositions = [
      (row: -1, col: -1),
      (row: -2, col: -1),
      (row: -3, col: -1),
      (row: -1, col: 14),
      (row: -2, col: 14),
      (row: -3, col: 14),
      (row: 14, col: -1),
      (row: 14, col: 14),
    ];

    for (int i = 0; i < refPositions.length; i++) {
      final ref = refPositions[i];
      fiducials.add(FiducialPosition(
        id: 'ref_$i',
        row: ref.row,
        col: ref.col,
        baseX: _gridOffsetX + (ref.col * _cellWidth),
        baseY: _gridOffsetY + (ref.row * _cellHeight),
        isReference: true,
      ));
    }

    return GridData(
      gridImageId: 'default',
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
