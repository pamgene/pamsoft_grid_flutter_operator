# Pamsoft Grid Checker - Technical Specification v0.1.0

**Created:** 2026-01-08

**Version:** 0.1.0

**Status:** Draft

**Repository:** pamsoft_grid_flutter_operator

---

## Document Overview

This document specifies the technical architecture, patterns, and implementation requirements for version 0.1.0 of **Pamsoft Grid Checker**. This specification provides a structured approach to Flutter application development with clean architecture principles.

---

## Version 0.1.0 Scope

Version 0.1.0 is a **Minimum Viable Product (MVP)** focused on establishing the core architecture with abstraction layers and mock implementations.

### Goals

- Establish project architecture with abstraction layers
- Implement service injection pattern using GetIt
- Create mock services for development and testing
- Build core UI components and screens
- Demonstrate data loading and display with mock images
- Validate architecture for future real backend integration
- Provide theme support (light/dark modes)
- Support web deployment (primary) and desktop execution

### Non-Goals (Deferred to Future Versions)

- Real backend API integration
- Actual algorithm execution
- File system integration for loading experiments
- Persistent storage/database
- Advanced features beyond MVP
- Authentication/authorization
- Full mobile/tablet responsiveness
- Advanced user customization

---

## Architecture Overview

### Layered Architecture

The application follows a clean architecture pattern with clear separation of concerns:

```
┌─────────────────────────────────────────────────────────────────┐
│                      Presentation Layer                         │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────────┐  │
│  │   Screens    │  │   Widgets    │  │      Providers       │  │
│  │              │  │              │  │                      │  │
│  │ - HomeScreen │  │ - GridCanvas │  │ - GridProvider       │  │
│  │              │  │ - ImageList  │  │ - ImageProvider      │  │
│  │              │  │ - NavButtons │  │ - ThemeProvider      │  │
│  │              │  │ - Sliders    │  │ - SettingsProvider   │  │
│  └──────────────┘  └──────────────┘  └──────────────────────┘  │
└─────────────────────────────┬───────────────────────────────────┘
                              │
┌─────────────────────────────▼───────────────────────────────────┐
│                       Domain Layer                              │
│  ┌──────────────────────┐  ┌──────────────────────────────────┐│
│  │       Models         │  │           Services               ││
│  │     (Abstract)       │  │          (Abstract)              ││
│  │                      │  │                                  ││
│  │ - ImageMetadata      │  │ - ImageService                   ││
│  │ - GridData           │  │ - GridService                    ││
│  │ - FiducialPosition   │  │ - StorageService                 ││
│  │ - ExperimentData     │  │                                  ││
│  └──────────────────────┘  └──────────────────────────────────┘│
└─────────────────────────────┬───────────────────────────────────┘
                              │
┌─────────────────────────────▼───────────────────────────────────┐
│                    Implementation Layer                         │
│  ┌──────────────────────┐  ┌──────────────────────────────────┐│
│  │    Mock Impls        │  │         Real Impls               ││
│  │     (v0.1.0)         │  │         (Future)                 ││
│  │                      │  │                                  ││
│  │ - MockImageService   │  │ - RealImageService               ││
│  │ - MockGridService    │  │ - RealGridService                ││
│  │ - MockStorageService │  │ - RealStorageService             ││
│  └──────────────────────┘  └──────────────────────────────────┘│
└─────────────────────────────────────────────────────────────────┘
```

### Directory Structure

```
lib/
├── main.dart                              # Application entry point
├── di/
│   └── service_locator.dart               # Dependency injection setup
├── models/
│   ├── image_metadata.dart                # Abstract image metadata interface
│   ├── image_metadata_impl.dart           # Concrete implementation
│   ├── grid_data.dart                     # Grid data model
│   ├── fiducial_position.dart             # Individual fiducial position
│   ├── experiment_data.dart               # Experiment collection model
│   └── enums.dart                         # Status enums, etc.
├── services/
│   ├── image_service.dart                 # Abstract image service interface
│   ├── grid_service.dart                  # Abstract grid service interface
│   └── storage_service.dart               # Abstract storage interface
├── implementations/
│   └── services/
│       ├── mock_image_service.dart        # Mock image service
│       ├── mock_grid_service.dart         # Mock grid service
│       └── mock_storage_service.dart      # Mock storage service
├── providers/
│   ├── grid_provider.dart                 # Grid state management
│   ├── image_provider.dart                # Image selection state
│   ├── settings_provider.dart             # Brightness/contrast/theme state
│   └── theme_provider.dart                # Theme state management
├── screens/
│   └── home_screen.dart                   # Main application screen
├── widgets/
│   ├── grid_canvas.dart                   # Interactive grid overlay widget
│   ├── image_viewer.dart                  # TIFF/PNG image display widget
│   ├── image_list.dart                    # Scrollable image list
│   ├── grid_dropdown.dart                 # Grid image dropdown selector
│   ├── navigation_buttons.dart            # Grid/Image navigation buttons
│   ├── brightness_contrast_sliders.dart   # Adjustment sliders
│   ├── action_buttons.dart                # New Grid / Run buttons
│   ├── status_indicator.dart              # Green/Yellow status square
│   ├── pagination_controls.dart           # Show entries & page navigation
│   └── theme_toggle.dart                  # Light/dark mode toggle
└── utils/
    ├── constants.dart                     # App-wide constants
    ├── image_filters.dart                 # Brightness/contrast filter utilities
    └── filename_parser.dart               # TIFF filename parsing utilities

assets/
├── images/
│   ├── 641070511_W1_F1_T100_P94_I473_A29.png
│   ├── 641070511_W1_F1_T50_P94_I472_A29.png
│   └── 641070511_W1_F1_T5_P94_I469_A29.png
└── data/
    └── mock_control_file.json             # Parsed control file data

test/
├── models/                                # Model tests
├── services/                              # Service interface tests
├── implementations/
│   └── services/                          # Mock service tests
├── providers/                             # Provider tests
└── widgets/                               # Widget tests

integration_test/
└── app_flow_test.dart                     # End-to-end tests
```

