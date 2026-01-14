import 'dart:typed_data';

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

  /// PNG image bytes (converted from TIFF at runtime).
  Uint8List? get imageBytes;

  /// Creates a copy with updated fields.
  ImageMetadata copyWith({
    bool? isGridImage,
    Uint8List? imageBytes,
  });
}
