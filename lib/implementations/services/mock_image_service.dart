import 'package:pamsoft_grid_flutter_operator/models/image_metadata.dart';
import 'package:pamsoft_grid_flutter_operator/models/image_metadata_impl.dart';
import 'package:pamsoft_grid_flutter_operator/models/experiment_data.dart';
import 'package:pamsoft_grid_flutter_operator/services/image_service.dart';

/// Mock implementation of ImageService for development and testing.
class MockImageService implements ImageService {
  // Sample image assets
  static const List<String> _sampleAssets = [
    'assets/images/641070511_W1_F1_T100_P94_I473_A29.png',
    'assets/images/641070511_W1_F1_T50_P94_I472_A29.png',
    'assets/images/641070511_W1_F1_T5_P94_I469_A29.png',
  ];

  // Mock grid images (representing different Well/Field combinations)
  final List<ImageMetadata> _gridImages = [];
  final Map<String, List<ImageMetadata>> _imagesByGrid = {};

  MockImageService() {
    _initializeMockData();
  }

  void _initializeMockData() {
    // Generate mock grid images for different Well/Field combinations
    final wells = ['W1', 'W2', 'W3', 'W4'];
    final fields = ['F1'];
    final timePoints = ['T100', 'T50', 'T25', 'T10', 'T5'];

    for (final well in wells) {
      for (final field in fields) {
        // Grid image is T100 (last time point, brightest)
        final gridId = '641070511_${well}_${field}_T100_P94_I473_A29';
        final gridImage = ImageMetadataImpl(
          id: gridId,
          filename: '$gridId.tif',
          experimentId: '641070511',
          well: well,
          field: field,
          timePoint: 'T100',
          position: 'P94',
          imageNumber: 'I473',
          array: 'A29',
          isGridImage: true,
        );
        _gridImages.add(gridImage);

        // Generate time point images for this grid
        final images = <ImageMetadata>[];
        for (int i = 0; i < timePoints.length; i++) {
          final time = timePoints[i];
          final imgNum = 473 - i;
          final id = '641070511_${well}_${field}_${time}_P94_I${imgNum}_A29';
          images.add(ImageMetadataImpl(
            id: id,
            filename: '$id.tif',
            experimentId: '641070511',
            well: well,
            field: field,
            timePoint: time,
            position: 'P94',
            imageNumber: 'I$imgNum',
            array: 'A29',
            isGridImage: time == 'T100',
          ));
        }
        _imagesByGrid[gridId] = images;
      }
    }
  }

  @override
  Future<ExperimentData> loadExperimentData() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return ExperimentData(
      experimentId: '641070511',
      gridImages: _gridImages,
      imagesByGrid: _imagesByGrid,
    );
  }

  @override
  Future<List<ImageMetadata>> getGridImages() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return List.from(_gridImages);
  }

  @override
  Future<List<ImageMetadata>> getImagesForGrid(String gridImageId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _imagesByGrid[gridImageId] ?? [];
  }

  @override
  String getImageAssetPath(String imageId) {
    // Cycle through sample images based on time point
    if (imageId.contains('T100')) {
      return _sampleAssets[0];
    } else if (imageId.contains('T50')) {
      return _sampleAssets[1];
    } else {
      return _sampleAssets[2];
    }
  }

  @override
  ImageMetadata parseFilename(String filename) {
    // Parse: {ExperimentID}_{Well}_{Field}_{Time}_{Position}_{Image}_{Array}.tif
    final cleanName = filename.replaceAll('.tif', '').replaceAll('.png', '');
    final parts = cleanName.split('_');
    return ImageMetadataImpl(
      id: cleanName,
      filename: filename,
      experimentId: parts.isNotEmpty ? parts[0] : '',
      well: parts.length > 1 ? parts[1] : '',
      field: parts.length > 2 ? parts[2] : '',
      timePoint: parts.length > 3 ? parts[3] : '',
      position: parts.length > 4 ? parts[4] : '',
      imageNumber: parts.length > 5 ? parts[5] : '',
      array: parts.length > 6 ? parts[6] : '',
      isGridImage: parts.length > 3 && parts[3] == 'T100',
    );
  }
}
