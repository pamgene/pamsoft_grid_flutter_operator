import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:pamsoft_grid_flutter_operator/models/image_metadata.dart';
import 'package:pamsoft_grid_flutter_operator/models/experiment_data.dart';
import 'package:pamsoft_grid_flutter_operator/services/image_service.dart';
import 'package:pamsoft_grid_flutter_operator/utils/tercen_url_parser.dart';
import 'package:pamsoft_grid_flutter_operator/utils/tiff_converter.dart';
import 'package:pamsoft_grid_flutter_operator/utils/document_id_resolver.dart';
import 'package:sci_tercen_client/sci_client_service_factory.dart';

/// Tercen implementation of ImageService.
///
/// Loads images from Tercen ZIP files instead of assets.
/// Uses lazy loading: downloads ZIP once, but only extracts/converts images on demand.
class TercenImageService implements ImageService {
  final ServiceFactory _factory;
  final TercenUrlParser _urlParser;
  final ImageService _mockService;

  // Cache for loaded data
  ExperimentData? _cachedData;
  final Map<String, Uint8List> _imageCache = {};

  // ZIP archive (downloaded once, extracted lazily)
  Archive? _archive;
  String? _loadedDocumentId;

  TercenImageService(this._factory, this._urlParser, this._mockService);

  @override
  Future<ExperimentData> loadExperimentData() async {
    if (_cachedData != null) {
      return _cachedData!;
    }

    try {
      print('🔍 Loading experiment data from Tercen (lazy loading mode)');

      // Use DocumentIdResolver to get the actual .documentId
      final resolver = DocumentIdResolver(_urlParser);
      final resolvedIds = await resolver.resolveDocumentId();

      if (resolvedIds == null || resolvedIds.documentId == null) {
        throw Exception('Failed to resolve .documentId - DocumentIdResolver returned null');
      }

      final documentId = resolvedIds.documentId!;
      print('✓ Resolved .documentId: $documentId');

      // Download ZIP and extract metadata (but don't convert images yet)
      print('📥 Downloading ZIP file for .documentId: $documentId');
      final images = await _downloadZipAndExtractMetadata(documentId);

      print('✓ Found ${images.length} images (will convert on demand)');

      // Build experiment data structure
      final experimentData = _buildExperimentData(images);

      _cachedData = experimentData;
      return experimentData;
    } catch (e, stackTrace) {
      print('❌ ERROR loading experiment data from Tercen: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Downloads ZIP file and extracts metadata only (lazy loading).
  /// Images are converted on-demand in getImageBytes().
  Future<List<ImageMetadata>> _downloadZipAndExtractMetadata(String documentId) async {
    try {
      // Download ZIP file from Tercen
      final fileService = _factory.fileService;

      print('📥 Downloading ZIP for .documentId: $documentId');

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

      // Decode ZIP archive (but don't extract files yet)
      _archive = ZipDecoder().decodeBytes(zipBytes);
      _loadedDocumentId = documentId;

      print('📂 ZIP archive contains ${_archive!.files.length} files');

      // Extract metadata only (no TIFF conversion yet)
      final images = <ImageMetadata>[];

      for (final file in _archive!.files) {
        if (file.isFile && file.name.contains('ImageResults/') && file.name.endsWith('.tif')) {
          // Extract filename from path
          final filename = file.name.split('/').last;

          // Parse filename to create ImageMetadata
          final metadata = parseFilename(filename);
          images.add(metadata);

          print('  Found: ${filename}');
        }
      }

      print('✓ Extracted metadata for ${images.length} images');

      return images;
    } catch (e) {
      print('✗ Error downloading ZIP for $documentId: $e');
      rethrow;
    }
  }

  ExperimentData _buildExperimentData(List<ImageMetadata> images) {
    // Grid images are P94 T100 images only (matching Shiny behavior).
    // Each grid image is associated with all images sharing the same
    // barcode_well_field_time prefix (e.g. "641031403_W1_F1_T100").
    final gridImages = <ImageMetadata>[];
    final imagesByGrid = <String, List<ImageMetadata>>{};

    // Group all images by barcode_well_field_time prefix
    final groupedByPrefix = <String, List<ImageMetadata>>{};
    for (final image in images) {
      final parts = image.id.split('_');
      if (parts.length >= 4) {
        final prefix = parts.sublist(0, 4).join('_');
        groupedByPrefix.putIfAbsent(prefix, () => []);
        groupedByPrefix[prefix]!.add(image);
      }
    }

    // Find P94 grid images and map them to their image groups
    for (final image in images) {
      if (image.isGridImage && image.position == 'P94') {
        gridImages.add(image);

        // Get all images with the same prefix
        final parts = image.id.split('_');
        if (parts.length >= 4) {
          final prefix = parts.sublist(0, 4).join('_');
          final group = groupedByPrefix[prefix] ?? [image];

          // Sort: grid image (P94) first, then others sorted by position
          final sorted = List<ImageMetadata>.from(group);
          sorted.sort((a, b) {
            if (a.id == image.id) return -1;
            if (b.id == image.id) return 1;
            return a.position.compareTo(b.position);
          });

          imagesByGrid[image.id] = sorted;
        } else {
          imagesByGrid[image.id] = [image];
        }
      }
    }

    print('📋 Built experiment data: ${gridImages.length} grid images (P94 only)');
    for (final gi in gridImages) {
      final count = imagesByGrid[gi.id]?.length ?? 0;
      print('  Grid: ${gi.id} → $count associated images');
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
    // Return cached PNG bytes if available
    if (_imageCache.containsKey(imageId)) {
      print('  ✓ Returning cached image: $imageId');
      return _imageCache[imageId];
    }

    // Ensure ZIP is loaded
    if (_archive == null) {
      print('  Loading experiment data first...');
      await loadExperimentData();
    }

    if (_archive == null) {
      print('  ✗ No archive available');
      return null;
    }

    try {
      // Find the TIFF file in the archive
      print('  🔍 Extracting and converting: $imageId.tif');

      for (final file in _archive!.files) {
        if (file.isFile &&
            file.name.contains('ImageResults/') &&
            file.name.endsWith('$imageId.tif')) {

          // Extract TIFF bytes
          final tiffBytes = file.content as List<int>;
          final tiffData = Uint8List.fromList(tiffBytes);

          print('    Converting TIFF (${tiffBytes.length} bytes)');

          // Convert TIFF to PNG
          final pngBytes = TiffConverter.tiffToPng(tiffData);

          if (pngBytes != null) {
            // Cache the result
            _imageCache[imageId] = pngBytes;
            print('    ✓ Converted to PNG (${pngBytes.length} bytes)');
            return pngBytes;
          } else {
            print('    ✗ Failed to convert TIFF to PNG');
            return null;
          }
        }
      }

      print('  ✗ Image not found in archive: $imageId');
      return null;
    } catch (e) {
      print('  ✗ Error extracting image $imageId: $e');
      return null;
    }
  }

  @override
  ImageMetadata parseFilename(String filename) {
    // Use mock service's filename parser
    return _mockService.parseFilename(filename);
  }
}
