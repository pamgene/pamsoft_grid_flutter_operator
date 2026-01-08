import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pamsoft_grid_flutter_operator/providers/image_selection_provider.dart';
import 'package:pamsoft_grid_flutter_operator/providers/settings_provider.dart';

/// Scrollable list of images for the current grid.
class ImageList extends StatelessWidget {
  const ImageList({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<ImageSelectionProvider, SettingsProvider>(
      builder: (context, imageProvider, settingsProvider, child) {
        final images = imageProvider.currentGridImages;
        final selectedIndex = imageProvider.currentImageIndex;
        final pageSize = settingsProvider.pageSize;

        // Apply pagination
        List<int> visibleIndices;
        int startIndex = 0;
        int endIndex = images.length;

        if (pageSize > 0 && images.length > pageSize) {
          // For now, simple pagination showing first N items
          // Could be enhanced with proper page navigation
          endIndex = pageSize.clamp(0, images.length);
        }

        visibleIndices = List.generate(endIndex - startIndex, (i) => startIndex + i);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: visibleIndices.length,
                itemBuilder: (context, index) {
                  final imageIndex = visibleIndices[index];
                  final image = images[imageIndex];
                  final isSelected = imageIndex == selectedIndex;
                  final isGridImage = image.isGridImage;

                  return ListTile(
                    dense: true,
                    selected: isSelected,
                    selectedTileColor: Theme.of(context).colorScheme.primaryContainer,
                    leading: isGridImage
                        ? Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Center(
                              child: Text(
                                'G',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          )
                        : const SizedBox(width: 24),
                    title: Text(
                      image.displayName,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isGridImage ? FontWeight.bold : FontWeight.normal,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () {
                      imageProvider.setImageIndex(imageIndex);
                    },
                  );
                },
              ),
            ),
            // Pagination info
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Showing ${visibleIndices.length} of ${images.length} entries',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        );
      },
    );
  }
}
