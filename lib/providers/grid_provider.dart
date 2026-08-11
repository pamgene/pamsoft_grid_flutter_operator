import 'package:flutter/foundation.dart';
import 'package:pamsoft_grid_flutter_operator/di/service_locator.dart';
import 'package:pamsoft_grid_flutter_operator/models/grid_data.dart';
import 'package:pamsoft_grid_flutter_operator/models/enums.dart';
import 'package:pamsoft_grid_flutter_operator/models/grid_configuration.dart';
import 'package:pamsoft_grid_flutter_operator/models/operator_properties.dart';
import 'package:pamsoft_grid_flutter_operator/services/grid_service.dart';
import 'package:pamsoft_grid_flutter_operator/services/image_service.dart';
import 'package:pamsoft_grid_flutter_operator/services/properties_service.dart';
import 'dart:math' as math;

/// Provider for managing grid state and interactions.
class GridProvider extends ChangeNotifier {
  final GridService _gridService = locator<GridService>();
  final PropertiesService _propertiesService = locator<PropertiesService>();

  GridData? _currentGridData;
  String? _currentGridImageId;
  bool _isLoading = false;
  bool _isProcessing = false;
  String? _error;

  OperatorProperties? _properties;

  /// Dimensions of the image currently on screen, once one has been decoded.
  ///
  /// The grid coordinates from Tercen are in image pixels, so the overlay's
  /// scale is only right when the configuration carries the real dimensions —
  /// they used to be hardcoded to the Evolve3 552x413.
  double? _imageWidth;
  double? _imageHeight;

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
      _properties ??= await _propertiesService.getProperties();
      // Mutate in place rather than copyWith: the grid service hands out a
      // cached instance, and edits made through this provider are expected to
      // land on that same object.
      final data = await _gridService.loadGridData(gridImageId);
      data.configuration = _applyProperties(data.configuration);
      _currentGridData = data;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Records the dimensions of the decoded image on screen.
  ///
  /// Called once the image is decoded, which may be after the grid loads, so
  /// the configuration is rebuilt when they arrive or change.
  void setImageSize(double width, double height) {
    if (_imageWidth == width && _imageHeight == height) return;
    _imageWidth = width;
    _imageHeight = height;

    final data = _currentGridData;
    if (data == null) return;
    data.configuration = _applyProperties(data.configuration);
    notifyListeners();
  }

  /// Folds the operator properties and the real image dimensions into a
  /// configuration loaded from the grid service.
  GridConfiguration _applyProperties(GridConfiguration base) {
    final props = _properties ?? OperatorProperties.defaults;
    final width = _imageWidth ?? base.imageWidth;
    final height = _imageHeight ?? base.imageHeight;
    final dimensionsChanged =
        width != base.imageWidth || height != base.imageHeight;

    return base.copyWith(
      spotPitch:
          OperatorProperties.resolveSpotPitch(props.spotPitch, width, height),
      spotSize: props.spotSize,
      imageWidth: width,
      imageHeight: height,
      // Both construction sites centre the grid in the image; keep that true
      // if the dimensions turn out to differ from what the service assumed.
      centerX: dimensionsChanged ? width / 2 : base.centerX,
      centerY: dimensionsChanged ? height / 2 : base.centerY,
    );
  }

  /// Moves the entire grid by an offset.
  void moveWholeGrid(double dx, double dy) {
    if (_currentGridData == null) return;

    _currentGridData!.globalOffsetX += dx;
    _currentGridData!.globalOffsetY += dy;

    // Mark all fiducials as manually adjusted
    for (final fiducial in _currentGridData!.fiducials) {
      fiducial.isManual = true;
    }

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
    _currentGridData!.fiducials[fiducialIndex].isManual = true;

    _markAsModified();
    notifyListeners();
  }

