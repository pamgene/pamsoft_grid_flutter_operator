import 'package:flutter/material.dart';

/// Application-wide constants.
class AppConstants {
  // App info
  static const String appTitle = 'Pamsoft Grid Checker';

  // Layout dimensions
  static const double leftPanelWidth = 300.0;
  static const double leftPanelMinWidth = 280.0;
  static const double leftPanelMaxWidth = 350.0;

  // Image container - fixed size based on TIFF aspect ratio (552x413)
  // Using a scale factor to display at a reasonable size
  static const double imageOriginalWidth = 552.0;
  static const double imageOriginalHeight = 413.0;
  static const double imageDisplayScale = 1.4; // Scale up for better visibility
  static const double imageContainerWidth = imageOriginalWidth * imageDisplayScale;
  static const double imageContainerHeight = imageOriginalHeight * imageDisplayScale;

  // Grid canvas - sized to match visible blobs in the image
  static const double fiducialRadius = 8.0;
  static const double fiducialHitTestRadius = 14.0;
  static const double fiducialStrokeWidth = 1.5;
  static const Color fiducialColor = Colors.green;

  // Status indicator
  static const double statusIndicatorSize = 14.0;
  static const Color statusProcessedColor = Colors.green;
  static const Color statusModifiedColor = Colors.yellow;

  // Brightness/Contrast defaults
  static const double defaultBrightness = 0.0;
  static const double minBrightness = -0.5;
  static const double maxBrightness = 0.5;

  static const double defaultContrast = 1.0;
  static const double minContrast = 0.2;
  static const double maxContrast = 4.0;

  // Pagination options
  static const List<int> pageSizeOptions = [10, 25, 50, 100, -1]; // -1 = All
  static const int defaultPageSize = -1;

  // Processing
  static const Duration processingDelay = Duration(seconds: 5);
}
