import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:pamsoft_grid_flutter_operator/models/grid_data.dart';
import 'package:pamsoft_grid_flutter_operator/models/grid_configuration.dart';
import 'package:pamsoft_grid_flutter_operator/models/fiducial_position.dart';
import 'package:pamsoft_grid_flutter_operator/models/enums.dart';
import 'package:pamsoft_grid_flutter_operator/services/grid_service.dart';
import 'package:pamsoft_grid_flutter_operator/utils/block_slice.dart';
import 'package:pamsoft_grid_flutter_operator/utils/tercen_url_parser.dart';
import 'package:sci_tercen_context/sci_tercen_context.dart';
import 'package:tson/string_list.dart';

/// Resolves an image name to its run of crosstab column indices, or null when
/// that is not known (mock mode, or an image with non-contiguous columns).
typedef CiRangeResolver = Future<CiRange?> Function(String imageName);

/// Tercen implementation of GridService.
///
/// Grid data lives in the step's crosstab: one column per spot per image,
/// one row per variable (gridX, gridY, diameter, ...). Two ways in:
///
/// * **Slice** — the current grid image's cells only, read as one contiguous
///   block of the physically Morton-ordered table (see [MortonLayout]). Under
///   a megabyte, so the first grid overlay is on screen in about a second
///   whatever the dataset size. Verified cell by cell before it is trusted.
/// * **Full load** — every cell, chunked and fetched two requests at a time
///   into flat typed arrays, with progress on [loadProgress]. Needed to save
///   (the output is one row per spot for every image) and as the fallback
///   when a slice cannot be taken. Started in the background as soon as the
///   first grid is requested.
class TercenGridService implements GridService {
  final ServiceFactoryBase _factory;
  final TercenUrlParser _urlParser;
  final GridService _mockService;
  final CiRangeResolver? _ciRangeFor;

  final Map<String, GridData> _gridDataCache = {};
  final Map<String, GridStatus> _statusCache = {};

  /// Cached OperatorContext — created once and reused.
  AbstractOperatorContext? _ctx;

  /// The whole crosstab, once loaded. [_fullLoad] is the in-flight load so a
  /// second caller awaits the same future instead of starting another.
  _FullData? _fullData;
  Future<_FullData>? _fullLoad;

  /// Row variables (rselect), shared by slices and the full load.
  Future<_RowVars>? _rowVars;

  final ValueNotifier<LoadProgress?> _loadProgress = ValueNotifier(null);
  final ValueNotifier<LoadProgress?> _saveProgress = ValueNotifier(null);

  /// Rows per request for the full load. Small enough that the progress bar
  /// moves every second or so on a large run; the per-request overhead is
  /// negligible next to the transfer.
  static const int selectChunkRows = 250000;

  /// Requests kept in flight during the full load.
  static const int parallelSelects = 2;

  TercenGridService(this._factory, this._urlParser, this._mockService,
      {CiRangeResolver? ciRangeFor})
      : _ciRangeFor = ciRangeFor;

  @override
  ValueListenable<LoadProgress?> get loadProgress => _loadProgress;

  @override
  ValueListenable<LoadProgress?> get saveProgress => _saveProgress;

  @override
  int get modifiedCount =>
      _statusCache.values.where((s) => s == GridStatus.modified).length;

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

  // ---------------------------------------------------------------------------
  // Row variables
  // ---------------------------------------------------------------------------

  Future<_RowVars> _getRowVars() => _rowVars ??= _loadRowVars();

  Future<_RowVars> _loadRowVars() async {
    final ctx = await _getContext();
    final rowData = await ctx.rselect();
    final names = <int, String>{};
    for (final col in rowData.columns) {
      final values = col.values as List?;
      if (values == null) continue;
      for (int i = 0; i < values.length; i++) {
        final varName = values[i]?.toString() ?? '';
        names[i] = varName.contains('.') ? varName.split('.').last : varName;
      }
    }
    print('✓ Row variables: $names');
    return _RowVars(rowData.nRows, names);
  }