---

## Dependency Injection Pattern

### Service Locator Setup

Using **GetIt** for dependency injection to enable:

- Easy mocking for tests
- Swapping between mock and real implementations
- Singleton service management
- Clear dependency management

**Implementation:**

```dart
// lib/di/service_locator.dart
import 'package:get_it/get_it.dart';
import 'package:pamsoft_grid_flutter_operator/implementations/services/mock_image_service.dart';
import 'package:pamsoft_grid_flutter_operator/implementations/services/mock_grid_service.dart';
import 'package:pamsoft_grid_flutter_operator/implementations/services/mock_storage_service.dart';
import 'package:pamsoft_grid_flutter_operator/services/image_service.dart';
import 'package:pamsoft_grid_flutter_operator/services/grid_service.dart';
import 'package:pamsoft_grid_flutter_operator/services/storage_service.dart';

/// Global service locator instance.
final GetIt getIt = GetIt.instance;

/// Alias for backwards compatibility
final GetIt locator = getIt;

/// Sets up the service locator with dependency registrations.
///
/// Call this function before running the app to register all services.
///
/// Parameters:
///   - [useMocks]: If true, registers mock implementations. If false, registers
///     real implementations (when available). Defaults to true.
///
/// Example:
/// ```dart
/// void main() {
///   setupServiceLocator(useMocks: true);
///   runApp(MyApp());
/// }
/// ```
void setupServiceLocator({bool useMocks = true}) {
  if (useMocks) {
    // Register mock services
    locator.registerSingleton<ImageService>(MockImageService());
    locator.registerSingleton<GridService>(MockGridService());
    locator.registerSingleton<StorageService>(MockStorageService());
  } else {
    // TODO: Register real services when implemented
    // locator.registerSingleton<ImageService>(RealImageService());
    // locator.registerSingleton<GridService>(RealGridService());
    // locator.registerSingleton<StorageService>(RealStorageService());
    throw UnimplementedError('Real services not yet implemented');
  }
}

/// Resets the service locator.
///
/// Useful for testing to ensure a clean state between tests.
Future<void> resetServiceLocator() async {
  await locator.reset();
}
```

**Usage in main.dart:**

```dart
void main() {
  setupServiceLocator(useMocks: true);
  runApp(const PamsoftGridCheckerApp());
}
```

**Usage in widgets:**

```dart
class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final imageService = locator<ImageService>();
    // Use service...
  }
}
```

---

## Service Abstractions

### 1. ImageService

**Purpose:** Abstract interface for image management and metadata retrieval.

**Interface:**

```dart
// lib/services/image_service.dart
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
```

**Mock Implementation:**

```dart
// lib/implementations/services/mock_image_service.dart
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
    final parts = filename.replaceAll('.tif', '').split('_');
    return ImageMetadataImpl(
      id: filename.replaceAll('.tif', ''),
      filename: filename,
      experimentId: parts[0],
      well: parts[1],
      field: parts[2],
      timePoint: parts[3],
      position: parts[4],
      imageNumber: parts[5],
      array: parts[6],
      isGridImage: parts[3] == 'T100',
    );
  }
}
```

### 2. GridService

**Purpose:** Abstract interface for grid coordinate management and processing.

**Interface:**

```dart
// lib/services/grid_service.dart
import 'package:pamsoft_grid_flutter_operator/models/grid_data.dart';
import 'package:pamsoft_grid_flutter_operator/models/fiducial_position.dart';

/// Abstract interface for grid service.
///
/// Provides methods to load, modify, and process grid coordinates.
abstract class GridService {
  /// Loads grid data for a specific grid image.
  ///
  /// Returns fitted grid coordinates from the algorithm (mock data in v0.1.0).
  Future<GridData> loadGridData(String gridImageId);

  /// Saves adjusted grid coordinates.
  ///
  /// [gridImageId] - The grid image identifier.
  /// [gridData] - The adjusted grid data.
  Future<void> saveGridAdjustments(String gridImageId, GridData gridData);

  /// Loads the default grid from control file.
  ///
  /// Used when user clicks "New Grid" to reset to original positions.
  Future<GridData> loadDefaultGrid();

  /// Runs the grid processing algorithm (mock: 5-second delay).
  ///
  /// [gridImageId] - The grid image to process.
  /// Returns processed grid data.
  Future<GridData> runGridProcessing(String gridImageId);

  /// Gets the current status for a grid image.
  ///
  /// Returns [GridStatus.processed] (green) or [GridStatus.modified] (yellow).
  GridStatus getGridStatus(String gridImageId);

  /// Updates the status for a grid image.
  void setGridStatus(String gridImageId, GridStatus status);
}

/// Status of a grid image in the QC workflow.
enum GridStatus {
  /// Grid has been processed (shown as green indicator)
  processed,

  /// Grid has been modified but not yet processed (shown as yellow indicator)
  modified,
}
```

**Mock Implementation:**

```dart
// lib/implementations/services/mock_grid_service.dart
import 'dart:math';
import 'package:pamsoft_grid_flutter_operator/models/grid_data.dart';
import 'package:pamsoft_grid_flutter_operator/models/fiducial_position.dart';
import 'package:pamsoft_grid_flutter_operator/services/grid_service.dart';

