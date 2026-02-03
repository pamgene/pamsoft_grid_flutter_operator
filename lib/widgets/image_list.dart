import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pamsoft_grid_flutter_operator/providers/image_selection_provider.dart';
import 'package:pamsoft_grid_flutter_operator/providers/settings_provider.dart';

/// Scrollable list of images for the current grid.
class ImageList extends StatelessWidget {
  const ImageList({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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

        return ListView.builder(
          itemCount: visibleIndices.length,
          itemBuilder: (context, index) {
            final imageIndex = visibleIndices[index];
            final image = images[imageIndex];
            final isSelected = imageIndex == selectedIndex;
            final isGridImage = image.isGridImage;

            return Tooltip(
              message: image.displayName,
              waitDuration: const Duration(milliseconds: 500),
              child: ListTile(
                dense: true,
                selected: isSelected,
                selectedTileColor: colorScheme.primaryContainer,
                leading: isGridImage
                    ? Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Center(
                          child: Text(
                            'G',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.onPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      )
                    : const SizedBox(width: 24),
                title: Text(
                  image.displayName,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.brightness == Brightness.dark
                        ? Colors.white
                        : colorScheme.onSurface,
                    fontWeight: isGridImage ? FontWeight.w600 : FontWeight.normal,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () {
                  imageProvider.setImageIndex(imageIndex);
                },
              ),
            );
          },
        );
      },
    );
  }
}
