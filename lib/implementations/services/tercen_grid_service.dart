import 'package:pamsoft_grid_flutter_operator/models/grid_data.dart';
import 'package:pamsoft_grid_flutter_operator/models/grid_configuration.dart';
import 'package:pamsoft_grid_flutter_operator/models/fiducial_position.dart';
import 'package:pamsoft_grid_flutter_operator/models/enums.dart';
import 'package:pamsoft_grid_flutter_operator/services/grid_service.dart';
import 'package:pamsoft_grid_flutter_operator/utils/tercen_url_parser.dart';
import 'package:sci_tercen_context/sci_tercen_context.dart';

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

    // 6. Filter for the target gridImageId and build fiducials
    final fiducials = <FiducialPosition>[];

    for (final entry in dataMap.entries) {
      final ci = entry.key;
      final riYMap = entry.value;

      final colMeta = colMetadata[ci];
      if (colMeta == null) continue;

      // Check if this is our target grid image
      final imageName = colMeta['Image'] as String?;
      if (imageName != gridImageId) continue;

      final spotRow = (colMeta['spotRow'] as num?)?.toDouble() ?? 0.0;
      final spotCol = (colMeta['spotCol'] as num?)?.toDouble() ?? 0.0;
      final id = colMeta['ID'] as String? ?? '';

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
        fiducials.add(FiducialPosition(
          id: '$ci',
          row: spotRow.toInt(),
          col: spotCol.toInt(),
          baseX: gridX,
          baseY: gridY,
          diameter: diameter ?? 0.0,
          isReference: id == '#REF',
          isManual: manual == 1,
          isBad: bad == 1,
          isEmpty: empty == 1,
        ));
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
}
