import 'package:flutter/foundation.dart';
import 'package:pamsoft_grid_flutter_operator/di/service_locator.dart';
import 'package:pamsoft_grid_flutter_operator/models/grid_data.dart';
import 'package:pamsoft_grid_flutter_operator/models/enums.dart';
import 'package:pamsoft_grid_flutter_operator/services/grid_service.dart';
import 'dart:math' as math;

/// Provider for managing grid state and interactions.
class GridProvider extends ChangeNotifier {
  final GridService _gridService = locator<GridService>();

  GridData? _currentGridData;
  String? _currentGridImageId;
  bool _isLoading = false;
  bool _isProcessing = false;
  String? _error;

  GridData? get currentGridData => _currentGridData;
  String? get currentGridImageId => _currentGridImageId;
  bool get isLoading => _isLoading;
  bool get isProcessing => _isProcessing;
  String? get error => _error;

  /// Gets the current grid status.
  GridStatus get currentStatus =>
      _currentGridImageId != null
          ? _gridService.getGridStatus(_currentGridImageId!)
          : GridStatus.processed;

  /// Loads grid data for a specific grid image.
  Future<void> loadGrid(String gridImageId) async {
    _isLoading = true;
    _error = null;
    _currentGridImageId = gridImageId;
    notifyListeners();

    try {
      _currentGridData = await _gridService.loadGridData(gridImageId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Moves the entire grid by an offset.
  void moveWholeGrid(double dx, double dy) {
    if (_currentGridData == null) return;

    _currentGridData!.globalOffsetX += dx;
    _currentGridData!.globalOffsetY += dy;

    _markAsModified();
    notifyListeners();
  }

  /// Moves a single fiducial by an offset.
  void moveFiducial(String fiducialId, double dx, double dy) {
    if (_currentGridData == null) return;

    final fiducialIndex = _currentGridData!.fiducials.indexWhere(
      (f) => f.id == fiducialId,
    );

    if (fiducialIndex == -1) return;

    _currentGridData!.fiducials[fiducialIndex].individualOffsetX += dx;
    _currentGridData!.fiducials[fiducialIndex].individualOffsetY += dy;

    _markAsModified();
    notifyListeners();
  }

  /// Rotates the entire grid around a center point.
  void rotateWholeGrid(double radians, double centerX, double centerY) {
    if (_currentGridData == null) return;

    final cos = math.cos(radians);
    final sin = math.sin(radians);

    for (final fiducial in _currentGridData!.fiducials) {
      // Get current position
      final currentX = fiducial.x + _currentGridData!.globalOffsetX;
      final currentY = fiducial.y + _currentGridData!.globalOffsetY;

      // Translate to origin (relative to center)
      final relX = currentX - centerX;
      final relY = currentY - centerY;

      // Apply rotation
      final newX = (cos * relX) + (sin * relY);
      final newY = (cos * relY) - (sin * relX);

      // Translate back
      final rotatedX = newX + centerX;
      final rotatedY = newY + centerY;

      // Update fiducial position by adjusting its base coordinates
      // Since we're working with global offset, we need to update the individual offsets
      fiducial.individualOffsetX += rotatedX - currentX;
      fiducial.individualOffsetY += rotatedY - currentY;
    }

    _markAsModified();
    notifyListeners();
  }

  void _markAsModified() {
    if (_currentGridImageId != null) {
      _gridService.setGridStatus(_currentGridImageId!, GridStatus.modified);
      _gridService.saveGridAdjustments(_currentGridImageId!, _currentGridData!);
    }
  }

  /// Resets to default grid from control file.
  Future<void> resetToDefaultGrid() async {
    if (_currentGridImageId == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final defaultGrid = await _gridService.loadDefaultGrid();
      _currentGridData = GridData(
        gridImageId: _currentGridImageId!,
        fiducials: defaultGrid.fiducials,
        globalOffsetX: 0,
        globalOffsetY: 0,
      );
      _markAsModified();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Runs grid processing (5-second mock delay).
  Future<void> runProcessing() async {
    if (_currentGridImageId == null) return;

    _isProcessing = true;
    notifyListeners();

    try {
      _currentGridData =
          await _gridService.runGridProcessing(_currentGridImageId!);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }
}