/// Mock implementation of GridService for development and testing.
class MockGridService implements GridService {
  final Map<String, GridData> _gridDataCache = {};
  final Map<String, GridStatus> _statusCache = {};
  final Random _random = Random(42); // Seeded for consistency

  // Control file grid structure (14x14 peptides + 8 reference fiducials)
  static const int gridRows = 14;
  static const int gridCols = 14;
  static const double cellWidth = 30.0;
  static const double cellHeight = 30.0;
  static const double gridOffsetX = 100.0;
  static const double gridOffsetY = 50.0;

  @override
  Future<GridData> loadGridData(String gridImageId) async {
    await Future.delayed(const Duration(milliseconds: 200));

    if (_gridDataCache.containsKey(gridImageId)) {
      return _gridDataCache[gridImageId]!;
    }

    // Generate mock fitted grid (control file + small random offsets)
    final gridData = _generateMockFittedGrid(gridImageId);
    _gridDataCache[gridImageId] = gridData;
    _statusCache[gridImageId] = GridStatus.processed;

    return gridData;
  }

  GridData _generateMockFittedGrid(String gridImageId) {
    final fiducials = <FiducialPosition>[];

    // Generate 14x14 peptide grid
    for (int row = 0; row < gridRows; row++) {
      for (int col = 0; col < gridCols; col++) {
        final baseX = gridOffsetX + (col * cellWidth);
        final baseY = gridOffsetY + (row * cellHeight);

        // Add small random offset to simulate algorithm fit
        final offsetX = (_random.nextDouble() - 0.5) * 4;
        final offsetY = (_random.nextDouble() - 0.5) * 4;

        fiducials.add(FiducialPosition(
          id: 'peptide_${row}_$col',
          row: row,
          col: col,
          x: baseX + offsetX,
          y: baseY + offsetY,
          isReference: false,
        ));
      }
    }

    // Add reference fiducials around edges
    final refPositions = [
      (-1, -1), (-3, -1), (-5, -1), (-3, -2),
      (-2, -20), (-4, -20), (-6, -20), (-6, -19),
    ];

    for (int i = 0; i < refPositions.length; i++) {
      final (refRow, refCol) = refPositions[i];
      final baseX = gridOffsetX + (refCol * cellWidth * 0.5);
      final baseY = gridOffsetY + (refRow * cellHeight * 0.5);

      fiducials.add(FiducialPosition(
        id: 'ref_$i',
        row: refRow,
        col: refCol,
        x: baseX,
        y: baseY,
        isReference: true,
      ));
    }

    return GridData(
      gridImageId: gridImageId,
      fiducials: fiducials,
      globalOffsetX: 0,
      globalOffsetY: 0,
    );
  }

  @override
  Future<void> saveGridAdjustments(String gridImageId, GridData gridData) async {
    await Future.delayed(const Duration(milliseconds: 100));
    _gridDataCache[gridImageId] = gridData;
    _statusCache[gridImageId] = GridStatus.modified;
  }

  @override
  Future<GridData> loadDefaultGrid() async {
    await Future.delayed(const Duration(milliseconds: 200));

    // Return grid based purely on control file (no algorithm offsets)
    final fiducials = <FiducialPosition>[];

    for (int row = 0; row < gridRows; row++) {
      for (int col = 0; col < gridCols; col++) {
        fiducials.add(FiducialPosition(
          id: 'peptide_${row}_$col',
          row: row,
          col: col,
          x: gridOffsetX + (col * cellWidth),
          y: gridOffsetY + (row * cellHeight),
          isReference: false,
        ));
      }
    }

    // Add reference fiducials
    final refPositions = [
      (-1, -1), (-3, -1), (-5, -1), (-3, -2),
      (-2, -20), (-4, -20), (-6, -20), (-6, -19),
    ];

    for (int i = 0; i < refPositions.length; i++) {
      final (refRow, refCol) = refPositions[i];
      fiducials.add(FiducialPosition(
        id: 'ref_$i',
        row: refRow,
        col: refCol,
        x: gridOffsetX + (refCol * cellWidth * 0.5),
        y: gridOffsetY + (refRow * cellHeight * 0.5),
        isReference: true,
      ));
    }

    return GridData(
      gridImageId: 'default',
      fiducials: fiducials,
      globalOffsetX: 0,
      globalOffsetY: 0,
    );
  }

