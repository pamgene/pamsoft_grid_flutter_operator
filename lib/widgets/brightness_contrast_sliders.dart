import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pamsoft_grid_flutter_operator/providers/settings_provider.dart';
import 'package:pamsoft_grid_flutter_operator/utils/constants.dart';

/// Brightness slider widget (compact single-row layout).
class BrightnessSlider extends StatelessWidget {
  const BrightnessSlider({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settingsProvider, child) {
        return _CompactSlider(
          label: 'Brightness',
          value: settingsProvider.brightness,
          min: AppConstants.minBrightness,
          max: AppConstants.maxBrightness,
          divisions: 100,
          format: (v) => v.toStringAsFixed(2),
          onChanged: settingsProvider.setBrightness,
        );
      },
    );
  }
}

/// Contrast slider widget (compact single-row layout).
class ContrastSlider extends StatelessWidget {
  const ContrastSlider({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settingsProvider, child) {
        return _CompactSlider(
          label: 'Contrast',
          value: settingsProvider.contrast,
          min: AppConstants.minContrast,
          max: AppConstants.maxContrast,
          divisions: 76,
          format: (v) => v.toStringAsFixed(1),
          onChanged: settingsProvider.setContrast,
        );
      },
    );
  }
}

/// Compact slider: label, thin-track slider, and value in a single row.
class _CompactSlider extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String Function(double) format;
  final ValueChanged<double> onChanged;

  const _CompactSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.format,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        SizedBox(
          width: 64,
          child: Text(label, style: theme.textTheme.labelSmall),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 2,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
              padding: EdgeInsets.zero,
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: divisions,
              onChanged: onChanged,
            ),
          ),
        ),
        SizedBox(
          width: 34,
          child: Text(
            format(value),
            style: theme.textTheme.labelSmall,
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}
