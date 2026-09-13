import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pamsoft_grid_flutter_operator/providers/grid_provider.dart';
import 'package:pamsoft_grid_flutter_operator/providers/image_selection_provider.dart';
import 'package:pamsoft_grid_flutter_operator/utils/review_progress.dart';
import 'package:pamsoft_grid_flutter_operator/utils/block_slice.dart';

/// New Grid, and the finishing action.
///
/// The finishing button has three states and never goes back to the first:
///
/// | state  | label               | why                                        |
/// |--------|---------------------|--------------------------------------------|
/// | ready  | Save and finish     | saves every grid and completes the step    |
/// | saving | Saving…             | grey, inert; phase in the line below       |
/// | done   | Step complete       | grey chip, not a button; window can close  |
///
/// It used to read "Run", show a spinner, and then read "Run" again after a
/// successful save — which users read as "nothing happened".
class ActionButtons extends StatelessWidget {
  const ActionButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<GridProvider, ImageSelectionProvider>(
      builder: (context, gridProvider, imageProvider, child) {
        final busy = gridProvider.isSaving || gridProvider.isDone;
        final progress = gridProvider.progress(imageProvider.gridImageCount);
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
                    child: _FinishButton(
                      gridProvider: gridProvider,
                      progress: progress,
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                _statusLine(gridProvider, progress),
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

  static String _statusLine(GridProvider p, ReviewProgress progress) {
    switch (p.saveState) {
      case SaveState.done:
        return 'Grids saved. You can close this window.';
      case SaveState.saving:
        return p.saveProgress?.phase ?? 'Saving…';
      case SaveState.failed:
        return 'Save failed. Fix the problem and try again.';
      case SaveState.idle:
        return progress.readyLine();
    }
  }
}

class _FinishButton extends StatelessWidget {
  final GridProvider gridProvider;
  final ReviewProgress progress;
  const _FinishButton({required this.gridProvider, required this.progress});

  /// Finishing with grids nobody opened is allowed, but not by accident.
  Future<void> _finish(BuildContext context) async {
    if (progress.needsConfirmation) {
      final go = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(progress.confirmationTitle),
          content: Text(progress.confirmationBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Keep checking'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: FilledButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('Finish anyway'),
            ),
          ],
        ),
      );
      if (go != true) return;
    }
    await gridProvider.finishAndSave();
  }

  @override
  Widget build(BuildContext context) {
    final state = gridProvider.saveState;
    final scheme = Theme.of(context).colorScheme;

    switch (state) {
      case SaveState.saving:
        // Grey and inert. No count on the button: "2 of 3" read as grids.
        // The phase is spelled out in the status line underneath.
        return _InertChip(
          background: Colors.grey.shade400,
          foreground: Colors.white,
          leading: const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          ),
          label: 'Saving…',
        );
      case SaveState.done:
        // Not a button any more: a neutral chip so nothing invites a click.
        return _InertChip(
          background: scheme.surfaceContainerHighest,
          foreground: scheme.onSurfaceVariant,
          leading: Icon(
            Icons.check_circle,
            size: 16,
            color: Colors.green.shade700,
          ),
          label: 'Step complete',
        );
      case SaveState.idle:
      case SaveState.failed:
        return Tooltip(
          message: gridProvider.isLoadingAllGrids
              ? 'Grid data is still loading; saving waits for it to finish'
              : 'Saves all grids and completes the step',
          child: ElevatedButton(
            onPressed: () => _finish(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: EdgeInsets.zero,
              textStyle: const TextStyle(fontSize: 12),
            ),
            child: Text(
              state == SaveState.failed
                  ? 'Retry save and finish'
                  : 'Save and finish',
            ),
          ),
        );
    }
  }
}

/// A button-sized, non-interactive status element.
class _InertChip extends StatelessWidget {
  final Color background;
  final Color foreground;
  final Widget leading;
  final String label;
  const _InertChip({
    required this.background,
    required this.foreground,
    required this.leading,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(4),
      ),
      alignment: Alignment.center,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          leading,
          const SizedBox(width: 8),
          Text(label, style: TextStyle(fontSize: 12, color: foreground)),
        ],
      ),
    );
  }
}
