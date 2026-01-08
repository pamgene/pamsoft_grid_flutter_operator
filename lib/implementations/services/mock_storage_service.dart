import 'package:pamsoft_grid_flutter_operator/services/storage_service.dart';

/// Mock implementation of StorageService for development and testing.
///
/// Stores all values in memory (session only).
class MockStorageService implements StorageService {
  double _brightness = 0.0; // Default: 0 (range: -0.5 to 0.5)
  double _contrast = 1.0; // Default: 1 (range: 0.2 to 4.0)
  bool _isDarkMode = false; // Default: light mode
  int _pageSize = -1; // Default: -1 means "All"

  @override
  double getBrightness() => _brightness;

  @override
  void setBrightness(double value) {
    _brightness = value.clamp(-0.5, 0.5);
  }

  @override
  double getContrast() => _contrast;

  @override
  void setContrast(double value) {
    _contrast = value.clamp(0.2, 4.0);
  }

  @override
  bool isDarkMode() => _isDarkMode;

  @override
  void setDarkMode(bool isDark) {
    _isDarkMode = isDark;
  }

  @override
  int getPageSize() => _pageSize;

  @override
  void setPageSize(int size) {
    _pageSize = size;
  }

  @override
  void clear() {
    _brightness = 0.0;
    _contrast = 1.0;
    _isDarkMode = false;
    _pageSize = -1;
  }
}
