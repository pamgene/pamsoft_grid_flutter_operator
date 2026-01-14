import 'dart:typed_data';
import 'package:image/image.dart' as img;

/// Utility class for converting 16-bit grayscale TIFF images to PNG.
///
/// This is specifically designed for Pamgene/Pamstation TIFF images which are
/// typically 12-bit grayscale data stored in 16-bit format.
class TiffConverter {
  /// Converts 16-bit grayscale TIFF bytes to PNG bytes.
  ///
  /// Returns the PNG-encoded bytes, or null if conversion fails.
  static Uint8List? tiffToPng(Uint8List tiffBytes) {
    try {
      final image = decode16BitGrayscaleTiff(tiffBytes);
      if (image == null) return null;

      final pngBytes = img.encodePng(image);
      return Uint8List.fromList(pngBytes);
    } catch (e) {
      print('TiffConverter.tiffToPng error: $e');
      return null;
    }
  }

  /// Manual decoder for 16-bit grayscale uncompressed TIFF.
  ///
  /// This handles the specific format used by Pamgene/Pamstation equipment
  /// where 12-bit data is stored in 16-bit containers.
  static img.Image? decode16BitGrayscaleTiff(Uint8List bytes) {
    try {
      // Check TIFF magic number (II for little-endian, MM for big-endian)
      if (bytes.length < 8) {
        print('TiffConverter: File too small');
        return null;
      }

      final byteOrder = bytes[0] == 0x49 ? Endian.little : Endian.big;
      final data = ByteData.sublistView(bytes);

      // Verify TIFF magic number (42)
      final magic = data.getUint16(2, byteOrder);
      if (magic != 42) {
        print('TiffConverter: Not a valid TIFF file (magic=$magic)');
        return null;
      }

      // Read IFD offset (at byte 4)
      final ifdOffset = data.getUint32(4, byteOrder);

      // Read number of directory entries
      final numEntries = data.getUint16(ifdOffset, byteOrder);

      int? width, height, bitsPerSample, rowsPerStrip;
      int stripOffsetsValue = 0;
      int stripOffsetsCount = 0;
      int stripOffsetsType = 0;

      // Parse IFD entries
      for (var i = 0; i < numEntries; i++) {
        final entryOffset = ifdOffset + 2 + (i * 12);
        final tag = data.getUint16(entryOffset, byteOrder);
        final type = data.getUint16(entryOffset + 2, byteOrder);
        final count = data.getUint32(entryOffset + 4, byteOrder);

        int value;
        if (type == 3) {
          // SHORT (2 bytes)
          value = data.getUint16(entryOffset + 8, byteOrder);
        } else {
          // LONG (4 bytes) or offset
          value = data.getUint32(entryOffset + 8, byteOrder);
        }

        switch (tag) {
          case 256: // ImageWidth
            width = value;
            break;
          case 257: // ImageLength (height)
            height = value;
            break;
          case 258: // BitsPerSample
            bitsPerSample = value;
            break;
          case 273: // StripOffsets
            stripOffsetsValue = value;
            stripOffsetsCount = count;
            stripOffsetsType = type;
            break;
          case 278: // RowsPerStrip
            rowsPerStrip = value;
            break;
        }
      }

      if (width == null || height == null) {
        print('TiffConverter: Missing required TIFF tags (width/height)');
        return null;
      }

      rowsPerStrip ??= height;

      // Read strip offsets array
      List<int> stripOffsets = [];
      if (stripOffsetsCount == 1) {
        stripOffsets.add(stripOffsetsValue);
      } else {
        // Value is offset to array
        final arrayOffset = stripOffsetsValue;
        for (var i = 0; i < stripOffsetsCount; i++) {
          if (stripOffsetsType == 3) {
            // SHORT
            stripOffsets.add(data.getUint16(arrayOffset + i * 2, byteOrder));
          } else {
            // LONG
            stripOffsets.add(data.getUint32(arrayOffset + i * 4, byteOrder));
          }
        }
      }

      // Create 8-bit grayscale image
      final image = img.Image(width: width, height: height, numChannels: 1);

      // Read strips and convert 16-bit to 8-bit
      var y = 0;
      for (var stripIndex = 0;
          stripIndex < stripOffsets.length && y < height;
          stripIndex++) {
        var pixelOffset = stripOffsets[stripIndex];
        final rowsInStrip =
            (y + rowsPerStrip > height) ? height - y : rowsPerStrip;

        for (var row = 0; row < rowsInStrip && y < height; row++, y++) {
          for (var x = 0; x < width; x++) {
            if (pixelOffset + 1 >= bytes.length) break;

            // Read 16-bit value (12-bit data stored in low bits)
            final value16 = data.getUint16(pixelOffset, byteOrder);
            // Convert 12-bit (0-4095) to 8-bit (0-255) by shifting right 4 bits
            final value8 = (value16 >> 4) & 0xFF;

            image.setPixelRgb(x, y, value8, value8, value8);
            pixelOffset += 2;
          }
        }
      }

      return image;
    } catch (e) {
      print('TiffConverter.decode16BitGrayscaleTiff error: $e');
      return null;
    }
  }
}