  // ---------------------------------------------------------------------------
  // Column metadata
  // ---------------------------------------------------------------------------

  /// Column factor names as they appear in the column table (namespaced).
  Future<_ColNames> _colNames(AbstractOperatorContext ctx) async {
    final cnames = await ctx.cnames;
    String pick(String suffix) => cnames.firstWhere(
        (n) => n == suffix || n.endsWith('.$suffix'),
        orElse: () => '');
    return _ColNames(
      image: pick('Image'),
      grdImage: pick('grdImageNameUsed'),
      spotRow: pick('spotRow'),
      spotCol: pick('spotCol'),
      id: pick('ID'),
    );
  }

  /// Reads the column factors for columns `[offset, offset + limit)` into flat
  /// arrays indexed from 0.
  Future<_ColMeta> _loadColumns(AbstractOperatorContext ctx, _ColNames names,
      {int offset = 0, int limit = -1}) async {
    final wanted = [names.image, names.grdImage, names.spotRow, names.spotCol, names.id]
        .where((n) => n.isNotEmpty)
        .toList();
    final tbl = await ctx.cselect(names: wanted, offset: offset, limit: limit);
    final n = tbl.nRows;
    final meta = _ColMeta(n);
    for (final col in tbl.columns) {
      final values = col.values as List?;
      if (values == null) continue;
      if (col.name == names.image) {
        for (var i = 0; i < n; i++) meta.image[i] = values[i]?.toString() ?? '';
      } else if (col.name == names.grdImage) {
        for (var i = 0; i < n; i++) meta.grdImage[i] = values[i]?.toString() ?? '';
      } else if (col.name == names.id) {
        for (var i = 0; i < n; i++) meta.id[i] = values[i]?.toString() ?? '';
      } else if (col.name == names.spotRow) {
        for (var i = 0; i < n; i++) meta.spotRow[i] = (values[i] as num?)?.toInt() ?? 0;
      } else if (col.name == names.spotCol) {
        for (var i = 0; i < n; i++) meta.spotCol[i] = (values[i] as num?)?.toInt() ?? 0;
      }
    }
    return meta;
  }

  // ---------------------------------------------------------------------------
  // Slice: one image's cells
  // ---------------------------------------------------------------------------

  /// Reads just the columns of [image] and their cells. Returns null when the
  /// layout does not allow it or the block read does not check out, in which
  /// case the caller waits for the full load.
  Future<_Slice?> _loadSlice(String image) async {
    final resolver = _ciRangeFor;
    if (resolver == null) return null;
    final range = await resolver(image);
    if (range == null || range.count == 0) return null;

    final ctx = await _getContext();
    final rows = await _getRowVars();
    final qt = await ctx.schema;
    final cs = await ctx.cschema;
    final nCols = cs.nRows;
    if (!MortonLayout.canSlice(nRi: rows.n, nCols: nCols, qtRows: qt.nRows)) {
      print('ℹ️ Crosstab not sliceable (nRi=${rows.n}, nCols=$nCols, qtRows=${qt.nRows}); full load only');
      return null;
    }
    if (range.end > nCols) return null;

    final blockRows = MortonLayout.blockRows(range, nRi: rows.n, nCols: nCols);
    final names = await _colNames(ctx);
    final sw = Stopwatch()..start();
    final results = await Future.wait([
      ctx.select(names: const ['.ci', '.ri', '.y'], offset: blockRows.offset, limit: blockRows.limit),
      _loadColumns(ctx, names, offset: range.start, limit: range.count),
    ]);
    final cells = results[0] as Table;
    final meta = results[1] as _ColMeta;

    final ci = _intColumn(cells, '.ci');
    final ri = _intColumn(cells, '.ri');
    final y = _doubleColumn(cells, '.y');
    if (ci == null || ri == null || y == null) return null;
    if (!MortonLayout.sliceCovers(ci, ri, range, nRi: rows.n)) {
      print('⚠️ Block read for $image did not contain exactly its cells; falling back to full load');
      return null;
    }

    final slice = _Slice(range, rows.n, meta);
    for (var i = 0; i < ci.length; i++) {
      final c = ci[i];
      if (!range.contains(c)) continue;
      slice.cells[(c - range.start) * rows.n + ri[i]] = y[i];
    }
    print('✓ Slice for $image: ${range.count} columns x ${rows.n} variables in ${sw.elapsedMilliseconds} ms');
    return slice;
  }

