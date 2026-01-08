import 'package:flutter/foundation.dart';
import 'package:pamsoft_grid_flutter_operator/di/service_locator.dart';
import 'package:pamsoft_grid_flutter_operator/services/storage_service.dart';

/// Provider for managing brightness, contrast, and pagination settings.
class SettingsProvider extends ChangeNotifier {
  final StorageService _storageService = locator<StorageService>();

  double get brightness => _storageService.getBrightness();
  double get contrast => _storageService.getContrast();
  int get pageSize => _storageService.getPageSize();

  /// Sets the brightness value.
  void setBrightness(double value) {
    _storageService.setBrightness(value);
    notifyListeners();
  }

  /// Sets the contrast value.
  void setContrast(double value) {
    _storageService.setContrast(value);
    notifyListeners();
  }

  /// Sets the page size for image list.
  void setPageSize(int size) {
    _storageService.setPageSize(size);
    notifyListeners();
  }
}
