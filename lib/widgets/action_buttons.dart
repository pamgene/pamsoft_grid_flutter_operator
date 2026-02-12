import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pamsoft_grid_flutter_operator/providers/grid_provider.dart';

/// New Grid and Run action buttons.
class ActionButtons extends StatelessWidget {
  const ActionButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GridProvider>(
      builder: (context, gridProvider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 32,
                    child: OutlinedButton(
                      onPressed: gridProvider.isProcessing
                          ? null
                          : () => gridProvider.resetToDefaultGrid(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.green,
                        side: const BorderSide(color: Colors.green, width: 1.5),
                        padding: EdgeInsets.zero,
                        textStyle: const TextStyle(fontSize: 12),
                      ),
                      child: const Text('New Grid'),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SizedBox(
                    height: 32,
                    child: ElevatedButton(
                      onPressed: gridProvider.isProcessing
                          ? null
                          : () => gridProvider.runProcessing(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.zero,
                        textStyle: const TextStyle(fontSize: 12),
                      ),
                      child: gridProvider.isProcessing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Run'),
                    ),
                  ),
                ),
              ],
            ),
            if (gridProvider.error != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  gridProvider.error!,
                  style: const TextStyle(color: Colors.red, fontSize: 11),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        );
      },
    );
  }
}
