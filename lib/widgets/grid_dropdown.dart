import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pamsoft_grid_flutter_operator/providers/image_selection_provider.dart';

/// Dropdown selector for grid images.
class GridDropdown extends StatelessWidget {
  const GridDropdown({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ImageSelectionProvider>(
      builder: (context, imageProvider, child) {
        final gridImages = imageProvider.experimentData?.gridImages ?? [];
        final currentIndex = imageProvider.currentGridIndex;

        if (gridImages.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Grid Image',
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(height: 4),
            DropdownButtonFormField<int>(
              initialValue: currentIndex,
              isExpanded: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                isDense: true,
              ),
              items: gridImages.asMap().entries.map((entry) {
                return DropdownMenuItem<int>(
                  value: entry.key,
                  child: Text(
                    entry.value.displayName,
                    style: const TextStyle(fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (index) {
                if (index != null) {
                  imageProvider.setGridIndex(index);
                }
              },
            ),
          ],
        );
      },
    );
  }
}
