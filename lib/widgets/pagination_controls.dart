import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pamsoft_grid_flutter_operator/providers/settings_provider.dart';
import 'package:pamsoft_grid_flutter_operator/utils/constants.dart';

/// Pagination controls for the image list.
class PaginationControls extends StatelessWidget {
  const PaginationControls({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settingsProvider, child) {
        return Row(
          children: [
            Text(
              'Show',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(width: 8),
            DropdownButton<int>(
              value: settingsProvider.pageSize,
              isDense: true,
              items: AppConstants.pageSizeOptions.map((size) {
                return DropdownMenuItem<int>(
                  value: size,
                  child: Text(
                    size == -1 ? 'All' : size.toString(),
                    style: const TextStyle(fontSize: 12),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  settingsProvider.setPageSize(value);
                }
              },
            ),
            const SizedBox(width: 8),
            Text(
              'entries',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        );
      },
    );
  }
}
