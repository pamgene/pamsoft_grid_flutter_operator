import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pamsoft_grid_flutter_operator/providers/image_selection_provider.dart';

/// Grid navigation buttons for previous/next grid navigation.
class GridNavigationButtons extends StatelessWidget {
  const GridNavigationButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ImageSelectionProvider>(
      builder: (context, imageProvider, child) {
        return Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 30,
                child: ElevatedButton(
                  onPressed:
                      imageProvider.canGoPreviousGrid ? imageProvider.previousGrid : null,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                  child: const Text('<<Grid'),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: SizedBox(
                height: 30,
                child: ElevatedButton(
                  onPressed: imageProvider.canGoNextGrid ? imageProvider.nextGrid : null,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                  child: const Text('Grid>>'),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Image navigation buttons for previous/next image navigation.
class ImageNavigationButtons extends StatelessWidget {
  const ImageNavigationButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ImageSelectionProvider>(
      builder: (context, imageProvider, child) {
        return Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 30,
                child: ElevatedButton(
                  onPressed:
                      imageProvider.canGoPreviousImage ? imageProvider.previousImage : null,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                  child: const Text('<Image'),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: SizedBox(
                height: 30,
                child: ElevatedButton(
                  onPressed: imageProvider.canGoNextImage ? imageProvider.nextImage : null,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                  child: const Text('Image>'),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
