import 'package:pamsoft_grid_flutter_operator/models/image_metadata.dart';
import 'package:pamsoft_grid_flutter_operator/models/experiment_data.dart';

/// Abstract interface for image service.
///
/// Provides methods to load, query, and manage experiment images.
abstract class ImageService {
  /// Loads all experiment data including grid images and their time points.
  ///
  /// Returns a [Future] that completes with [ExperimentData].
  Future<ExperimentData> loadExperimentData();

  /// Gets all grid images (T100 time points).
  ///
  /// Returns a list of [ImageMetadata] representing grid images.
  Future<List<ImageMetadata>> getGridImages();

  /// Gets all images for a specific grid image group.
  ///
  /// [gridImageId] - The ID of the grid image.
  /// Returns all time points associated with that Well/Field combination.
  Future<List<ImageMetadata>> getImagesForGrid(String gridImageId);

  /// Gets the asset path for displaying an image.
  ///
  /// In mock implementation, cycles through available sample images.
  /// [imageId] - The image identifier.
  String getImageAssetPath(String imageId);

  /// Parses filename to extract metadata.
  ///
  /// Returns parsed components: experimentId, well, field, time, position, etc.
  ImageMetadata parseFilename(String filename);
}