  @override
  Future<GridData> runGridProcessing(String gridImageId) async {
    // Simulate 5-second processing delay
    await Future.delayed(const Duration(seconds: 5));

    // Mark as processed
    _statusCache[gridImageId] = GridStatus.processed;

    // Return current grid data (with adjustments applied)
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
```

### 3. StorageService

**Purpose:** Abstract interface for local/session storage.

**Interface:**

```dart
// lib/services/storage_service.dart

/// Abstract interface for storage service.
abstract class StorageService {
  /// Gets brightness setting.
  double getBrightness();

  /// Sets brightness setting.
  void setBrightness(double value);

  /// Gets contrast setting.
  double getContrast();

  /// Sets contrast setting.
  void setContrast(double value);

  /// Gets current theme mode.
  bool isDarkMode();

  /// Sets theme mode.
  void setDarkMode(bool isDark);

  /// Gets current page size for image list.
  int getPageSize();

  /// Sets page size for image list.
  void setPageSize(int size);

  /// Clears all stored data.
  void clear();
}
```

**Mock Implementation:**

```dart
// lib/implementations/services/mock_storage_service.dart
import 'package:pamsoft_grid_flutter_operator/services/storage_service.dart';

/// Mock implementation of StorageService for development and testing.
///
/// Stores all values in memory (session only).
class MockStorageService implements StorageService {
  double _brightness = 0.0;      // Default: 0 (range: -0.5 to 0.5)
  double _contrast = 1.0;        // Default: 1 (range: 0.2 to 4.0)
  bool _isDarkMode = false;      // Default: light mode
  int _pageSize = -1;            // Default: -1 means "All"

  @override
  double getBrightness() => _brightness;

  @override
  void setBrightness(double value) {
    _brightness = value.clamp(-0.5, 0.5);
  }

  @override
  double getContrast() => _contrast;

  @override
  void setContrast(double value) {
    _contrast = value.clamp(0.2, 4.0);
  }

  @override
  bool isDarkMode() => _isDarkMode;

  @override
  void setDarkMode(bool isDark) {
    _isDarkMode = isDark;
  }

  @override
  int getPageSize() => _pageSize;

  @override
  void setPageSize(int size) {
    _pageSize = size;
  }

  @override
  void clear() {
    _brightness = 0.0;
    _contrast = 1.0;
    _isDarkMode = false;
    _pageSize = -1;
  }
}
```

---

## Data Models

### ImageMetadata (Abstract)

```dart
// lib/models/image_metadata.dart

/// Abstract interface for image metadata.
abstract class ImageMetadata {
  /// Unique identifier (filename without extension).
  String get id;

  /// Full filename including extension.
  String get filename;

  /// Experiment run identifier.
  String get experimentId;

  /// Well identifier (W1, W2, W3, W4).
  String get well;

  /// Field identifier (F1, F2, etc.).
  String get field;

  /// Time point (T5, T10, T25, T50, T100).
  String get timePoint;

  /// Position identifier.
  String get position;

  /// Image number in sequence.
  String get imageNumber;

  /// Array type (A29, A30).
  String get array;

  /// Whether this is a grid image (T100 time point).
  bool get isGridImage;

  /// Display name for UI (typically the filename).
  String get displayName;

  /// Creates a copy with updated fields.
  ImageMetadata copyWith({
    bool? isGridImage,
  });
}
```

### ImageMetadata Implementation

```dart
// lib/models/image_metadata_impl.dart
import 'package:pamsoft_grid_flutter_operator/models/image_metadata.dart';

/// Concrete implementation of ImageMetadata.
class ImageMetadataImpl implements ImageMetadata {
  @override
  final String id;

  @override
  final String filename;

  @override
  final String experimentId;

  @override
  final String well;

  @override
  final String field;

  @override
  final String timePoint;

  @override
  final String position;

  @override
  final String imageNumber;

  @override
  final String array;

  @override
  final bool isGridImage;

  const ImageMetadataImpl({
    required this.id,
    required this.filename,
    required this.experimentId,
    required this.well,
    required this.field,
    required this.timePoint,
    required this.position,
    required this.imageNumber,
    required this.array,
    this.isGridImage = false,
  });

  @override
  String get displayName => id;

  @override
  ImageMetadata copyWith({bool? isGridImage}) {
    return ImageMetadataImpl(
      id: id,
      filename: filename,
      experimentId: experimentId,
      well: well,
      field: field,
      timePoint: timePoint,
      position: position,
      imageNumber: imageNumber,
      array: array,
      isGridImage: isGridImage ?? this.isGridImage,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ImageMetadata &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
```

### FiducialPosition

```dart
// lib/models/fiducial_position.dart

/// Represents a single fiducial position in the grid.
class FiducialPosition {
  /// Unique identifier for this fiducial.
  final String id;

  /// Row in the grid (-ve for reference fiducials).
  final int row;

  /// Column in the grid (-ve for reference fiducials).
  final int col;

  /// X coordinate (pixels).
  double x;

  /// Y coordinate (pixels).
  double y;

  /// Whether this is a reference fiducial (vs peptide spot).
  final bool isReference;

  /// Individual offset from base position (for individual dragging).
  double individualOffsetX;
  double individualOffsetY;

  FiducialPosition({
    required this.id,
    required this.row,
    required this.col,
    required this.x,
    required this.y,
    this.isReference = false,
    this.individualOffsetX = 0,
    this.individualOffsetY = 0,
  });

  /// Creates a copy with updated position.
  FiducialPosition copyWith({
    double? x,
    double? y,
    double? individualOffsetX,
    double? individualOffsetY,
  }) {
    return FiducialPosition(
      id: id,
      row: row,
      col: col,
      x: x ?? this.x,
      y: y ?? this.y,
      isReference: isReference,
      individualOffsetX: individualOffsetX ?? this.individualOffsetX,
      individualOffsetY: individualOffsetY ?? this.individualOffsetY,
    );
  }

  /// Gets the actual display position (base + individual offset).
  double get displayX => x + individualOffsetX;
  double get displayY => y + individualOffsetY;
}
```

### GridData

```dart
// lib/models/grid_data.dart
import 'package:pamsoft_grid_flutter_operator/models/fiducial_position.dart';

/// Contains all grid data for a single grid image.
class GridData {
  /// The grid image this data belongs to.
  final String gridImageId;

  /// All fiducial positions in the grid.
  final List<FiducialPosition> fiducials;

  /// Global X offset (for whole-grid dragging).
  double globalOffsetX;

  /// Global Y offset (for whole-grid dragging).
  double globalOffsetY;

  GridData({
    required this.gridImageId,
    required this.fiducials,
    this.globalOffsetX = 0,
    this.globalOffsetY = 0,
  });

  /// Creates a deep copy of the grid data.
  GridData copyWith({
    String? gridImageId,
    List<FiducialPosition>? fiducials,
    double? globalOffsetX,
    double? globalOffsetY,
  }) {
    return GridData(
      gridImageId: gridImageId ?? this.gridImageId,
      fiducials: fiducials ?? this.fiducials.map((f) => f.copyWith()).toList(),
      globalOffsetX: globalOffsetX ?? this.globalOffsetX,
      globalOffsetY: globalOffsetY ?? this.globalOffsetY,
    );
  }

  /// Gets the number of peptide spots.
  int get peptideCount => fiducials.where((f) => !f.isReference).length;

  /// Gets the number of reference fiducials.
  int get referenceCount => fiducials.where((f) => f.isReference).length;
}
```

### ExperimentData

```dart
// lib/models/experiment_data.dart
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
```

---

## State Management with Provider

### GridProvider

```dart
// lib/providers/grid_provider.dart
import 'package:flutter/foundation.dart';
import 'package:pamsoft_grid_flutter_operator/di/service_locator.dart';
import 'package:pamsoft_grid_flutter_operator/models/grid_data.dart';
import 'package:pamsoft_grid_flutter_operator/models/fiducial_position.dart';
import 'package:pamsoft_grid_flutter_operator/services/grid_service.dart';

/// Provider for managing grid state and interactions.
class GridProvider extends ChangeNotifier {
  final GridService _gridService = locator<GridService>();

  GridData? _currentGridData;
  String? _currentGridImageId;
  bool _isLoading = false;
  bool _isProcessing = false;
  String? _error;

  GridData? get currentGridData => _currentGridData;
  String? get currentGridImageId => _currentGridImageId;
  bool get isLoading => _isLoading;
  bool get isProcessing => _isProcessing;
  String? get error => _error;

  /// Gets the current grid status.
  GridStatus get currentStatus =>
      _currentGridImageId != null
          ? _gridService.getGridStatus(_currentGridImageId!)
          : GridStatus.processed;

  /// Loads grid data for a specific grid image.
  Future<void> loadGrid(String gridImageId) async {
    _isLoading = true;
    _error = null;
    _currentGridImageId = gridImageId;
    notifyListeners();

    try {
      _currentGridData = await _gridService.loadGridData(gridImageId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Moves the entire grid by an offset.
  void moveWholeGrid(double dx, double dy) {
    if (_currentGridData == null) return;

    _currentGridData!.globalOffsetX += dx;
    _currentGridData!.globalOffsetY += dy;

    _markAsModified();
    notifyListeners();
  }

  /// Moves a single fiducial by an offset.
  void moveFiducial(String fiducialId, double dx, double dy) {
    if (_currentGridData == null) return;

    final fiducial = _currentGridData!.fiducials.firstWhere(
      (f) => f.id == fiducialId,
      orElse: () => throw Exception('Fiducial not found'),
    );

    fiducial.individualOffsetX += dx;
    fiducial.individualOffsetY += dy;

    _markAsModified();
    notifyListeners();
  }

  void _markAsModified() {
    if (_currentGridImageId != null) {
      _gridService.setGridStatus(_currentGridImageId!, GridStatus.modified);
      _gridService.saveGridAdjustments(_currentGridImageId!, _currentGridData!);
    }
  }

  /// Resets to default grid from control file.
  Future<void> resetToDefaultGrid() async {
    if (_currentGridImageId == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final defaultGrid = await _gridService.loadDefaultGrid();
      _currentGridData = GridData(
        gridImageId: _currentGridImageId!,
        fiducials: defaultGrid.fiducials,
        globalOffsetX: 0,
        globalOffsetY: 0,
      );
      _markAsModified();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Runs grid processing (5-second mock delay).
  Future<void> runProcessing() async {
    if (_currentGridImageId == null) return;

    _isProcessing = true;
    notifyListeners();

    try {
      _currentGridData = await _gridService.runGridProcessing(_currentGridImageId!);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }
}
```

### ImageProvider

```dart
// lib/providers/image_provider.dart
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
  String? _error;

  ExperimentData? get experimentData => _experimentData;
  bool get isLoading => _isLoading;
  String? get error => _error;

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
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Navigates to the next grid image.
  void nextGrid() {
    if (_experimentData == null) return;
    if (_currentGridIndex < _experimentData!.gridImages.length - 1) {
      _currentGridIndex++;
      _currentImageIndex = 0;
      notifyListeners();
    }
  }

  /// Navigates to the previous grid image.
  void previousGrid() {
    if (_currentGridIndex > 0) {
      _currentGridIndex--;
      _currentImageIndex = 0;
      notifyListeners();
    }
  }

  /// Sets the current grid by index.
  void setGridIndex(int index) {
    if (_experimentData == null) return;
    if (index >= 0 && index < _experimentData!.gridImages.length) {
      _currentGridIndex = index;
      _currentImageIndex = 0;
      notifyListeners();
    }
  }

  /// Navigates to the next image in the list.
  void nextImage() {
    final images = currentGridImages;
    if (_currentImageIndex < images.length - 1) {
      _currentImageIndex++;
      notifyListeners();
    }
  }

  /// Navigates to the previous image in the list.
  void previousImage() {
    if (_currentImageIndex > 0) {
      _currentImageIndex--;
      notifyListeners();
    }
  }

  /// Sets the current image by index.
  void setImageIndex(int index) {
    final images = currentGridImages;
    if (index >= 0 && index < images.length) {
      _currentImageIndex = index;
      notifyListeners();
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
```

### SettingsProvider

```dart
// lib/providers/settings_provider.dart
import 'package:flutter/foundation.dart';
import 'package:pamsoft_grid_flutter_operator/di/service_locator.dart';
import 'package:pamsoft_grid_flutter_operator/services/storage_service.dart';

/// Provider for managing brightness, contrast, and pagination settings.
class SettingsProvider extends ChangeNotifier {
  final StorageService _storageService = locator<StorageService>();

  double get brightness => _storageService.getBrightness();
  double get contrast => _storageService.getContrast();
  int get pageSize => _storageService.getPageSize();

  /// Sets the brightness value.
  void setBrightness(double value) {
    _storageService.setBrightness(value);
    notifyListeners();
  }

  /// Sets the contrast value.
  void setContrast(double value) {
    _storageService.setContrast(value);
    notifyListeners();
  }

  /// Sets the page size for image list.
  void setPageSize(int size) {
    _storageService.setPageSize(size);
    notifyListeners();
  }
}
```

### ThemeProvider

```dart
// lib/providers/theme_provider.dart
import 'package:flutter/material.dart';
import 'package:pamsoft_grid_flutter_operator/di/service_locator.dart';
import 'package:pamsoft_grid_flutter_operator/services/storage_service.dart';

/// Provider for managing application theme (light/dark mode).
class ThemeProvider extends ChangeNotifier {
  final StorageService _storageService = locator<StorageService>();

  bool get isDarkMode => _storageService.isDarkMode();

  ThemeMode get themeMode => isDarkMode ? ThemeMode.dark : ThemeMode.light;

  /// Toggles between light and dark mode.
  void toggleTheme() {
    _storageService.setDarkMode(!isDarkMode);
    notifyListeners();
  }

  /// Sets the theme mode explicitly.
  void setDarkMode(bool isDark) {
    _storageService.setDarkMode(isDark);
    notifyListeners();
  }
}
```

---

## Key Widget Implementations

### GridCanvas Widget

```dart
// lib/widgets/grid_canvas.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pamsoft_grid_flutter_operator/models/grid_data.dart';
import 'package:pamsoft_grid_flutter_operator/models/fiducial_position.dart';
import 'package:pamsoft_grid_flutter_operator/providers/grid_provider.dart';

/// Interactive canvas for displaying and manipulating the grid overlay.
class GridCanvas extends StatefulWidget {
  final double imageWidth;
  final double imageHeight;

  const GridCanvas({
    super.key,
    required this.imageWidth,
    required this.imageHeight,
  });

  @override
  State<GridCanvas> createState() => _GridCanvasState();
}

class _GridCanvasState extends State<GridCanvas> {
  String? _draggingFiducialId;
  Offset? _lastDragPosition;

  static const double fiducialRadius = 8.0;
  static const double hitTestRadius = 12.0;

  @override
  Widget build(BuildContext context) {
    return Consumer<GridProvider>(
      builder: (context, gridProvider, child) {
        final gridData = gridProvider.currentGridData;
        if (gridData == null) {
          return const SizedBox.shrink();
        }

        return GestureDetector(
          onPanStart: (details) => _onPanStart(details, gridData, gridProvider),
          onPanUpdate: (details) => _onPanUpdate(details, gridProvider),
          onPanEnd: (_) => _onPanEnd(),
          child: CustomPaint(
            size: Size(widget.imageWidth, widget.imageHeight),
            painter: GridPainter(
              gridData: gridData,
              fiducialRadius: fiducialRadius,
            ),
          ),
        );
      },
    );
  }

  void _onPanStart(DragStartDetails details, GridData gridData, GridProvider provider) {
    final localPosition = details.localPosition;

    // Check if we're clicking on a fiducial
    for (final fiducial in gridData.fiducials) {
      final fiducialPos = Offset(
        fiducial.displayX + gridData.globalOffsetX,
        fiducial.displayY + gridData.globalOffsetY,
      );

      if ((localPosition - fiducialPos).distance <= hitTestRadius) {
        _draggingFiducialId = fiducial.id;
        _lastDragPosition = localPosition;
        return;
      }
    }

    // Not on a fiducial, will drag whole grid
    _draggingFiducialId = null;
    _lastDragPosition = localPosition;
  }

  void _onPanUpdate(DragUpdateDetails details, GridProvider provider) {
    if (_lastDragPosition == null) return;

    final delta = details.localPosition - _lastDragPosition!;
    _lastDragPosition = details.localPosition;

    if (_draggingFiducialId != null) {
      // Dragging individual fiducial
      provider.moveFiducial(_draggingFiducialId!, delta.dx, delta.dy);
    } else {
      // Dragging whole grid
      provider.moveWholeGrid(delta.dx, delta.dy);
    }
  }

  void _onPanEnd() {
    _draggingFiducialId = null;
    _lastDragPosition = null;
  }
}

/// Custom painter for rendering the grid overlay.
class GridPainter extends CustomPainter {
  final GridData gridData;
  final double fiducialRadius;

  GridPainter({
    required this.gridData,
    required this.fiducialRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    for (final fiducial in gridData.fiducials) {
      final center = Offset(
        fiducial.displayX + gridData.globalOffsetX,
        fiducial.displayY + gridData.globalOffsetY,
      );

      canvas.drawCircle(center, fiducialRadius, paint);
    }
  }

  @override
  bool shouldRepaint(GridPainter oldDelegate) {
    return oldDelegate.gridData != gridData;
  }
}
```

### ImageViewer Widget

```dart
// lib/widgets/image_viewer.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pamsoft_grid_flutter_operator/providers/settings_provider.dart';
import 'package:pamsoft_grid_flutter_operator/providers/image_provider.dart';
import 'package:pamsoft_grid_flutter_operator/widgets/grid_canvas.dart';
import 'package:pamsoft_grid_flutter_operator/utils/image_filters.dart';

/// Widget for displaying the TIFF/PNG image with grid overlay.
class ImageViewer extends StatelessWidget {
  const ImageViewer({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<ImageSelectionProvider, SettingsProvider>(
      builder: (context, imageProvider, settingsProvider, child) {
        final assetPath = imageProvider.currentImageAssetPath;

        if (assetPath.isEmpty) {
          return const Center(
            child: Text('No image selected'),
          );
        }

        return Container(
          color: Colors.black,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  // Image with brightness/contrast filter
                  ColorFiltered(
                    colorFilter: ImageFilters.createBrightnessContrastFilter(
                      brightness: settingsProvider.brightness,
                      contrast: settingsProvider.contrast,
                    ),
                    child: Image.asset(
                      assetPath,
                      fit: BoxFit.contain,
                      width: constraints.maxWidth,
                      height: constraints.maxHeight,
                    ),
                  ),
                  // Grid overlay
                  Positioned.fill(
                    child: GridCanvas(
                      imageWidth: constraints.maxWidth,
                      imageHeight: constraints.maxHeight,
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}
```

### Image Filters Utility

```dart
// lib/utils/image_filters.dart
import 'dart:ui';

/// Utility class for creating image filters.
class ImageFilters {
  /// Creates a color filter matrix for brightness and contrast adjustment.
  ///
  /// [brightness] - Range: -0.5 to 0.5, default: 0
  /// [contrast] - Range: 0.2 to 4.0, default: 1
  static ColorFilter createBrightnessContrastFilter({
    required double brightness,
    required double contrast,
  }) {
    // Normalize brightness to 0-255 range for the matrix
    final brightnessOffset = brightness * 255;

    // Contrast adjustment: values are multiplied, then brightness is added
    return ColorFilter.matrix(<double>[
      contrast, 0, 0, 0, brightnessOffset,
      0, contrast, 0, 0, brightnessOffset,
      0, 0, contrast, 0, brightnessOffset,
      0, 0, 0, 1, 0,
    ]);
  }
}
```

---

## Testing Strategy

### Unit Tests

**Service Tests:**

```dart
// test/services/mock_image_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:pamsoft_grid_flutter_operator/implementations/services/mock_image_service.dart';

void main() {
  group('MockImageService', () {
    late MockImageService service;

    setUp(() {
      service = MockImageService();
    });

    test('loadExperimentData returns experiment data', () async {
      final data = await service.loadExperimentData();

      expect(data, isNotNull);
      expect(data.experimentId, equals('641070511'));
      expect(data.gridImages, isNotEmpty);
    });

    test('getGridImages returns T100 images', () async {
      final gridImages = await service.getGridImages();

      expect(gridImages, isNotEmpty);
      for (final image in gridImages) {
        expect(image.timePoint, equals('T100'));
        expect(image.isGridImage, isTrue);
      }
    });

    test('getImagesForGrid returns all time points', () async {
      final gridImages = await service.getGridImages();
      final images = await service.getImagesForGrid(gridImages.first.id);

      expect(images.length, equals(5)); // T100, T50, T25, T10, T5
    });

    test('getImageAssetPath returns correct asset for time point', () {
      final t100Path = service.getImageAssetPath('test_T100_test');
      final t5Path = service.getImageAssetPath('test_T5_test');

      expect(t100Path, contains('T100'));
      expect(t5Path, contains('T5'));
    });
  });
}
```

**Provider Tests:**

```dart
// test/providers/grid_provider_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:pamsoft_grid_flutter_operator/di/service_locator.dart';
import 'package:pamsoft_grid_flutter_operator/providers/grid_provider.dart';
import 'package:pamsoft_grid_flutter_operator/services/grid_service.dart';

void main() {
  group('GridProvider', () {
    late GridProvider provider;

    setUp(() {
      setupServiceLocator(useMocks: true);
      provider = GridProvider();
    });

    tearDown(() async {
      await resetServiceLocator();
    });

    test('initial state has no grid data', () {
      expect(provider.currentGridData, isNull);
      expect(provider.isLoading, isFalse);
      expect(provider.isProcessing, isFalse);
    });

    test('loadGrid loads grid data', () async {
      await provider.loadGrid('test_grid_id');

      expect(provider.currentGridData, isNotNull);
      expect(provider.currentGridData!.fiducials, isNotEmpty);
      expect(provider.isLoading, isFalse);
    });

    test('moveWholeGrid updates global offset', () async {
      await provider.loadGrid('test_grid_id');

      provider.moveWholeGrid(10, 20);

      expect(provider.currentGridData!.globalOffsetX, equals(10));
      expect(provider.currentGridData!.globalOffsetY, equals(20));
      expect(provider.currentStatus, equals(GridStatus.modified));
    });

    test('moveFiducial updates individual offset', () async {
      await provider.loadGrid('test_grid_id');
      final fiducialId = provider.currentGridData!.fiducials.first.id;

      provider.moveFiducial(fiducialId, 5, 10);

      final fiducial = provider.currentGridData!.fiducials
          .firstWhere((f) => f.id == fiducialId);
      expect(fiducial.individualOffsetX, equals(5));
      expect(fiducial.individualOffsetY, equals(10));
    });

    test('runProcessing changes status to processed', () async {
      await provider.loadGrid('test_grid_id');
      provider.moveWholeGrid(10, 20); // Mark as modified

      expect(provider.currentStatus, equals(GridStatus.modified));

      await provider.runProcessing();

      expect(provider.currentStatus, equals(GridStatus.processed));
      expect(provider.isProcessing, isFalse);
    });
  });
}
```

### Widget Tests

```dart
// test/widgets/status_indicator_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pamsoft_grid_flutter_operator/widgets/status_indicator.dart';
import 'package:pamsoft_grid_flutter_operator/services/grid_service.dart';

void main() {
  group('StatusIndicator', () {
    testWidgets('displays green for processed status', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatusIndicator(status: GridStatus.processed),
          ),
        ),
      );

      final container = tester.widget<Container>(find.byType(Container));
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, equals(Colors.green));
    });

    testWidgets('displays yellow for modified status', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatusIndicator(status: GridStatus.modified),
          ),
        ),
      );

      final container = tester.widget<Container>(find.byType(Container));
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, equals(Colors.yellow));
    });
  });
}
```

### Integration Tests

```dart
// integration_test/app_flow_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:pamsoft_grid_flutter_operator/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('App Flow', () {
    testWidgets('loads and displays experiment data', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Verify main screen loads
      expect(find.text('Pamsoft Grid Checker'), findsOneWidget);

      // Verify grid dropdown is populated
      expect(find.byType(DropdownButton), findsOneWidget);
    });

    testWidgets('can navigate between grids using buttons', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Find and tap Grid>> button
      await tester.tap(find.text('Grid>>'));
      await tester.pumpAndSettle();

      // Verify navigation occurred (would need to check state)
    });

    testWidgets('can toggle theme', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Find and tap theme toggle
      await tester.tap(find.byIcon(Icons.dark_mode));
      await tester.pumpAndSettle();

      // Verify theme changed (check for light mode icon)
      expect(find.byIcon(Icons.light_mode), findsOneWidget);
    });
  });
}
```

---

## Dependencies (pubspec.yaml)

```yaml
name: pamsoft_grid_flutter_operator
description: "Quality control application for reviewing automated fiducial grid fitting on Pamstation experiment images."
publish_to: 'none'
version: 0.1.0

environment:
  sdk: ^3.5.0

dependencies:
  flutter:
    sdk: flutter

  # State management
  provider: ^6.1.1

  # Service locator for dependency injection
  get_it: ^7.6.4

  # Utilities
  uuid: ^4.2.1
  intl: ^0.19.0

  # UI components
  cupertino_icons: ^1.0.8

dev_dependencies:
  flutter_test:
    sdk: flutter
  integration_test:
    sdk: flutter

  # Linting and testing
  flutter_lints: ^4.0.0
  mockito: ^5.4.4
  build_runner: ^2.4.6

flutter:
  uses-material-design: true

  assets:
    - assets/images/
    - assets/data/
```

---

## Implementation Checklist

### Phase 1: Foundation

- [ ] Set up Flutter project structure
- [ ] Configure pubspec.yaml with dependencies
- [ ] Create directory structure (models, services, implementations, etc.)
- [ ] Set up GetIt service locator
- [ ] Create abstract model interfaces
- [ ] Create abstract service interfaces

### Phase 2: Mock Implementations

- [ ] Implement MockImageService with sample data
- [ ] Implement MockGridService with grid generation
- [ ] Implement MockStorageService
- [ ] Create concrete model implementations
- [ ] Write unit tests for mock services

### Phase 3: State Management

- [ ] Create GridProvider
- [ ] Create ImageSelectionProvider
- [ ] Create SettingsProvider
- [ ] Create ThemeProvider
- [ ] Write provider unit tests

### Phase 4: UI Components

- [ ] Create StatusIndicator widget
- [ ] Create GridCanvas widget with drag interactions
- [ ] Create ImageViewer widget with filters
- [ ] Create ImageList widget
- [ ] Create GridDropdown widget
- [ ] Create NavigationButtons widget
- [ ] Create BrightnessContrastSliders widget
- [ ] Create ActionButtons widget (New Grid / Run)
- [ ] Create PaginationControls widget
- [ ] Create ThemeToggle widget
- [ ] Write widget tests

### Phase 5: Screens

- [ ] Create HomeScreen with full layout
- [ ] Implement keyboard navigation (arrow keys)
- [ ] Wire up all providers to UI
- [ ] Write screen tests

### Phase 6: Integration

- [ ] Implement theme switching
- [ ] Add loading states and error handling
- [ ] Test on web platform
- [ ] Test on desktop platform
- [ ] Write integration tests

### Phase 7: Polish

- [ ] Performance optimization
- [ ] Accessibility improvements
- [ ] Code cleanup and documentation
- [ ] Final testing pass

---

## Best Practices

### 1. Service Abstraction

- Always define abstract interfaces for services
- Keep interfaces focused and cohesive
- Mock implementations should behave realistically
- Use dependency injection for all service access

### 2. Testing

- Write tests alongside implementation (TDD approach)
- Aim for >80% code coverage
- Test edge cases and error conditions
- Use meaningful test descriptions

### 3. State Management

- Keep providers focused on single responsibilities
- Use `notifyListeners()` judiciously
- Implement proper error handling in providers
- Reset service locator between tests

### 4. Code Organization

- Follow consistent naming conventions
- Group related functionality
- Keep files small and focused
- Document public APIs with dartdoc comments

### 5. Performance

- Use `const` constructors where possible
- Implement efficient grid rendering with CustomPainter
- Cache computed values where appropriate
- Profile before optimizing

---

## Future Enhancements (Post v0.1.0)

### Real Backend Integration

- Implement RealImageService with file system access
- Implement RealGridService with algorithm execution
- Add output file generation
- Integrate with upstream/downstream pipeline

### Advanced Features

- Undo/redo for grid adjustments
- Zoom/pan controls for image viewer
- Comparison view (before/after)
- Export QC report
- Batch processing

### Performance Improvements

- Virtual scrolling for large image lists
- Lazy loading of grid data
- Caching strategies
- Optimized rendering for large grids

---

## Revision History

| Version | Date       | Author | Changes                          |
| ------- | ---------- | ------ | -------------------------------- |
| 0.1.0   | 2026-01-08 | Claude | Initial technical specification  |
