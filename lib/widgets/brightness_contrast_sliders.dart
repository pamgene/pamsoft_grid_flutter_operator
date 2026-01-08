import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pamsoft_grid_flutter_operator/providers/settings_provider.dart';
import 'package:pamsoft_grid_flutter_operator/utils/constants.dart';

/// Brightness slider widget.
class BrightnessSlider extends StatelessWidget {
  const BrightnessSlider({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settingsProvider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Brightness',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                Text(
                  settingsProvider.brightness.toStringAsFixed(2),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            Slider(
              value: settingsProvider.brightness,
              min: AppConstants.minBrightness,
              max: AppConstants.maxBrightness,
              divisions: 100,
              onChanged: (value) {
                settingsProvider.setBrightness(value);
              },
            ),
          ],
        );
      },
    );
  }
}

/// Contrast slider widget.
class ContrastSlider extends StatelessWidget {
  const ContrastSlider({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settingsProvider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Contrast',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                Text(
                  settingsProvider.contrast.toStringAsFixed(2),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            Slider(
              value: settingsProvider.contrast,
              min: AppConstants.minContrast,
              max: AppConstants.maxContrast,
              divisions: 76, // (4.0 - 0.2) / 0.05 = 76 steps
              onChanged: (value) {
                settingsProvider.setContrast(value);
              },
            ),
          ],
        );
      },
    );
  }
}
