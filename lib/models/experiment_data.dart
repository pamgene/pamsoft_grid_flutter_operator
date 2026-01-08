import 'package:pamsoft_grid_flutter_operator/models/image_metadata.dart';

/// Contains all data for an experiment session.
class ExperimentData {
  /// The experiment identifier.
  final String experimentId;

  /// List of grid images (T100 time points).
  final List<ImageMetadata> gridImages;

  /// Map of grid image ID to its associated time point images.
  final Map<String, List<ImageMetadata>> imagesByGrid;

  const ExperimentData({
    required this.experimentId,
    required this.gridImages,
    required this.imagesByGrid,
  });

  /// Gets the total number of images across all grids.
  int get totalImageCount =>
      imagesByGrid.values.fold(0, (sum, list) => sum + list.length);
}
