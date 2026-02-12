import 'package:pamsoft_grid_flutter_operator/models/grid_data.dart';
import 'package:pamsoft_grid_flutter_operator/models/grid_configuration.dart';
import 'package:pamsoft_grid_flutter_operator/models/fiducial_position.dart';
import 'package:pamsoft_grid_flutter_operator/models/enums.dart';
import 'package:pamsoft_grid_flutter_operator/services/grid_service.dart';
import 'package:pamsoft_grid_flutter_operator/utils/tercen_url_parser.dart';
import 'package:sci_tercen_client/sci_client_service_factory.dart';
import 'package:sci_tercen_client/sci_client.dart' hide ServiceFactory;

/// Tercen implementation of GridService.
///
/// Loads grid data from Tercen table (ctx.select) instead of calculating positions.
class TercenGridService implements GridService {
  final ServiceFactory _factory;
  final TercenUrlParser _urlParser;
  final GridService _mockService;

  final Map<String, GridData> _gridDataCache = {};
  final Map<String, GridStatus> _statusCache = {};

  TercenGridService(this._factory, this._urlParser, this._mockService);

  @override
  Future<GridData> loadGridData(String gridImageId) async {
    if (_gridDataCache.containsKey(gridImageId)) {
      return _gridDataCache[gridImageId]!;
    }

    try {
      print('🔍 Loading grid data from Tercen for $gridImageId');

      // Load table data from Tercen
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
    // Get services
    final taskService = _factory.taskService;

    // Get current task from URL
    if (_urlParser.taskId == null) {
      throw Exception('No taskId found in URL');
    }

    print('📋 Fetching task: ${_urlParser.taskId}');
    final task = await taskService.get(_urlParser.taskId!);
    print('✓ Got task type: ${task.runtimeType}');

    // Handle both RunWebAppTask and direct CubeQueryTask
    CubeQueryTask cubeTask;

    if (task is CubeQueryTask) {
      // Direct CubeQueryTask (common in Data Steps)
      print('✓ Task is directly a CubeQueryTask');
      cubeTask = task as CubeQueryTask;
    } else if (task is RunWebAppTask) {
      // RunWebAppTask wrapping a CubeQueryTask
      print('✓ Task is RunWebAppTask, fetching wrapped CubeQueryTask');
      final webAppTask = task as RunWebAppTask;
      if (webAppTask.cubeQueryTaskId.isEmpty) {
        throw Exception('No cubeQueryTaskId in RunWebAppTask');
      }

      print('📋 Fetching cube query task: ${webAppTask.cubeQueryTaskId}');
      final wrappedTask = await taskService.get(webAppTask.cubeQueryTaskId);
      print('✓ Got cube task type: ${wrappedTask.runtimeType}');

      if (wrappedTask is! CubeQueryTask) {
        throw Exception('Wrapped task is not CubeQueryTask, got ${wrappedTask.runtimeType}');
      }

      cubeTask = wrappedTask as CubeQueryTask;
    } else {
      throw Exception('Task is neither RunWebAppTask nor CubeQueryTask, it is ${task.runtimeType}');
    }

    // Use tableSchemaService.select() with query hashes (equivalent of R's ctx$select)
    final query = cubeTask.query;
    print('📋 Query hashes — qtHash: ${query.qtHash}, columnHash: ${query.columnHash}, rowHash: ${query.rowHash}');

    // 1. Get row counts from schemas
    final qtSchema = await _factory.tableSchemaService.get(query.qtHash);
    final nRows = qtSchema.nRows;
    print('✓ qtSchema: $nRows rows, ${qtSchema.columns.length} columns');

    final colSchema = await _factory.tableSchemaService.get(query.columnHash);
    final nCols = colSchema.nRows;
    print('✓ colSchema: $nCols rows, ${colSchema.columns.length} columns');

    final rowSchema = await _factory.tableSchemaService.get(query.rowHash);
    final nRowFactors = rowSchema.nRows;
    print('✓ rowSchema: $nRowFactors rows, ${rowSchema.columns.length} columns');

    // 2. Fetch main data table (equivalent of ctx$select(c('.ci', '.ri', '.y')))
    print('📋 Fetching main data table (.ci, .ri, .y) — $nRows rows');
    final qtData = await _factory.tableSchemaService.select(
      query.qtHash, ['.ci', '.ri', '.y'], 0, nRows,
    );

    // 3. Fetch column metadata (equivalent of ctx$cselect)
    // Discover available column names from schema (non-dot-prefixed)
    final colFactorNames = colSchema.columns
        .map((c) => c.name)
        .where((name) => !name.startsWith('.'))
        .toList();
    print('📋 Fetching column metadata: $colFactorNames — $nCols rows');

    final colData = await _factory.tableSchemaService.select(
      query.columnHash, colFactorNames, 0, nCols,
    );

    // 4. Fetch row metadata (equivalent of ctx$rselect)
    final rowFactorNames = rowSchema.columns
        .map((c) => c.name)
        .where((name) => !name.startsWith('.'))
        .toList();
    print('📋 Fetching row metadata: $rowFactorNames — $nRowFactors rows');

    final rowData = await _factory.tableSchemaService.select(
      query.rowHash, rowFactorNames, 0, nRowFactors,
    );

    // 5. Build column metadata map: ci index -> {Image, spotRow, spotCol, ID, ...}
    final colMetadata = <int, Map<String, dynamic>>{};
    for (final col in colData.columns) {
      final values = col.values as List?;
      if (values != null) {
        for (int i = 0; i < values.length; i++) {
          colMetadata.putIfAbsent(i, () => {});
          // Strip namespace prefix if present (e.g., "ds1.Image" -> "Image")
          final fieldName = col.name.contains('.')
              ? col.name.split('.').last
              : col.name;
          colMetadata[i]![fieldName] = values[i];
        }
      }
    }
    print('✓ Built column metadata for ${colMetadata.length} columns');

    // 6. Build row metadata map: ri index -> variable name
    final rowMetadata = <int, String>{};
    for (final col in rowData.columns) {
      final values = col.values as List?;
      if (values != null) {
        for (int i = 0; i < values.length; i++) {
          final varName = values[i]?.toString() ?? '';
          // Strip namespace prefix
          rowMetadata[i] = varName.contains('.')
              ? varName.split('.').last
              : varName;
        }
      }
    }
    print('✓ Built row metadata: $rowMetadata');

    // 7. Parse qtData columns
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

    // 8. Build data map: ci -> {ri -> y}
    final dataMap = <int, Map<int, double>>{};
    for (int i = 0; i < ciValues.length; i++) {
      final ci = (ciValues[i] as num).toInt();
      final ri = (riValues[i] as num).toInt();
      final y = yValues[i];
      dataMap.putIfAbsent(ci, () => {});
      dataMap[ci]![ri] = y;
    }
    print('✓ Built data map with ${dataMap.length} column entries');

    // 9. Filter for the target gridImageId and build fiducials
    final fiducials = <FiducialPosition>[];

    for (final entry in dataMap.entries) {
      final ci = entry.key;
      final riYMap = entry.value;

      // Get column metadata for this .ci
      final colMeta = colMetadata[ci];
      if (colMeta == null) continue;

      // Check if this is our target grid image
      final imageName = colMeta['Image'] as String?;
      if (imageName != gridImageId) continue;

      // Extract position data from column metadata
      final spotRow = (colMeta['spotRow'] as num?)?.toDouble() ?? 0.0;
      final spotCol = (colMeta['spotCol'] as num?)?.toDouble() ?? 0.0;
      final id = colMeta['ID'] as String? ?? '';

      // Get variable values for this column
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

      // Only create fiducial if we have position data
      if (gridX != null && gridY != null) {
        final isReference = id == '#REF';

        fiducials.add(FiducialPosition(
          id: '$ci',
          row: spotRow.toInt(),
          col: spotCol.toInt(),
          baseX: gridX,
          baseY: gridY,
          diameter: diameter ?? 0.0,
          isReference: isReference,
          isManual: manual == 1,
          isBad: bad == 1,
          isEmpty: empty == 1,
        ));
      }
    }

    print('✓ Created ${fiducials.length} fiducials for grid $gridImageId');

    // Create a default configuration
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
    // For "New Grid" button, use the mock service's calculation
    return _mockService.loadDefaultGrid();
  }

  @override
  Future<GridData> runGridProcessing(String gridImageId) async {
    // Simulate processing delay
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
