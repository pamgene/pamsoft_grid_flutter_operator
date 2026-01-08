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
        return Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: gridProvider.isProcessing
                    ? null
                    : () => gridProvider.resetToDefaultGrid(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.green,
                  side: const BorderSide(color: Colors.green, width: 1.5),
                ),
                child: const Text('New Grid'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: gridProvider.isProcessing
                    ? null
                    : () => gridProvider.runProcessing(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: gridProvider.isProcessing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Run'),
              ),
            ),
          ],
        );
      },
    );
  }
}
