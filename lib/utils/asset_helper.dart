import 'dart:js_interop';
import 'package:web/web.dart' as web;

/// Helper class to resolve asset URLs correctly when embedded in Tercen.
///
/// When base href is commented out, Flutter's Image.asset cannot find assets.
/// This helper constructs the correct URL based on the current document location.
class AssetHelper {
  /// Gets the base URL for assets based on current document location.
  static String getAssetUrl(String assetPath) {
    // Get the current page URL and extract the base path
    final currentUrl = web.window.location.href;

    // Remove any query string or hash
    final baseUrl = currentUrl.split('?')[0].split('#')[0];

    // Remove 'index.html' if present, or ensure it ends with '/'
    String basePath;
    if (baseUrl.endsWith('index.html')) {
      basePath = baseUrl.substring(0, baseUrl.length - 10);
    } else if (baseUrl.endsWith('/')) {
      basePath = baseUrl;
    } else {
      basePath = '$baseUrl/';
    }

    // Construct full asset URL
    // Asset path is like 'assets/images/xxx.png'
    // We need to prepend 'assets/' if the path doesn't start with it
    String fullAssetPath = assetPath;
    if (!assetPath.startsWith('assets/')) {
      fullAssetPath = 'assets/$assetPath';
    }

    return '$basePath$fullAssetPath';
  }
}