  static List<int>? _intColumn(Table t, String name) {
    for (final c in t.columns) {
      if (c.name == name) return (c.values as List).map((v) => (v as num).toInt()).toList(growable: false);
    }
    return null;
  }

  static Float64List? _doubleColumn(Table t, String name) {
    for (final c in t.columns) {
      if (c.name == name) {
        final v = c.values;
        if (v is Float64List) return v;
        return Float64List.fromList((v as List).map((e) => (e as num).toDouble()).toList());
      }
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Full load
  // ---------------------------------------------------------------------------

  /// The whole crosstab, loaded once. Concurrent callers share the load.
  Future<_FullData> _getTercenData() {
    final loaded = _fullData;
    if (loaded != null) return Future.value(loaded);
    return _fullLoad ??= _loadFullData().then((d) {
      _fullData = d;
      return d;
    }, onError: (Object e) {
      _fullLoad = null; // allow a retry
      throw e;
    });
  }

  /// Starts the full load without waiting for it. Errors are logged; the next
  /// explicit caller (save, or a grid that cannot be sliced) surfaces them.
  void _startFullLoadInBackground() {
    if (_fullData != null || _fullLoad != null) return;
    _getTercenData().catchError((Object e) {
      print('⚠️ Background crosstab load failed: $e');
      return Future<_FullData>.error(e);
    }).ignore();
  }

  Future<_FullData> _loadFullData() async {
    final ctx = await _getContext();
    final rows = await _getRowVars();
    final mainSchema = await ctx.schema;
    final cs = await ctx.cschema;
    final nCols = cs.nRows;
    final totalQtRows = mainSchema.nRows;
    final nRi = rows.n;
    print('📋 Loading the whole crosstab: $totalQtRows cells, $nCols columns x $nRi variables');

    final sw = Stopwatch()..start();
    final y = Float64List(nCols * nRi)..fillRange(0, nCols * nRi, double.nan);
    var loaded = 0;
    _loadProgress.value = LoadProgress('Loading grid data', 0, totalQtRows);

    // Chunks are fetched a few at a time; the order they land in does not
    // matter because every cell is written to its (ci, ri) slot.
    final chunks = chunkRows(totalQtRows, selectChunkRows);
    var next = 0;
    Future<void> worker() async {
      while (next < chunks.length) {
        final chunk = chunks[next++];
        final tbl = await ctx.select(
            names: const ['.ci', '.ri', '.y'], offset: chunk.offset, limit: chunk.limit);
        final ci = _intColumn(tbl, '.ci');
        final ri = _intColumn(tbl, '.ri');
        final yy = _doubleColumn(tbl, '.y');
        if (ci == null || ri == null || yy == null) {
          throw StateError('select returned no .ci/.ri/.y columns');
        }
        for (var i = 0; i < ci.length; i++) {
          final c = ci[i], r = ri[i];
          if (c < 0 || c >= nCols || r < 0 || r >= nRi) continue;
          y[c * nRi + r] = yy[i];
        }
        loaded += tbl.nRows;
        _loadProgress.value = LoadProgress('Loading grid data', loaded, totalQtRows);
      }
    }

    await Future.wait(List.generate(parallelSelects, (_) => worker()));
    print('✓ Cells: $loaded rows in ${sw.elapsedMilliseconds} ms');

    _loadProgress.value = LoadProgress('Loading spot layout', loaded, totalQtRows);
    final names = await _colNames(ctx);
    final meta = await _loadColumns(ctx, names);
    print('✓ Columns: ${meta.n} in ${sw.elapsedMilliseconds} ms total');

    final data = _FullData(nCols: nCols, nRi: nRi, y: y, meta: meta, rowVars: rows);
    _loadProgress.value = LoadProgress('Grid data loaded', totalQtRows, totalQtRows);
    print('✓ Crosstab ready: ${data.allImages.length} images, ${sw.elapsedMilliseconds} ms');
    return data;
  }

  // ---------------------------------------------------------------------------
  // GridService
  // ---------------------------------------------------------------------------

  @override
  Future<GridData> loadGridData(String gridImageId) async {
    final cached = _gridDataCache[gridImageId];
    if (cached != null) return cached;

    try {
      print('🔍 Loading grid for $gridImageId');
      _SpotSource? source = _fullData;
      if (source == null) {
        // First look at a grid: read its own block and let the rest stream in
        // behind it, rather than making the user wait for every cell.
        _startFullLoadInBackground();
        try {
          source = await _loadSlice(gridImageId);
        } catch (e) {
          print('⚠️ Sliced load failed for $gridImageId: $e — waiting for the full load');
        }
        source ??= await _getTercenData();
      }
      final rows = await _getRowVars();
      final gridData = _buildGridDataForImage(source, rows, gridImageId);
      _gridDataCache[gridImageId] = gridData;
      _statusCache[gridImageId] = GridStatus.processed;

      print('✓ ${gridData.fiducials.length} fiducials for $gridImageId');
      return gridData;
    } catch (e, stackTrace) {
      print('❌ ERROR loading grid data: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Build GridData for a single image from a slice or the full data.
  GridData _buildGridDataForImage(_SpotSource data, _RowVars rows, String gridImageId) {
    // Resolve gridImageId to matching Image in the data
    String? resolvedImageName;
    if (data.hasImage(gridImageId)) {
      resolvedImageName = gridImageId;
    } else {
      final parts = gridImageId.split('_');
      if (parts.length >= 4) {
        final prefix = parts.sublist(0, 4).join('_');
        for (final img in data.images) {
          if (img.startsWith(prefix)) {
            resolvedImageName = img;
            break;
          }
        }
      }
    }

    final fiducials = <FiducialPosition>[];

    if (resolvedImageName != null) {
      final riGridX = rows.indexOf('gridX');
      final riGridY = rows.indexOf('gridY');
      final riDiameter = rows.indexOf('diameter');
      final riManual = rows.indexOf('manual');
      final riBad = rows.indexOf('bad');
      final riEmpty = rows.indexOf('empty');

      for (final ci in data.cisFor(resolvedImageName)) {
        final gridX = data.y(ci, riGridX);
        final gridY = data.y(ci, riGridY);
        if (gridX == null || gridY == null) continue;
        final diameter = data.y(ci, riDiameter);
        final manual = data.y(ci, riManual);
        final bad = data.y(ci, riBad);
        final empty = data.y(ci, riEmpty);

        fiducials.add(FiducialPosition(
          id: '$ci',
          ci: ci,
          imageName: data.image(ci),
          grdImageNameUsed: data.grdImage(ci),
          row: data.spotRow(ci),
          col: data.spotCol(ci),
          baseX: gridY,
          baseY: gridX,
          diameter: diameter ?? 0.0,
          isReference: data.id(ci) == '#REF',
          isManual: manual?.toInt() == 1,
          isBad: bad?.toInt() == 1,
          isEmpty: empty?.toInt() == 1,
        ));
      }
    }

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
    Future<void> step(String msg, int actual, int total) async {
      _saveProgress.value = LoadProgress(msg, actual, total);
      await ctx.progress(msg, actual: actual, total: total);
    }

    try {
      print('📤 saveAllGrids: loading the whole crosstab if not there yet...');
      await step('Preparing grids', 0, 3);

      // 1. Every cell: the output is one row per spot for every image.
      final data = await _getTercenData();
      final rows = data.rowVars;

      // 2. Ensure all grid images are loaded (lazy load any unvisited ones)
      for (final gridImageId in allGridImageIds) {
        if (!_gridDataCache.containsKey(gridImageId)) {
          print('  Loading unvisited grid: $gridImageId');
          _gridDataCache[gridImageId] = _buildGridDataForImage(data, rows, gridImageId);
        }
      }

      await step('Building results', 1, 3);

      // 3. Build position lookup for modified grids:
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

      // 4. Row index of each output variable
      final riGridX = rows.indexOf('gridX');
      final riGridY = rows.indexOf('gridY');
      final riFixedX = rows.indexOf('grdXFixedPosition');
      final riFixedY = rows.indexOf('grdYFixedPosition');
      final riDiameter = rows.indexOf('diameter');
      final riManual = rows.indexOf('manual');
      final riBad = rows.indexOf('bad');
      final riEmpty = rows.indexOf('empty');
      final riRotation = rows.indexOf('grdRotation');

      // 5. Build output arrays — one row per spot (unique .ci), in ci order
      final nOut = data.nCols;
      final outCi = Int32List(nOut);
      final outGridX = Float64List(nOut);
      final outGridY = Float64List(nOut);
      final outFixedX = Float64List(nOut);
      final outFixedY = Float64List(nOut);
      final outDiameter = Float64List(nOut);
      final outManual = Float64List(nOut);
      final outBad = Float64List(nOut);
      final outEmpty = Float64List(nOut);
      final outRotation = Float64List(nOut);
      final outGrdImageNameUsed = List<String>.filled(nOut, '');
      final outImage = List<String>.filled(nOut, '');

      for (var ci = 0; ci < nOut; ci++) {
        final spotRow = data.spotRow(ci);
        final spotCol = data.spotCol(ci);
        final imageName = data.image(ci);
        final grdImageName = data.grdImage(ci);

        // Check if this spot's grid was modified
        final modifiedSpot = modifiedGridLookup[grdImageName]?['${spotRow}_$spotCol'];

        outCi[ci] = ci;
        outGrdImageNameUsed[ci] = grdImageName;
        outImage[ci] = imageName;
        if (modifiedSpot != null) {
          // Use modified positions (propagated from the grid image to all images)
          outGridX[ci] = modifiedSpot.tercenGridX;
          outGridY[ci] = modifiedSpot.tercenGridY;
          outFixedX[ci] = modifiedSpot.tercenGridX; // manual: fixed = current
          outFixedY[ci] = modifiedSpot.tercenGridY;
          outDiameter[ci] = modifiedSpot.diameter;
          outManual[ci] = modifiedSpot.isManual ? 1.0 : 0.0;
          outBad[ci] = modifiedSpot.isBad ? 1.0 : 0.0;
          outEmpty[ci] = modifiedSpot.isEmpty ? 1.0 : 0.0;
          outRotation[ci] = modifiedSpot.rotation;
        } else {
          // Use original values from Tercen data
          outGridX[ci] = data.y(ci, riGridX) ?? 0.0;
          outGridY[ci] = data.y(ci, riGridY) ?? 0.0;
          outFixedX[ci] = data.y(ci, riFixedX) ?? 0.0;
          outFixedY[ci] = data.y(ci, riFixedY) ?? 0.0;
          outDiameter[ci] = data.y(ci, riDiameter) ?? 0.0;
          outManual[ci] = data.y(ci, riManual) ?? 0.0;
          outBad[ci] = data.y(ci, riBad) ?? 0.0;
          outEmpty[ci] = data.y(ci, riEmpty) ?? 0.0;
          outRotation[ci] = data.y(ci, riRotation) ?? 0.0;
        }
      }

      print('  Output: $nOut rows');

      // 6. Add namespace prefixes to column names
      final ns = await ctx.namespace;
      print('  Operator namespace: "$ns"');
      final nameMap = await ctx.addNamespace([
        'gridX', 'gridY', 'grdXFixedPosition', 'grdYFixedPosition',
        'diameter', 'manual', 'bad', 'empty', 'grdRotation',
        'grdImageNameUsed', 'Image',
      ]);
      print('  Namespaced columns: $nameMap');

      // 7. Build the output Table with TypedData on column.values
      //    TSON encoder requires dart:typed_data (Int32List, Float64List) and
      //    CStringList for correct binary serialization (LIST_INT32_TYPE,
      //    LIST_FLOAT64_TYPE, LIST_STRING_TYPE). Regular Dart lists serialize
      //    as generic LIST_TYPE which the server rejects.
      final table = Table();
      table.nRows = nOut;

      // .ci column (system column — no namespace prefix)
      final ciCol = Column();
      ciCol.name = '.ci';
      ciCol.type = 'int32';
      ciCol.nRows = nOut;
      ciCol.values = outCi;
      final ciVals = I32Values();
      ciVals.values.addAll(outCi);
      ciCol.cValues = ciVals;
      table.columns.add(ciCol);

      // Double columns: column.values = Float64List for correct TSON encoding
      void addDoubleCol(String name, Float64List values) {
        final col = Column();
        col.name = nameMap[name]!;
        col.type = 'double';
        col.nRows = nOut;
        col.values = values;
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
        col.nRows = nOut;
        col.values = CStringList.fromList(values);
        final str = StrValues();
        str.values.addAll(values);
        col.cValues = str;
        table.columns.add(col);
      }

      addStringCol('grdImageNameUsed', outGrdImageNameUsed);
      addStringCol('Image', outImage);

      print('  Table built: ${table.nRows} rows, ${table.columns.length} columns');

      // 8. Save to Tercen
      await step('Uploading results, this can take a minute', 2, 3);
      print('📤 Saving table to Tercen...');

      await ctx.saveTable(table);

      await step('Uploaded, waiting for the step to complete', 3, 3);
      print('✓ Save complete!');
    } finally {
      _saveProgress.value = null;
    }
  }

  @override
  Future<bool> waitForTaskCompletion(
      {Duration timeout = const Duration(minutes: 2)}) async {
    final taskId = _urlParser.taskId;
    if (taskId == null) return true;
    final deadline = DateTime.now().add(timeout);
    var delay = const Duration(milliseconds: 500);
    while (DateTime.now().isBefore(deadline)) {
      try {
        final task = await _factory.taskService.get(taskId);
        final kind = task.state.kind;
        if (kind == 'DoneState') return true;
        if (kind == 'FailedState' || kind == 'CanceledState') {
          print('✗ Task $taskId ended in $kind');
          return false;
        }
      } catch (e) {
        print('⚠️ Could not read task $taskId while waiting for completion: $e');
      }
      await Future<void>.delayed(delay);
      if (delay < const Duration(seconds: 3)) delay *= 2;
    }
    print('⚠️ Task $taskId did not reach Done within $timeout');
    return false;
  }
}

/// The row variables of the crosstab: how many, and each one's name by index.
class _RowVars {
  final int n;
  final Map<int, String> names;
  _RowVars(this.n, this.names);

  /// Row index of [variable], or -1 when the crosstab does not carry it.
  int indexOf(String variable) {
    for (final e in names.entries) {
      if (e.value == variable) return e.key;
    }
    return -1;
  }
}

/// Namespaced names of the column factors this operator reads.
class _ColNames {
  final String image, grdImage, spotRow, spotCol, id;
  const _ColNames({
    required this.image,
    required this.grdImage,
    required this.spotRow,
    required this.spotCol,
    required this.id,
  });
}

/// Column factors for a run of columns, in flat arrays indexed from 0.
class _ColMeta {
  final int n;
  final List<String> image;
  final List<String> grdImage;
  final List<String> id;
  final Int32List spotRow;
  final Int32List spotCol;
  _ColMeta(this.n)
      : image = List<String>.filled(n, ''),
        grdImage = List<String>.filled(n, ''),
        id = List<String>.filled(n, ''),
        spotRow = Int32List(n),
        spotCol = Int32List(n);
}

/// What [_buildGridDataForImage] needs to know about the spots of an image,
/// whether they come from a slice or the whole crosstab.
abstract class _SpotSource {
  bool hasImage(String image);
  Iterable<String> get images;
  Iterable<int> cisFor(String image);
  /// The cell value, or null when the variable is absent (ri < 0) or missing.
  double? y(int ci, int ri);
  String image(int ci);
  String grdImage(int ci);
  String id(int ci);
  int spotRow(int ci);
  int spotCol(int ci);
}

/// One image's columns: cells in a flat array, column metadata from its range.
class _Slice implements _SpotSource {
  final CiRange range;
  final int nRi;
  final _ColMeta meta;
  final Float64List cells;
  _Slice(this.range, this.nRi, this.meta)
      : cells = Float64List(range.count * nRi)..fillRange(0, range.count * nRi, double.nan);

  @override
  bool hasImage(String image) => meta.image.isNotEmpty && meta.image[0] == image;
  @override
  Iterable<String> get images => meta.image.isEmpty ? const [] : [meta.image[0]];
  @override
  Iterable<int> cisFor(String image) =>
      hasImage(image) ? Iterable<int>.generate(range.count, (i) => range.start + i) : const [];

  double? _cell(int ci, int ri) {
    if (ri < 0 || ri >= nRi || !range.contains(ci)) return null;
    final v = cells[(ci - range.start) * nRi + ri];
    return v.isNaN ? null : v;
  }

  @override
  double? y(int ci, int ri) => _cell(ci, ri);
  @override
  String image(int ci) => meta.image[ci - range.start];
  @override
  String grdImage(int ci) => meta.grdImage[ci - range.start];
  @override
  String id(int ci) => meta.id[ci - range.start];
  @override
  int spotRow(int ci) => meta.spotRow[ci - range.start];
  @override
  int spotCol(int ci) => meta.spotCol[ci - range.start];
}

/// The whole crosstab in flat typed arrays: `y[ci * nRi + ri]`.
class _FullData implements _SpotSource {
  final int nCols;
  final int nRi;
  final Float64List cells;
  final _ColMeta meta;
  final _RowVars rowVars;

  /// Image name -> its column indices, in order (an index over [meta.image]).
  late final Map<String, List<int>> _ciByImage = () {
    final m = <String, List<int>>{};
    for (var ci = 0; ci < nCols; ci++) {
      (m[meta.image[ci]] ??= <int>[]).add(ci);
    }
    return m;
  }();

  _FullData({
    required this.nCols,
    required this.nRi,
    required Float64List y,
    required this.meta,
    required this.rowVars,
  }) : cells = y;

  Set<String> get allImages => _ciByImage.keys.toSet();

  @override
  bool hasImage(String image) => _ciByImage.containsKey(image);
  @override
  Iterable<String> get images => _ciByImage.keys;
  @override
  Iterable<int> cisFor(String image) => _ciByImage[image] ?? const [];

  @override
  double? y(int ci, int ri) {
    if (ri < 0 || ri >= nRi || ci < 0 || ci >= nCols) return null;
    final v = cells[ci * nRi + ri];
    return v.isNaN ? null : v;
  }

  @override
  String image(int ci) => meta.image[ci];
  @override
  String grdImage(int ci) => meta.grdImage[ci];
  @override
  String id(int ci) => meta.id[ci];
  @override
  int spotRow(int ci) => meta.spotRow[ci];
  @override
  int spotCol(int ci) => meta.spotCol[ci];
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
