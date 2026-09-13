import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pamsoft_grid_flutter_operator/providers/grid_provider.dart';
import 'package:pamsoft_grid_flutter_operator/utils/block_slice.dart';

/// New Grid, and the finishing action.
///
/// The finishing button has three states and never goes back to the first:
///
/// | state  | label               | why                                        |
/// |--------|---------------------|--------------------------------------------|
/// | ready  | Save and finish     | saves every grid and completes the step    |
/// | saving | Saving grids, n/N   | disabled; the tab-close guard is armed     |
/// | done   | Step complete       | disabled; the user can close the window    |
///
/// It used to read "Run", show a spinner, and then read "Run" again after a
/// successful save — which users read as "nothing happened".
class ActionButtons extends StatelessWidget {
  const ActionButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GridProvider>(
      builder: (context, gridProvider, child) {
        final busy = gridProvider.isSaving || gridProvider.isDone;
        final modified = gridProvider.modifiedCount;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 32,
                    child: OutlinedButton(
                      onPressed: busy
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
                  flex: 2,
                  child: SizedBox(
                    height: 32,
                    child: _FinishButton(gridProvider: gridProvider),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                _statusLine(gridProvider, modified),
                style: TextStyle(
                  fontSize: 11,
                  color: gridProvider.isDone
                      ? Colors.green.shade700
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            if (gridProvider.error != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  gridProvider.error!,
                  style: const TextStyle(color: Colors.red, fontSize: 11),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        );
      },
    );
  }

  static String _statusLine(GridProvider p, int modified) {
    switch (p.saveState) {
      case SaveState.done:
        return 'Grids saved. You can close this window.';
      case SaveState.saving:
        return p.saveProgress?.phase ?? 'Saving grids…';
      case SaveState.failed:
        return 'Save failed. Fix the problem and try again.';
      case SaveState.idle:
        return modified == 0
            ? 'No grid modified. Finishing accepts the automatic grids as they are.'
            : '$modified grid${modified == 1 ? '' : 's'} modified';
    }
  }
}

class _FinishButton extends StatelessWidget {
  final GridProvider gridProvider;
  const _FinishButton({required this.gridProvider});

  @override
  Widget build(BuildContext context) {
    final state = gridProvider.saveState;
    final style = ElevatedButton.styleFrom(
      backgroundColor: Colors.green,
      foregroundColor: Colors.white,
      disabledBackgroundColor:
          state == SaveState.done ? Colors.green.shade700 : Colors.grey.shade400,
      disabledForegroundColor: Colors.white,
      padding: EdgeInsets.zero,
      textStyle: const TextStyle(fontSize: 12),
    );

    switch (state) {
      case SaveState.saving:
        final p = gridProvider.saveProgress;
        final label = p != null && p.total > 0
            ? 'Saving grids, ${p.done} of ${p.total}'
            : 'Saving grids…';
        return ElevatedButton(
          onPressed: null,
          style: style,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              ),
              const SizedBox(width: 8),
              Text(label),
            ],
          ),
        );
      case SaveState.done:
        return ElevatedButton.icon(
          onPressed: null,
          style: style,
          icon: const Icon(Icons.check, size: 16),
          label: const Text('Step complete'),
        );
      case SaveState.idle:
      case SaveState.failed:
        return Tooltip(
          message: gridProvider.isLoadingAllGrids
              ? 'Grid data is still loading; saving waits for it to finish'
              : 'Saves all grids and completes the step',
          child: ElevatedButton(
            onPressed: () => gridProvider.finishAndSave(),
            style: style,
            child: Text(state == SaveState.failed ? 'Retry save and finish' : 'Save and finish'),
          ),
        );
    }
  }
}
