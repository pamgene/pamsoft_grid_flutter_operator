// ignore_for_file: avoid_print
import 'dart:io';

/// Updates lib/core/version/version_info.dart with the current git version.
///
/// Usage: dart run scripts/update_version.dart
///
/// This script will:
/// 1. Try to get the latest git tag
/// 2. If no tag exists, use the short commit hash
/// 3. Update version_info.dart with the version
void main() async {
  final gitVersion = await getGitVersion();
  final isTag = await isGitTag(gitVersion);

  print('Git version: $gitVersion (${isTag ? "tag" : "commit"})');

  final content = generateVersionInfo(gitVersion, isTag);
  final file = File('lib/core/version/version_info.dart');

  await file.writeAsString(content);
  print('Updated ${file.path}');
}

Future<String> getGitVersion() async {
  // Try to get the latest tag first
  var result = await Process.run('git', ['describe', '--tags', '--abbrev=0']);
  if (result.exitCode == 0) {
    return (result.stdout as String).trim();
  }

  // Fall back to short commit hash
  result = await Process.run('git', ['rev-parse', '--short', 'HEAD']);
  if (result.exitCode == 0) {
    return (result.stdout as String).trim();
  }

  return 'unknown';
}

Future<bool> isGitTag(String version) async {
  final result = await Process.run('git', ['tag', '-l', version]);
  return result.exitCode == 0 && (result.stdout as String).trim() == version;
}

String generateVersionInfo(String version, bool isTag) {
  final urlPath = isTag ? 'releases/tag/$version' : 'commit/$version';

  return '''/// Version information for the INFO section.
///
/// These values are populated by the scripts/update_version.dart script.
/// Run `dart run scripts/update_version.dart` before building to update.
class VersionInfo {
  VersionInfo._();

  /// GitHub repository URL
  static const String gitRepo = 'https://github.com/tercen/pamsoft_grid_flutter_operator';

  /// Git tag or short commit hash (for display)
  static const String gitVersion = '$version';

  /// Full URL to the release/commit on GitHub
  static String get gitReleaseUrl => '\$gitRepo/$urlPath';
}
''';
}
