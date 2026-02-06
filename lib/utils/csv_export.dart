import 'dart:convert';
import 'dart:js_interop';
import 'package:web/web.dart' as web;

/// Utility for exporting data to CSV files.
class CsvExport {
  /// Exports grid data to CSV file matching Shiny app format.
  ///
  /// Columns: .ci, gridX, gridY, grdXFixedPosition, grdYFixedPosition,
  ///          diameter, manual, bad, empty, grdRotation, grdImageNameUsed, Image
  static void exportGridData(
    List<Map<String, dynamic>> gridData,
    String filename,
  ) {
    if (gridData.isEmpty) {
      print('⚠️ No grid data to export');
      return;
    }

    print('📤 Exporting ${gridData.length} rows to CSV');

    // Build CSV content
    final buffer = StringBuffer();

    // Header row
    final headers = [
      '.ci',
      'gridX',
      'gridY',
      'grdXFixedPosition',
      'grdYFixedPosition',
      'diameter',
      'manual',
      'bad',
      'empty',
      'grdRotation',
      'grdImageNameUsed',
      'Image',
    ];
    buffer.writeln(headers.join(','));

    // Data rows
    for (int i = 0; i < gridData.length; i++) {
      final row = gridData[i];

      // Extract values (use 0 as default for missing numeric values)
      final ci = i; // Column index
      final gridX = row['gridX'] ?? 0.0;
      final gridY = row['gridY'] ?? 0.0;
      final grdXFixedPosition = row['grdXFixedPosition'] ?? gridX;
      final grdYFixedPosition = row['grdYFixedPosition'] ?? gridY;
      final diameter = row['diameter'] ?? 0.0;
      final manual = row['manual'] ?? 0;
      final bad = row['bad'] ?? 0;
      final empty = row['empty'] ?? 0;
      final grdRotation = row['grdRotation'] ?? 0.0;
      final grdImageNameUsed = row['grdImageNameUsed'] ?? '';
      final image = row['Image'] ?? '';

      // Format row
      final values = [
        ci.toString(),
        gridX.toString(),
        gridY.toString(),
        grdXFixedPosition.toString(),
        grdYFixedPosition.toString(),
        diameter.toString(),
        manual.toString(),
        bad.toString(),
        empty.toString(),
        grdRotation.toString(),
        '"$grdImageNameUsed"', // Quote string fields
        '"$image"',
      ];

      buffer.writeln(values.join(','));
    }

    final csvContent = buffer.toString();

    // Trigger download in browser
    _downloadFile(csvContent, filename);

    print('✓ CSV export complete: $filename');
  }

  /// Triggers a file download in the browser.
  static void _downloadFile(String content, String filename) {
    // Create data URL with base64-encoded CSV content
    final bytes = utf8.encode(content);
    final base64Content = base64Encode(bytes);
    final dataUrl = 'data:text/csv;base64,$base64Content';

    // Create download link
    final anchor = web.document.createElement('a') as web.HTMLAnchorElement
      ..href = dataUrl
      ..setAttribute('download', filename)
      ..style.display = 'none';

    // Add to document, click, and remove
    web.document.body?.appendChild(anchor);
    anchor.click();
    anchor.remove();
  }
}