  /// Rotates the entire grid around a center point.
  void rotateWholeGrid(double radians, double centerX, double centerY) {
    if (_currentGridData == null) return;

    // Accumulate rotation
    _currentGridData!.rotation += radians;

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
      fiducial.isManual = true;
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

  /// "New Grid": resets the current grid to a clean, regularly-spaced lattice.
  ///
  /// This operator has no grid-finding algorithm, so "New Grid" simply lays out
  /// a uniform lattice for the user to fine-tune. It MUST preserve the real
  /// chip's spots — their id / ci / row / col / diameter / reference flag — so
  /// that on save each spot maps back to the correct column.
  ///
  /// The previous implementation pulled a mock default (a hardcoded 14x14
  /// peptide grid at indices 0..13, plus fixed refs, built on the assumed
  /// 552x413 image). Those indices/positions did not match the real spot
  /// layout, so on save the mismatched spots collapsed onto one another —
  /// producing the overlapping grid spots reported after "New Grid".
  Future<void> resetToDefaultGrid() async {
    if (_currentGridImageId == null || _currentGridData == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      _currentGridData = _buildRegularDefault(_currentGridData!);
      _markAsModified();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Builds a clean, regularly-spaced grid from [src], preserving every real
  /// spot (id/ci/row/col/diameter/reference flag) and only resetting positions.
  ///
  /// The peptide spots are laid out on a uniform lattice fitted (least squares)
  /// to the current grid's actual positions, so the default matches the real
  /// image — pitch, offset and orientation — instead of a hardcoded
  /// 552x413 / pitch-17 / 14x14 assumption. Reference fiducials use a separate
  /// index convention (outlier row/col values) so they are kept at their current
  /// positions rather than forced onto the peptide lattice, which would distort
  /// them. Preserving each spot's row/col/ci also guarantees the saved grid maps
  /// back to the correct columns (no collapsed/overlapping spots).
  GridData _buildRegularDefault(GridData src) {
    final fids = src.fiducials;
    if (fids.isEmpty) return src;

    double curX(f) => f.baseX + f.individualOffsetX + src.globalOffsetX;
    double curY(f) => f.baseY + f.individualOffsetY + src.globalOffsetY;

    final peptides = fids.where((f) => !f.isReference).toList();
    final basis = peptides.length >= 4 ? peptides : fids;

    double mean(List<double> v) => v.reduce((a, b) => a + b) / v.length;
    double slope(List<double> idx, List<double> pos) {
      final mi = mean(idx), mp = mean(pos);
      var num = 0.0, den = 0.0;
      for (var i = 0; i < idx.length; i++) {
        num += (idx[i] - mi) * (pos[i] - mp);
        den += (idx[i] - mi) * (idx[i] - mi);
      }
      return den == 0 ? src.configuration.spotPitch : num / den;
    }

    double absCorr(List<double> a, List<double> b) {
      final ma = mean(a), mb = mean(b);
      var num = 0.0, da = 0.0, db = 0.0;
      for (var i = 0; i < a.length; i++) {
        num += (a[i] - ma) * (b[i] - mb);
        da += (a[i] - ma) * (a[i] - ma);
        db += (b[i] - mb) * (b[i] - mb);
      }
      final d = math.sqrt(da * db);
      return d == 0 ? 0 : (num / d).abs();
    }

    final rowsD = [for (final f in basis) f.row.toDouble()];
    final colsD = [for (final f in basis) f.col.toDouble()];
    final xsD = [for (final f in basis) curX(f)];
    final ysD = [for (final f in basis) curY(f)];

    // This operator swaps axes on read (baseX <- gridY), so X follows the row
    // index and Y the col index; detect it so the layout stays correct even if
    // that convention changes.
    final xFollowsRow = absCorr(xsD, rowsD) >= absCorr(xsD, colsD);
    final xIdx = xFollowsRow ? rowsD : colsD;
    final yIdx = xFollowsRow ? colsD : rowsD;
    final bx = slope(xIdx, xsD), by = slope(yIdx, ysD);
    final miX = mean(xIdx), miY = mean(yIdx), mX = mean(xsD), mY = mean(ysD);
    double ix(f) => (xFollowsRow ? f.row : f.col).toDouble();
    double iy(f) => (xFollowsRow ? f.col : f.row).toDouble();

    final newFids = [
      for (final f in fids)
        f.isReference
            ? f.copyWith(
                baseX: curX(f),
                baseY: curY(f),
                individualOffsetX: 0,
                individualOffsetY: 0,
                isManual: false,
              )
            : f.copyWith(
                baseX: mX + bx * (ix(f) - miX),
                baseY: mY + by * (iy(f) - miY),
                individualOffsetX: 0,
                individualOffsetY: 0,
                isManual: false,
              )
    ];

    return GridData(
      gridImageId: src.gridImageId,
      configuration: src.configuration,
      fiducials: newFids,
      globalOffsetX: 0,
      globalOffsetY: 0,
      rotation: 0,
    );
  }

  /// Saves all grid adjustments to Tercen.
  ///
  /// Collects all grid data (modified and unmodified) across all grid images,
  /// builds the output table, and saves via ctx.saveTable().
  Future<void> runProcessing() async {
    _isProcessing = true;
    _error = null;
    notifyListeners();

    try {
      // Save current grid to cache before saving
      if (_currentGridImageId != null && _currentGridData != null) {
        await _gridService.saveGridAdjustments(
            _currentGridImageId!, _currentGridData!);
      }

      // Get all grid image IDs from the image service
      final imageService = locator<ImageService>();
      final gridImages = await imageService.getGridImages();
      final allGridImageIds = gridImages.map((g) => g.id).toList();

      print('📤 Saving all grids to Tercen (${allGridImageIds.length} grid images)');

      // Save all grids to Tercen
      await _gridService.saveAllGrids(allGridImageIds);

      print('✓ All grids saved to Tercen');
    } catch (e) {
      _error = e.toString();
      print('✗ Error saving to Tercen: $e');
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }
}
