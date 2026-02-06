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

    print('🔍 Loading grid data from Tercen for $gridImageId');

    // Load table data from Tercen
    final gridData = await _loadFromTercen(gridImageId);

    _gridDataCache[gridImageId] = gridData;
    _statusCache[gridImageId] = GridStatus.processed;

    print('✓ Loaded ${gridData.fiducials.length} fiducials from Tercen');
    return gridData;
  }

  Future<GridData> _loadFromTercen(String gridImageId) async {
    // Get services
    final taskService = _factory.taskService;

    // Get current task from URL
    if (_urlParser.taskId == null) {
      throw Exception('No taskId found in URL');
    }

    final task = await taskService.get(_urlParser.taskId!);

    // Cast to RunWebAppTask to get cubeQueryTaskId
    if (task is! RunWebAppTask) {
      throw Exception('Task is not RunWebAppTask: ${task.runtimeType}');
    }

    final webAppTask = task as RunWebAppTask;
    if (webAppTask.cubeQueryTaskId.isEmpty) {
      throw Exception('No cubeQueryTaskId in RunWebAppTask');
    }

    // Get the cube query task
    final cubeTask = await taskService.get(webAppTask.cubeQueryTaskId);
    if (cubeTask is! CubeQueryTask) {
      throw Exception('CubeQueryTask not found');
    }

    // Use Direct JSON extraction to get all data including column/row metadata
    print('📋 Extracting data from task JSON');

    final taskJson = cubeTask.toJson();
    final queryJson = taskJson['query'] as Map?;

    if (queryJson == null || queryJson['relation'] == null) {
      throw Exception('Task has no query relation');
    }

    var currentRelation = queryJson['relation'] as Map?;

    // Navigate through relation structure to find InMemoryTable
    while (currentRelation != null) {
      if (currentRelation['kind'] == 'InMemoryRelation' &&
          currentRelation['inMemoryTable'] != null) {

        final inMemoryTable = currentRelation['inMemoryTable'] as Map;
        final result = await _parseGridDataFromJson(inMemoryTable, gridImageId);
        return result;
      }

      // Navigate deeper into relation tree
      currentRelation = currentRelation['relation'] as Map?;
    }

    throw Exception('No InMemoryTable found in task JSON');
  }

  Future<GridData> _parseGridDataFromJson(
    Map inMemoryTable,
    String gridImageId,
  ) async {
    final columns = inMemoryTable['columns'] as List?;
    if (columns == null) {
      throw Exception('No columns in InMemoryTable');
    }

    print('📊 Parsing ${columns.length} columns from InMemoryTable');

    // Build column index map
    final colIndexMap = <String, int>{};
    for (int i = 0; i < columns.length; i++) {
      final col = columns[i] as Map;
      final name = col['name'] as String?;
      if (name != null) {
        colIndexMap[name] = i;
      }
    }

    print('📋 Available columns: ${colIndexMap.keys.join(", ")}');

    // Required indices
    final ciIdx = colIndexMap['.ci'];
    final riIdx = colIndexMap['.ri'];
    final yIdx = colIndexMap['.y'];

    if (ciIdx == null || riIdx == null || yIdx == null) {
      throw Exception('Required columns not found: .ci, .ri, .y');
    }

    // Extract column arrays
    final ciCol = columns[ciIdx] as Map;
    final riCol = columns[riIdx] as Map;
    final yCol = columns[yIdx] as Map;

    final ciValues = ciCol['values'] as List?;
    final riValues = riCol['values'] as List?;
    final yValues = yCol['values'] as List?;

    if (ciValues == null || riValues == null || yValues == null) {
      throw Exception('Missing values in required columns');
    }

    final nRows = ciValues.length;
    print('✓ Processing $nRows rows');

    // Extract column metadata (Image, spotRow, spotCol, ID, etc.)
    final columnMetadata = <int, Map<String, dynamic>>{};

    for (final entry in colIndexMap.entries) {
      final colName = entry.key;
      final colIdx = entry.value;

      // Look for column metadata columns (should be constant per .ci)
      if (!colName.startsWith('.') &&
          (colName.endsWith('Image') ||
           colName.endsWith('spotRow') ||
           colName.endsWith('spotCol') ||
           colName.endsWith('ID') ||
           colName.contains('documentId') ||
           colName.endsWith('grdImageNameUsed'))) {

        final col = columns[colIdx] as Map;
        final values = col['values'] as List?;

        if (values != null) {
          // Build metadata map: group by .ci
          for (int rowIdx = 0; rowIdx < nRows; rowIdx++) {
            final ci = (ciValues[rowIdx] as num).toInt();

            if (!columnMetadata.containsKey(ci)) {
              columnMetadata[ci] = {};
            }

            // Extract field name (remove namespace prefix)
            final fieldName = colName.contains('.')
                ? colName.split('.').last
                : colName;

            columnMetadata[ci]![fieldName] = values[rowIdx];
          }
        }
      }
    }

    print('✓ Extracted metadata for ${columnMetadata.length} columns');

    // Extract row metadata (variable names)
    final rowMetadata = <int, String>{};

    for (final entry in colIndexMap.entries) {
      final colName = entry.key;
      final colIdx = entry.value;

      if (colName.endsWith('variable') || colName.endsWith('.variable')) {
        final col = columns[colIdx] as Map;
        final values = col['values'] as List?;

        if (values != null) {
          for (int rowIdx = 0; rowIdx < nRows; rowIdx++) {
            final ri = (riValues[rowIdx] as num).toInt();
            rowMetadata[ri] = values[rowIdx]?.toString() ?? '';
          }
        }
        break;
      }
    }

    print('✓ Extracted ${rowMetadata.length} row metadata entries');

    // Build map of .ci -> {.ri -> .y}
    final dataMap = <int, Map<int, double>>{};

    for (int rowIdx = 0; rowIdx < nRows; rowIdx++) {
      final ci = (ciValues[rowIdx] as num).toInt();
      final ri = (riValues[rowIdx] as num).toInt();
      final y = (yValues[rowIdx] as num).toDouble();

      if (!dataMap.containsKey(ci)) {
        dataMap[ci] = {};
      }
      dataMap[ci]![ri] = y;
    }

    print('✓ Built data map with ${dataMap.length} column entries');

    // Filter for the target gridImageId and build fiducials
    final fiducials = <FiducialPosition>[];

    for (final entry in dataMap.entries) {
      final ci = entry.key;
      final riValues = entry.value;

      // Get column metadata for this .ci
      final colMeta = columnMetadata[ci];
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

      for (final riEntry in riValues.entries) {
        final ri = riEntry.key;
        final y = riEntry.value;
        final varName = rowMetadata[ri];

        if (varName == null || varName.isEmpty) continue;

        // Match variable names (strip namespace prefix like "ds1.")
        final cleanVarName = varName.contains('.')
            ? varName.split('.').last
            : varName;

        switch (cleanVarName) {
          case 'gridX':
            gridX = y;
            break;
          case 'gridY':
            gridY = y;
            break;
          case 'diameter':
            diameter = y;
            break;
          case 'manual':
            manual = y.toInt();
            break;
          case 'bad':
            bad = y.toInt();
            break;
          case 'empty':
            empty = y.toInt();
            break;
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
