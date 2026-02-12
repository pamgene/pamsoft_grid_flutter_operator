import 'dart:typed_data';

import 'package:pamsoft_grid_flutter_operator/models/grid_data.dart';
import 'package:pamsoft_grid_flutter_operator/models/grid_configuration.dart';
import 'package:pamsoft_grid_flutter_operator/models/fiducial_position.dart';
import 'package:pamsoft_grid_flutter_operator/models/enums.dart';
import 'package:pamsoft_grid_flutter_operator/services/grid_service.dart';
import 'package:pamsoft_grid_flutter_operator/utils/tercen_url_parser.dart';
import 'package:sci_tercen_context/sci_tercen_context.dart';
import 'package:tson/string_list.dart';

/// Tercen implementation of GridService.
///
/// Loads grid data from Tercen tables using OperatorContext (ctx.select/cselect/rselect).
class TercenGridService implements GridService {
  final ServiceFactoryBase _factory;
  final TercenUrlParser _urlParser;
  final GridService _mockService;

  final Map<String, GridData> _gridDataCache = {};
  final Map<String, GridStatus> _statusCache = {};

  /// Cached OperatorContext — created once and reused across loadGridData calls.
  AbstractOperatorContext? _ctx;

  TercenGridService(this._factory, this._urlParser, this._mockService);

  /// Get or create the OperatorContext.
  Future<AbstractOperatorContext> _getContext() async {
    if (_ctx != null) return _ctx!;

    if (_urlParser.taskId == null) {
      throw Exception('No taskId found in URL');
    }

    print('📋 Creating OperatorContext for task: ${_urlParser.taskId}');
    _ctx = await OperatorContext.create(
      serviceFactory: _factory,
      taskId: _urlParser.taskId!,
    );
    print('✓ OperatorContext created');
    return _ctx!;
  }

