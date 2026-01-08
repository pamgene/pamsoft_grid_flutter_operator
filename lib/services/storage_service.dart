/// Abstract interface for storage service.
abstract class StorageService {
  /// Gets brightness setting.
  double getBrightness();

  /// Sets brightness setting.
  void setBrightness(double value);

  /// Gets contrast setting.
  double getContrast();

  /// Sets contrast setting.
  void setContrast(double value);

  /// Gets current theme mode.
  bool isDarkMode();

  /// Sets theme mode.
  void setDarkMode(bool isDark);

  /// Gets current page size for image list.
  int getPageSize();

  /// Sets page size for image list.
  void setPageSize(int size);

  /// Clears all stored data.
  void clear();
}
