import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:pamsoft_grid_flutter_operator/models/image_metadata.dart';
import 'package:pamsoft_grid_flutter_operator/models/image_metadata_impl.dart';
import 'package:pamsoft_grid_flutter_operator/models/experiment_data.dart';
import 'package:pamsoft_grid_flutter_operator/services/image_service.dart';
import 'package:pamsoft_grid_flutter_operator/utils/tercen_url_parser.dart';
import 'package:pamsoft_grid_flutter_operator/utils/tiff_converter.dart';
import 'package:pamsoft_grid_flutter_operator/utils/document_id_resolver.dart';
import 'package:sci_tercen_client/sci_client_service_factory.dart';
import 'package:sci_tercen_client/sci_client.dart' hide ServiceFactory;

/// Tercen implementation of ImageService.
///
/// Loads images from Tercen ZIP files instead of assets.
class TercenImageService implements ImageService {
  final ServiceFactory _factory;
  final TercenUrlParser _urlParser;
  final ImageService _mockService;

  // Cache for loaded data
  ExperimentData? _cachedData;
  final Map<String, Uint8List> _imageCache = {};

  TercenImageService(this._factory, this._urlParser, this._mockService);

  @override
  Future<ExperimentData> loadExperimentData() async {
    if (_cachedData != null) {
      return _cachedData!;
    }

    try {
      print('🔍 Loading experiment data from Tercen');

      // Get the documentId from column metadata
      final documentIds = await _getDocumentIds();

      if (documentIds.isEmpty) {
        throw Exception('No documentId found in column metadata');
      }

      print('📦 Found ${documentIds.length} unique documentId(s)');

      // Download and extract images from each document
      final allImages = <ImageMetadata>[];

      for (final docId in documentIds) {
        print('📥 Downloading images for documentId: $docId');
        final images = await _downloadAndExtractImages(docId);
        allImages.addAll(images);
      }

      print('✓ Loaded ${allImages.length} images total');

      // Build experiment data structure
      final experimentData = _buildExperimentData(allImages);

      _cachedData = experimentData;
      return experimentData;
    } catch (e, stackTrace) {
      print('❌ ERROR loading experiment data from Tercen: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<List<String>> _getDocumentIds() async {
    // Strategy 1: Try extracting from column metadata (Shiny approach)
    try {
      print('📋 Strategy 1: Extracting documentId from column metadata...');
      final docIds = await _extractDocumentIdsFromColumns();
      if (docIds.isNotEmpty) {
        print('✓ Found ${docIds.length} documentId(s) from column metadata');
        return docIds;
      }
    } catch (e) {
      print('⚠️ Strategy 1 failed: $e');
    }

    // Strategy 2: Use DocumentIdResolver with fallback strategies
    try {
      print('📋 Strategy 2: Using DocumentIdResolver with fallback...');
      final resolver = DocumentIdResolver(_urlParser);
      final resolvedIds = await resolver.resolveDocumentId();

      if (resolvedIds == null || resolvedIds.documentId == null) {
        throw Exception('DocumentIdResolver failed');
      }

      print('✓ Resolved document ID: ${resolvedIds.documentId}');
      return [resolvedIds.documentId!];
    } catch (e) {
      print('⚠️ Strategy 2 failed: $e');
    }

    // Strategy 3: Try using standalone documentId from URL
    if (_urlParser.documentId != null && _urlParser.documentId!.isNotEmpty) {
      try {
        print('📋 Strategy 3: Trying standalone documentId from URL...');
        print('   Using documentId: ${_urlParser.documentId}');

        // Verify the file exists by attempting to get its metadata
        final fileService = _factory.fileService;
        await fileService.get(_urlParser.documentId!);

        print('✓ Verified documentId from URL exists: ${_urlParser.documentId}');
        return [_urlParser.documentId!];
      } catch (e) {
        print('⚠️ Strategy 3 failed: $e');
      }
    }

    throw Exception('Failed to resolve document ID using all 3 strategies');
  }

  /// Extracts documentId values from column metadata (Shiny approach).
  ///
  /// Finds columns containing "documentId" and extracts their unique values.
  Future<List<String>> _extractDocumentIdsFromColumns() async {
    final taskService = _factory.taskService;

    if (_urlParser.taskId == null) {
      throw Exception('No taskId available');
    }

    print('📋 Fetching task: ${_urlParser.taskId}');
    final task = await taskService.get(_urlParser.taskId!);

    // Navigate to CubeQueryTask
    CubeQueryTask cubeTask;
    if (task is CubeQueryTask) {
      cubeTask = task;
    } else if (task is RunWebAppTask) {
      final webAppTask = task as RunWebAppTask;
      if (webAppTask.cubeQueryTaskId.isEmpty) {
        throw Exception('No cubeQueryTaskId in RunWebAppTask');
      }
      final wrappedTask = await taskService.get(webAppTask.cubeQueryTaskId);
      if (wrappedTask is! CubeQueryTask) {
        throw Exception('Wrapped task is not CubeQueryTask');
      }
      cubeTask = wrappedTask;
    } else {
      throw Exception('Task is neither RunWebAppTask nor CubeQueryTask');
    }

    // Extract from JSON
    final taskJson = cubeTask.toJson();
    final queryJson = taskJson['query'] as Map?;

    if (queryJson == null || queryJson['relation'] == null) {
      throw Exception('Task has no query relation');
    }

    var currentRelation = queryJson['relation'] as Map?;

    // Navigate to InMemoryTable
    while (currentRelation != null) {
      if (currentRelation['kind'] == 'InMemoryRelation' &&
          currentRelation['inMemoryTable'] != null) {
        final inMemoryTable = currentRelation['inMemoryTable'] as Map;
        final columns = inMemoryTable['columns'] as List?;

        if (columns != null) {
          // Find columns containing "documentId"
          for (final col in columns) {
            final colMap = col as Map;
            final name = colMap['name'] as String?;

            if (name != null && name.contains('documentId') && !name.startsWith('.')) {
              final values = colMap['values'] as List?;
              if (values != null && values.isNotEmpty) {
                // Get unique non-null values
                final docIds = values
                    .where((v) => v != null && v.toString().isNotEmpty)
                    .map((v) => v.toString())
                    .toSet()
                    .toList();

                if (docIds.isNotEmpty) {
                  print('📋 Found documentId column: $name with ${docIds.length} unique value(s)');
                  return docIds;
                }
              }
            }
          }
        }
        break;
      }

      currentRelation = currentRelation['relation'] as Map?;
    }

    throw Exception('No documentId column found in task data');
  }

  Future<List<ImageMetadata>> _downloadAndExtractImages(String documentId) async {
    try {
      // Download ZIP file from Tercen
      final fileService = _factory.fileService;

      print('📥 Downloading file for documentId: $documentId');

      // Accumulate chunks from stream
      final chunks = <List<int>>[];
      await for (final chunk in fileService.download(documentId)) {
        chunks.add(chunk);
      }

      // Combine chunks into single byte array
      final totalLength = chunks.fold<int>(0, (sum, chunk) => sum + chunk.length);
      final zipBytes = Uint8List(totalLength);
      int offset = 0;
      for (final chunk in chunks) {
        zipBytes.setRange(offset, offset + chunk.length, chunk);
        offset += chunk.length;
      }

      print('✓ Downloaded ${zipBytes.length} bytes');

      // Extract ZIP file
      final archive = ZipDecoder().decodeBytes(zipBytes);

      print('📂 Extracting ZIP archive (${archive.files.length} files)');

      // Find ImageResults/*.tif files
      final images = <ImageMetadata>[];

      for (final file in archive.files) {
        if (file.isFile && file.name.contains('ImageResults/') && file.name.endsWith('.tif')) {
          print('  Processing: ${file.name}');

          // Extract filename from path
          final filename = file.name.split('/').last;
          final filenameWithoutExt = filename.replaceAll('.tif', '');

          // Extract file content
          final tiffBytes = file.content as List<int>;
          final tiffData = Uint8List.fromList(tiffBytes);

          // Convert TIFF to PNG
          final pngBytes = TiffConverter.tiffToPng(tiffData);

          if (pngBytes != null) {
            // Cache the PNG bytes
            _imageCache[filenameWithoutExt] = pngBytes;

            // Parse filename to create ImageMetadata
            final metadata = parseFilename(filename);

            images.add(metadata);

            print('    ✓ Converted ${filename} (${tiffBytes.length} → ${pngBytes.length} bytes)');
          } else {
            print('    ✗ Failed to convert ${filename}');
          }
        }
      }

      return images;
    } catch (e) {
      print('✗ Error downloading/extracting images for $documentId: $e');
      rethrow;
    }
  }

  ExperimentData _buildExperimentData(List<ImageMetadata> images) {
    // For Tercen integration, we treat each T100 image as a grid image
    // Group images by their id (each image is its own group for now)
    final gridImages = <ImageMetadata>[];
    final imagesByGrid = <String, List<ImageMetadata>>{};

    for (final image in images) {
      if (image.isGridImage) {
        gridImages.add(image);
        imagesByGrid[image.id] = [image];
      }
    }

    // Use first experimentId from images, or default
    final experimentId = images.isNotEmpty ? images.first.experimentId : 'tercen';

    return ExperimentData(
      experimentId: experimentId,
      gridImages: gridImages,
      imagesByGrid: imagesByGrid,
    );
  }

  @override
  Future<List<ImageMetadata>> getGridImages() async {
    final data = await loadExperimentData();
    return data.gridImages;
  }

  @override
  Future<List<ImageMetadata>> getImagesForGrid(String gridImageId) async {
    final data = await loadExperimentData();
    return data.imagesByGrid[gridImageId] ?? [];
  }

  @override
  String getImageAssetPath(String imageId) {
    // Not used for Tercen - images are loaded from cache
    return '';
  }

  @override
  Future<Uint8List?> getImageBytes(String imageId) async {
    // Return cached PNG bytes
    if (_imageCache.containsKey(imageId)) {
      return _imageCache[imageId];
    }

    // If not in cache, load experiment data first
    await loadExperimentData();

    return _imageCache[imageId];
  }

  @override
  ImageMetadata parseFilename(String filename) {
    // Use mock service's filename parser
    return _mockService.parseFilename(filename);
  }
}