  @override
  Future<GridData> loadGridData(String gridImageId) async {
    if (_gridDataCache.containsKey(gridImageId)) {
      return _gridDataCache[gridImageId]!;
    }

    try {
      print('🔍 Loading grid data from Tercen for $gridImageId');

      final gridData = await _loadFromTercen(gridImageId);

      _gridDataCache[gridImageId] = gridData;
      _statusCache[gridImageId] = GridStatus.processed;

      print('✓ Loaded ${gridData.fiducials.length} fiducials from Tercen');
      return gridData;
    } catch (e, stackTrace) {
      print('❌ ERROR loading grid data from Tercen: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<GridData> _loadFromTercen(String gridImageId) async {
    final ctx = await _getContext();

    // 1. Fetch the three tables (mirrors R's ctx$select / ctx$cselect / ctx$rselect)
    print('📋 Fetching main data table (.ci, .ri, .y)');
    final qtData = await ctx.select(names: ['.ci', '.ri', '.y']);
    print('✓ qtData: ${qtData.nRows} rows, ${qtData.columns.length} columns');

    final colNames = await ctx.cnames;
    print('📋 Fetching column metadata: $colNames');
    final colData = await ctx.cselect();
    print('✓ colData: ${colData.nRows} rows, ${colData.columns.length} columns');

    final rowNames = await ctx.rnames;
    print('📋 Fetching row metadata: $rowNames');
    final rowData = await ctx.rselect();
    print('✓ rowData: ${rowData.nRows} rows, ${rowData.columns.length} columns');

    // 2. Build column metadata map: ci index -> {Image, spotRow, spotCol, ID, ...}
    final colMetadata = <int, Map<String, dynamic>>{};
    for (final col in colData.columns) {
      final values = col.values as List?;
      if (values == null) continue;
      // Strip namespace prefix (e.g., "ds1.Image" -> "Image")
      final fieldName = col.name.contains('.')
          ? col.name.split('.').last
          : col.name;
      for (int i = 0; i < values.length; i++) {
        colMetadata.putIfAbsent(i, () => {});
        colMetadata[i]![fieldName] = values[i];
      }
    }
    print('✓ Built column metadata for ${colMetadata.length} columns');

    // 3. Build row metadata map: ri index -> variable name
    final rowMetadata = <int, String>{};
    for (final col in rowData.columns) {
      final values = col.values as List?;
      if (values == null) continue;
      for (int i = 0; i < values.length; i++) {
        final varName = values[i]?.toString() ?? '';
        // Strip namespace prefix (e.g., "ds1.gridX" -> "gridX")
        rowMetadata[i] = varName.contains('.')
            ? varName.split('.').last
            : varName;
      }
    }
    print('✓ Built row metadata: $rowMetadata');

    // 4. Parse qtData columns
    List ciValues = [], riValues = [];
    List<double> yValues = [];
    for (final col in qtData.columns) {
      switch (col.name) {
        case '.ci':
          ciValues = col.values as List;
        case '.ri':
          riValues = col.values as List;
        case '.y':
          yValues = (col.values as List).map((v) => (v as num).toDouble()).toList();
      }
    }
    print('✓ Parsed ${ciValues.length} qtData rows');

    // 5. Build data map: ci -> {ri -> y}
    final dataMap = <int, Map<int, double>>{};
    for (int i = 0; i < ciValues.length; i++) {
      final ci = (ciValues[i] as num).toInt();
      final ri = (riValues[i] as num).toInt();
      final y = yValues[i];
      dataMap.putIfAbsent(ci, () => {});
      dataMap[ci]![ri] = y;
    }
    print('✓ Built data map with ${dataMap.length} column entries');

    // 6. Collect unique Image values and resolve the target image name
    final allImages = <String>{};
    for (final meta in colMetadata.values) {
      final img = meta['Image']?.toString();
      if (img != null) allImages.add(img);
    }
    print('📋 Total unique Image values in data: ${allImages.length}');
    print('📋 Looking for gridImageId: "$gridImageId"');

    // Resolve gridImageId to matching Image in the data.
    // Image names: {barcode}_{well}_{field}_{time}_{peptide}_{index}_{array}
    // The data may only contain P94 (control peptide) images.
    // For non-P94 images, match by barcode+well+field+time prefix.
    String? resolvedImageName;
    if (allImages.contains(gridImageId)) {
      resolvedImageName = gridImageId;
    } else {
      // Extract prefix: barcode_well_field_time (first 4 underscore-separated parts)
      final parts = gridImageId.split('_');
      if (parts.length >= 4) {
        final prefix = parts.sublist(0, 4).join('_'); // e.g. "641031403_W1_F1_T100"
        for (final img in allImages) {
          if (img.startsWith(prefix)) {
            resolvedImageName = img;
            break;
          }
        }
      }
    }
    print('📋 Resolved to data Image: ${resolvedImageName ?? "NOT FOUND"}');

    // Filter for the resolved image name and build fiducials
    final fiducials = <FiducialPosition>[];

    if (resolvedImageName == null) {
      print('⚠ No matching image found in Tercen data for $gridImageId');
    } else {
      for (final entry in dataMap.entries) {
        final ci = entry.key;
        final riYMap = entry.value;

        final colMeta = colMetadata[ci];
        if (colMeta == null) continue;

        final imageName = colMeta['Image']?.toString() ?? '';
        if (imageName != resolvedImageName) continue;

        final spotRow = (colMeta['spotRow'] as num?)?.toDouble() ?? 0.0;
        final spotCol = (colMeta['spotCol'] as num?)?.toDouble() ?? 0.0;
        final id = colMeta['ID'] as String? ?? '';
        final grdImageNameUsed = colMeta['grdImageNameUsed']?.toString() ?? '';

        double? gridX;
        double? gridY;
        double? diameter;
        int? manual;
        int? bad;
        int? empty;

        for (final riEntry in riYMap.entries) {
          final ri = riEntry.key;
          final y = riEntry.value;
          final varName = rowMetadata[ri];

          if (varName == null || varName.isEmpty) continue;

          switch (varName) {
            case 'gridX':
              gridX = y;
            case 'gridY':
              gridY = y;
            case 'diameter':
              diameter = y;
            case 'manual':
              manual = y.toInt();
            case 'bad':
              bad = y.toInt();
            case 'empty':
              empty = y.toInt();
          }
        }

        if (gridX != null && gridY != null) {
          // Coordinate swap: Shiny uses display_x = gridY, display_y = gridX
          // (the TIFF image is transposed for display)
          fiducials.add(FiducialPosition(
            id: '$ci',
            ci: ci,
            imageName: imageName,
            grdImageNameUsed: grdImageNameUsed,
            row: spotRow.toInt(),
            col: spotCol.toInt(),
            baseX: gridY,
            baseY: gridX,
            diameter: diameter ?? 0.0,
            isReference: id == '#REF',
            isManual: manual == 1,
            isBad: bad == 1,
            isEmpty: empty == 1,
          ));
        }
      }
    }

    print('✓ Created ${fiducials.length} fiducials for grid $gridImageId');

    final config = GridConfiguration.evolve3(
      imageWidth: 552,
      imageHeight: 413,
    );

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
    _gridDataCache[gridImageId] = gridData;
    _statusCache[gridImageId] = GridStatus.modified;
  }

  @override
  Future<GridData> loadDefaultGrid() async {
    return _mockService.loadDefaultGrid();
  }

  @override
  Future<GridData> runGridProcessing(String gridImageId) async {
    await Future.delayed(const Duration(seconds: 5));
    _statusCache[gridImageId] = GridStatus.processed;
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
    final ctx = await _getContext();

    print('📤 saveAllGrids: Loading all Tercen data for output...');
    await ctx.progress('Loading data...', actual: 0, total: 3);

    // 1. Ensure all grid images are loaded (lazy load any unvisited ones)
    for (final gridImageId in allGridImageIds) {
      if (!_gridDataCache.containsKey(gridImageId)) {
        print('  Loading unvisited grid: $gridImageId');
        await loadGridData(gridImageId);
      }
    }

    // 2. Load ALL original data from Tercen (unfiltered - all spots across all images)
    final qtData = await ctx.select(names: ['.ci', '.ri', '.y']);
    final colData = await ctx.cselect();
    final rowData = await ctx.rselect();

    await ctx.progress('Building output...', actual: 1, total: 3);

    // 3. Build metadata maps (same as _loadFromTercen but for ALL data)
    final colMetadata = <int, Map<String, dynamic>>{};
    for (final col in colData.columns) {
      final values = col.values as List?;
      if (values == null) continue;
      final fieldName = col.name.contains('.')
          ? col.name.split('.').last
          : col.name;
      for (int i = 0; i < values.length; i++) {
        colMetadata.putIfAbsent(i, () => {});
        colMetadata[i]![fieldName] = values[i];
      }
    }

    final rowMetadata = <int, String>{};
    for (final col in rowData.columns) {
      final values = col.values as List?;
      if (values == null) continue;
      for (int i = 0; i < values.length; i++) {
        final varName = values[i]?.toString() ?? '';
        rowMetadata[i] = varName.contains('.')
            ? varName.split('.').last
            : varName;
      }
    }

    // Parse qtData into dataMap: ci -> {ri -> y}
    List ciValues = [], riValues = [];
    List<double> yValues = [];
    for (final col in qtData.columns) {
      switch (col.name) {
        case '.ci':
          ciValues = col.values as List;
        case '.ri':
          riValues = col.values as List;
        case '.y':
          yValues = (col.values as List).map((v) => (v as num).toDouble()).toList();
      }
    }

    final dataMap = <int, Map<int, double>>{};
    for (int i = 0; i < ciValues.length; i++) {
      final ci = (ciValues[i] as num).toInt();
      final ri = (riValues[i] as num).toInt();
      dataMap.putIfAbsent(ci, () => {});
      dataMap[ci]![ri] = yValues[i];
    }

    // 4. Build position lookup for modified grids:
    //    grdImageNameUsed -> { "row_col" -> modified fiducial data }
    // This allows applying grid changes to ALL images sharing the same grid.
    final modifiedGridLookup = <String, Map<String, _ModifiedSpot>>{};
    for (final entry in _gridDataCache.entries) {
      final gridImageId = entry.key;
      final gridData = entry.value;

      // Only include grids that were actually modified
      if (_statusCache[gridImageId] != GridStatus.modified) continue;

      final spotLookup = <String, _ModifiedSpot>{};
      for (final f in gridData.fiducials) {
        // Compute final display position
        final displayX = f.baseX + gridData.globalOffsetX + f.individualOffsetX;
        final displayY = f.baseY + gridData.globalOffsetY + f.individualOffsetY;

        // Coordinate swap back: display X → Tercen gridY, display Y → Tercen gridX
        spotLookup['${f.row}_${f.col}'] = _ModifiedSpot(
          tercenGridX: displayY,
          tercenGridY: displayX,
          diameter: f.diameter,
          isManual: f.isManual,
          isBad: f.isBad,
          isEmpty: f.isEmpty,
          rotation: gridData.rotation,
        );
      }

      modifiedGridLookup[gridImageId] = spotLookup;
    }

    print('  Modified grids: ${modifiedGridLookup.keys.toList()}');

    // 5. Find ri indices for each variable name
    final riForVar = <String, int>{};
    for (final entry in rowMetadata.entries) {
      riForVar[entry.value] = entry.key;
    }

    // 6. Build output arrays — one row per spot (unique .ci)
    // The Shiny uses .ci from gridY rows; we use all unique .ci values.
    final allCis = dataMap.keys.toList()..sort();

    final outCi = <int>[];
    final outGridX = <double>[];
    final outGridY = <double>[];
    final outFixedX = <double>[];
    final outFixedY = <double>[];
    final outDiameter = <double>[];
    final outManual = <double>[];
    final outBad = <double>[];
    final outEmpty = <double>[];
    final outRotation = <double>[];
    final outGrdImageNameUsed = <String>[];
    final outImage = <String>[];

    for (final ci in allCis) {
      final colMeta = colMetadata[ci];
      if (colMeta == null) continue;

      final riYMap = dataMap[ci]!;
      final spotRow = (colMeta['spotRow'] as num?)?.toInt() ?? 0;
      final spotCol = (colMeta['spotCol'] as num?)?.toInt() ?? 0;
      final imageName = colMeta['Image']?.toString() ?? '';
      final grdImageName = colMeta['grdImageNameUsed']?.toString() ?? '';

      // Check if this spot's grid was modified
      final modifiedSpots = modifiedGridLookup[grdImageName];
      final modifiedSpot = modifiedSpots?['${spotRow}_$spotCol'];

      if (modifiedSpot != null) {
        // Use modified positions (propagated from the grid image to all images)
        outCi.add(ci);
        outGridX.add(modifiedSpot.tercenGridX);
        outGridY.add(modifiedSpot.tercenGridY);
        outFixedX.add(modifiedSpot.tercenGridX); // manual: fixed = current
        outFixedY.add(modifiedSpot.tercenGridY);
        outDiameter.add(modifiedSpot.diameter);
        outManual.add(modifiedSpot.isManual ? 1.0 : 0.0);
        outBad.add(modifiedSpot.isBad ? 1.0 : 0.0);
        outEmpty.add(modifiedSpot.isEmpty ? 1.0 : 0.0);
        outRotation.add(modifiedSpot.rotation);
        outGrdImageNameUsed.add(grdImageName);
        outImage.add(imageName);
      } else {
        // Use original values from Tercen data
        outCi.add(ci);
        outGridX.add(riYMap[riForVar['gridX']] ?? 0.0);
        outGridY.add(riYMap[riForVar['gridY']] ?? 0.0);
        outFixedX.add(riYMap[riForVar['grdXFixedPosition']] ?? 0.0);
        outFixedY.add(riYMap[riForVar['grdYFixedPosition']] ?? 0.0);
        outDiameter.add(riYMap[riForVar['diameter']] ?? 0.0);
        outManual.add(riYMap[riForVar['manual']] ?? 0.0);
        outBad.add(riYMap[riForVar['bad']] ?? 0.0);
        outEmpty.add(riYMap[riForVar['empty']] ?? 0.0);
        outRotation.add(riYMap[riForVar['grdRotation']] ?? 0.0);
        outGrdImageNameUsed.add(grdImageName);
        outImage.add(imageName);
      }
    }

    print('  Output: ${outCi.length} rows');

    // 7. Add namespace prefixes to column names
    final nameMap = await ctx.addNamespace([
      'gridX', 'gridY', 'grdXFixedPosition', 'grdYFixedPosition',
      'diameter', 'manual', 'bad', 'empty', 'grdRotation',
      'grdImageNameUsed', 'Image',
    ]);

    // 8. Build the output Table with TypedData on column.values
    //    TSON encoder requires dart:typed_data (Int32List, Float64List) and
    //    CStringList for correct binary serialization (LIST_INT32_TYPE,
    //    LIST_FLOAT64_TYPE, LIST_STRING_TYPE). Regular Dart lists serialize
    //    as generic LIST_TYPE which the server rejects.
    final nRows = outCi.length;
    final table = Table();
    table.nRows = nRows;

    // .ci column (system column — no namespace prefix)
    final ciCol = Column();
    ciCol.name = '.ci';
    ciCol.type = 'int32';
    ciCol.nRows = nRows;
    ciCol.values = Int32List.fromList(outCi);
    final ciVals = I32Values();
    ciVals.values.addAll(outCi);
    ciCol.cValues = ciVals;
    table.columns.add(ciCol);

    // Double columns: column.values = Float64List for correct TSON encoding
    void addDoubleCol(String name, List<double> values) {
      final col = Column();
      col.name = nameMap[name]!;
      col.type = 'double';
      col.nRows = nRows;
      col.values = Float64List.fromList(values);
      final f64 = F64Values();
      f64.values.addAll(values);
      col.cValues = f64;
      table.columns.add(col);
    }

    addDoubleCol('gridX', outGridX);
    addDoubleCol('gridY', outGridY);
    addDoubleCol('grdXFixedPosition', outFixedX);
    addDoubleCol('grdYFixedPosition', outFixedY);
    addDoubleCol('diameter', outDiameter);
    addDoubleCol('manual', outManual);
    addDoubleCol('bad', outBad);
    addDoubleCol('empty', outEmpty);
    addDoubleCol('grdRotation', outRotation);

    // String columns: column.values = CStringList for correct TSON encoding
    void addStringCol(String name, List<String> values) {
      final col = Column();
      col.name = nameMap[name]!;
      col.type = 'string';
      col.nRows = nRows;
      col.values = CStringList.fromList(values);
      final str = StrValues();
      str.values.addAll(values);
      col.cValues = str;
      table.columns.add(col);
    }

    addStringCol('grdImageNameUsed', outGrdImageNameUsed);
    addStringCol('Image', outImage);

    print('  Table built: ${table.nRows} rows, ${table.columns.length} columns');
    for (final col in table.columns) {
      print('    ${col.name} (${col.cValues.runtimeType})');
    }

    // 9. Save to Tercen
    await ctx.progress('Saving to Tercen...', actual: 2, total: 3);
    print('📤 Saving table to Tercen...');

    await ctx.saveTable(table);

    await ctx.progress('Done', actual: 3, total: 3);
    print('✓ Save complete!');
  }
}

/// Helper class for modified spot data in Tercen coordinate space.
class _ModifiedSpot {
  final double tercenGridX;
  final double tercenGridY;
  final double diameter;
  final bool isManual;
  final bool isBad;
  final bool isEmpty;
  final double rotation;

  _ModifiedSpot({
    required this.tercenGridX,
    required this.tercenGridY,
    required this.diameter,
    required this.isManual,
    required this.isBad,
    required this.isEmpty,
    required this.rotation,
  });
}
