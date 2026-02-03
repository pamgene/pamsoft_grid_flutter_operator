/// Version information for the INFO section.
///
/// These values are populated by the scripts/update_version.dart script.
/// Run `dart run scripts/update_version.dart` before building to update.
class VersionInfo {
  VersionInfo._();

  /// GitHub repository URL
  static const String gitRepo = 'https://github.com/tercen/pamsoft_grid_flutter_operator';

  /// Git tag or short commit hash (for display)
  static const String gitVersion = '0.0.1';

  /// Full URL to the release/commit on GitHub
  static String get gitReleaseUrl => '$gitRepo/releases/tag/0.0.1';
}
