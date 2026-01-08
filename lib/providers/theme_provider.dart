import 'package:flutter/material.dart';
import 'package:pamsoft_grid_flutter_operator/di/service_locator.dart';
import 'package:pamsoft_grid_flutter_operator/services/storage_service.dart';

/// Provider for managing application theme (light/dark mode).
class ThemeProvider extends ChangeNotifier {
  final StorageService _storageService = locator<StorageService>();

  bool get isDarkMode => _storageService.isDarkMode();

  ThemeMode get themeMode => isDarkMode ? ThemeMode.dark : ThemeMode.light;

  /// Toggles between light and dark mode.
  void toggleTheme() {
    _storageService.setDarkMode(!isDarkMode);
    notifyListeners();
  }

  /// Sets the theme mode explicitly.
  void setDarkMode(bool isDark) {
    _storageService.setDarkMode(isDark);
    notifyListeners();
  }
}
