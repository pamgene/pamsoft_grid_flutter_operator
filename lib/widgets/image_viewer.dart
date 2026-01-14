import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pamsoft_grid_flutter_operator/providers/settings_provider.dart';
import 'package:pamsoft_grid_flutter_operator/providers/image_selection_provider.dart';
import 'package:pamsoft_grid_flutter_operator/widgets/grid_canvas.dart';
import 'package:pamsoft_grid_flutter_operator/utils/image_filters.dart';
import 'package:pamsoft_grid_flutter_operator/utils/constants.dart';
import 'package:pamsoft_grid_flutter_operator/utils/asset_helper.dart';

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

        // Fixed size container based on TIFF aspect ratio
        return Center(
          child: Container(
            width: AppConstants.imageContainerWidth,
            height: AppConstants.imageContainerHeight,
            decoration: BoxDecoration(
              color: Colors.black,
              border: Border.all(color: Colors.grey.shade700, width: 1),
            ),
            child: ClipRect(
              child: Stack(
                children: [
                  // Image with brightness/contrast filter - fills container
                  Positioned.fill(
                    child: ColorFiltered(
                      colorFilter: ImageFilters.createBrightnessContrastFilter(
                        brightness: settingsProvider.brightness,
                        contrast: settingsProvider.contrast,
                      ),
                      child: Image.network(
                        AssetHelper.getAssetUrl(assetPath),
                        fit: BoxFit.fill,
                        errorBuilder: (context, error, stackTrace) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  color: Colors.red,
                                  size: 48,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Failed to load image',
                                  style: TextStyle(color: Colors.grey[400]),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  // Grid overlay - clipped to container bounds
                  Positioned.fill(
                    child: GridCanvas(
                      containerWidth: AppConstants.imageContainerWidth,
                      containerHeight: AppConstants.imageContainerHeight,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
