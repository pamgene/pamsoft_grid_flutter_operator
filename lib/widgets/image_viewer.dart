import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pamsoft_grid_flutter_operator/providers/settings_provider.dart';
import 'package:pamsoft_grid_flutter_operator/providers/image_selection_provider.dart';
import 'package:pamsoft_grid_flutter_operator/widgets/grid_canvas.dart';
import 'package:pamsoft_grid_flutter_operator/utils/image_filters.dart';
import 'package:pamsoft_grid_flutter_operator/utils/constants.dart';

/// Widget for displaying the TIFF/PNG image with grid overlay.
class ImageViewer extends StatelessWidget {
  const ImageViewer({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<ImageSelectionProvider, SettingsProvider>(
      builder: (context, imageProvider, settingsProvider, child) {
        final imageBytes = imageProvider.currentImageBytes;
        final isLoadingImage = imageProvider.isLoadingImage;
        final currentImage = imageProvider.currentImage;

        if (currentImage == null) {
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
                      child: _buildImage(imageBytes, isLoadingImage),
                    ),
                  ),
                  // Grid overlay - clipped to container bounds.
                  // LayoutBuilder captures the actual inner dimensions (excluding
                  // the Container's 1px border) so the grid scale matches the image.
                  Positioned.fill(
                    child: LayoutBuilder(
                      builder: (context, constraints) => GridCanvas(
                        containerWidth: constraints.maxWidth,
                        containerHeight: constraints.maxHeight,
                      ),
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

  Widget _buildImage(imageBytes, bool isLoading) {
    if (isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text(
              'Converting TIFF...',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      );
    }

    if (imageBytes != null) {
      return Image.memory(
        imageBytes,
        fit: BoxFit.fill,
        errorBuilder: (context, error, stackTrace) {
          return _buildErrorWidget();
        },
      );
    }

    return _buildErrorWidget();
  }

  Widget _buildErrorWidget() {
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
  }
}
