import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pamsoft_grid_flutter_operator/providers/theme_provider.dart';

/// Theme toggle button for light/dark mode.
class ThemeToggle extends StatelessWidget {
  const ThemeToggle({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return IconButton(
          icon: Icon(
            themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
          ),
          tooltip: themeProvider.isDarkMode
              ? 'Switch to light mode'
              : 'Switch to dark mode',
          onPressed: () {
            themeProvider.toggleTheme();
          },
        );
      },
    );
  }
}
