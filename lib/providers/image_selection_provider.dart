import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:pamsoft_grid_flutter_operator/di/service_locator.dart';
import 'package:pamsoft_grid_flutter_operator/models/image_metadata.dart';
import 'package:pamsoft_grid_flutter_operator/models/experiment_data.dart';
import 'package:pamsoft_grid_flutter_operator/services/image_service.dart';

/// Provider for managing image selection and navigation.
class ImageSelectionProvider extends ChangeNotifier {
  final ImageService _imageService = locator<ImageService>();

  ExperimentData? _experimentData;
  int _currentGridIndex = 0;
  int _currentImageIndex = 0;
  bool _isLoading = false;
  bool _isLoadingImage = false;
  String? _error;
  Uint8List? _currentImageBytes;

  ExperimentData? get experimentData => _experimentData;
  bool get isLoading => _isLoading;
  bool get isLoadingImage => _isLoadingImage;
  String? get error => _error;
  Uint8List? get currentImageBytes => _currentImageBytes;

  /// Gets the current grid image.
  ImageMetadata? get currentGridImage {
    if (_experimentData == null || _experimentData!.gridImages.isEmpty) {
      return null;
    }
    return _experimentData!.gridImages[_currentGridIndex];
  }

  /// Gets all images for the current grid.
  List<ImageMetadata> get currentGridImages {
    final gridImage = currentGridImage;
    if (gridImage == null || _experimentData == null) return [];
    return _experimentData!.imagesByGrid[gridImage.id] ?? [];
  }

  /// Gets the currently selected image (may be grid or time point).
  ImageMetadata? get currentImage {
    final images = currentGridImages;
    if (images.isEmpty) return null;
    return images[_currentImageIndex.clamp(0, images.length - 1)];
  }

  /// Gets the index of the current grid image.
  int get currentGridIndex => _currentGridIndex;

  /// Gets the index of the current image in the list.
  int get currentImageIndex => _currentImageIndex;

  /// Gets total number of grid images.
  int get gridImageCount => _experimentData?.gridImages.length ?? 0;

  /// Gets the asset path for the current image.
  String get currentImageAssetPath {
    final image = currentImage;
    if (image == null) return '';
    return _imageService.getImageAssetPath(image.id);
  }

  /// Loads experiment data.
  Future<void> loadExperiment() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _experimentData = await _imageService.loadExperimentData();
      _currentGridIndex = 0;
      _currentImageIndex = 0;
      _isLoading = false;
      notifyListeners();

      // Load the first image bytes
      await _loadCurrentImageBytes();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Loads the image bytes for the current image.
  Future<void> _loadCurrentImageBytes() async {
    final image = currentImage;
    if (image == null) {
      _currentImageBytes = null;
      return;
    }

    _isLoadingImage = true;
    notifyListeners();

    try {
      _currentImageBytes = await _imageService.getImageBytes(image.id);
    } catch (e) {
      print('ImageSelectionProvider: Error loading image bytes: $e');
      _currentImageBytes = null;
    } finally {
      _isLoadingImage = false;
      notifyListeners();
    }
  }

  /// Navigates to the next grid image.
  void nextGrid() {
    if (_experimentData == null) return;
    if (_currentGridIndex < _experimentData!.gridImages.length - 1) {
      _currentGridIndex++;
      _currentImageIndex = 0;
      _currentImageBytes = null;
      notifyListeners();
      _loadCurrentImageBytes();
    }
  }

  /// Navigates to the previous grid image.
  void previousGrid() {
    if (_currentGridIndex > 0) {
      _currentGridIndex--;
      _currentImageIndex = 0;
      _currentImageBytes = null;
      notifyListeners();
      _loadCurrentImageBytes();
    }
  }

  /// Sets the current grid by index.
  void setGridIndex(int index) {
    if (_experimentData == null) return;
    if (index >= 0 && index < _experimentData!.gridImages.length) {
      _currentGridIndex = index;
      _currentImageIndex = 0;
      _currentImageBytes = null;
      notifyListeners();
      _loadCurrentImageBytes();
    }
  }

  /// Navigates to the next image in the list.
  void nextImage() {
    final images = currentGridImages;
    if (_currentImageIndex < images.length - 1) {
      _currentImageIndex++;
      _currentImageBytes = null;
      notifyListeners();
      _loadCurrentImageBytes();
    }
  }

  /// Navigates to the previous image in the list.
  void previousImage() {
    if (_currentImageIndex > 0) {
      _currentImageIndex--;
      _currentImageBytes = null;
      notifyListeners();
      _loadCurrentImageBytes();
    }
  }

  /// Sets the current image by index.
  void setImageIndex(int index) {
    final images = currentGridImages;
    if (index >= 0 && index < images.length) {
      _currentImageIndex = index;
      _currentImageBytes = null;
      notifyListeners();
      _loadCurrentImageBytes();
    }
  }

  /// Checks if we can navigate to next grid.
  bool get canGoNextGrid =>
      _experimentData != null &&
      _currentGridIndex < _experimentData!.gridImages.length - 1;

  /// Checks if we can navigate to previous grid.
  bool get canGoPreviousGrid => _currentGridIndex > 0;

  /// Checks if we can navigate to next image.
  bool get canGoNextImage => _currentImageIndex < currentGridImages.length - 1;

  /// Checks if we can navigate to previous image.
  bool get canGoPreviousImage => _currentImageIndex > 0;
}
