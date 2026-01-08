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
      contrast,
      0,
      0,
      0,
      brightnessOffset,
      0,
      contrast,
      0,
      0,
      brightnessOffset,
      0,
      0,
      contrast,
      0,
      brightnessOffset,
      0,
      0,
      0,
      1,
      0,
    ]);
  }
}
