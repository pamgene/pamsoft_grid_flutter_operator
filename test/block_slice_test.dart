import 'package:flutter_test/flutter_test.dart';
import 'package:pamsoft_grid_flutter_operator/utils/block_slice.dart';

/// Reference Morton order, built the way the engine does it, so the block
/// arithmetic is checked against the real layout rather than against itself.
int morton(int ci, int ri) {
  var code = 0;
  for (var b = 0; b < 16; b++) {
    code |= ((ci >> b) & 1) << (2 * b);
    code |= ((ri >> b) & 1) << (2 * b + 1);
  }
  return code;
}

/// A dense crosstab of [nCols] x [nRi] cells in the engine's physical order.
(List<int>, List<int>) physicalOrder(int nCols, int nRi) {
  final cells = <(int, int)>[
    for (var c = 0; c < nCols; c++)
      for (var r = 0; r < nRi; r++) (c, r)
  ];
  cells.sort((a, b) => morton(a.$1, a.$2).compareTo(morton(b.$1, b.$2)));
  return ([for (final c in cells) c.$1], [for (final c in cells) c.$2]);
}

void main() {
  group('MortonLayout.canSlice', () {
    test('accepts a dense crosstab with up to 16 row variables', () {
      expect(MortonLayout.canSlice(nRi: 9, nCols: 509184, qtRows: 4582656), isTrue);
      expect(MortonLayout.canSlice(nRi: 16, nCols: 100, qtRows: 1600), isTrue);
    });
    test('rejects too many row variables, sparse tables and empty inputs', () {
      expect(MortonLayout.canSlice(nRi: 17, nCols: 100, qtRows: 1700), isFalse);
      expect(MortonLayout.canSlice(nRi: 9, nCols: 100, qtRows: 899), isFalse);
      expect(MortonLayout.canSlice(nRi: 0, nCols: 100, qtRows: 0), isFalse);
      expect(MortonLayout.canSlice(nRi: 9, nCols: 0, qtRows: 0), isFalse);
    });
  });

  group('MortonLayout.blockRows', () {
    test('covers whole 16-column blocks around the range', () {
      // Today's dataset shape: 2,652 spots per image, 9 variables.
      const nRi = 9, nCols = 509184;
      final r = MortonLayout.blockRows(const CiRange(2652, 2652), nRi: nRi, nCols: nCols);
      expect(r.offset, (2652 ~/ 16) * 16 * nRi); // 2640 * 9
      expect(r.end, ((5303 ~/ 16) + 1) * 16 * nRi); // 5312 * 9
      expect(r.limit, greaterThanOrEqualTo(2652 * nRi));
      expect(r.limit, lessThanOrEqualTo((2652 + 30) * nRi));
    });
    test('clamps to the table end and handles an empty range', () {
      expect(MortonLayout.blockRows(const CiRange(90, 10), nRi: 3, nCols: 100),
          const RowRange(80 * 3, 20 * 3));
      expect(MortonLayout.blockRows(const CiRange(5, 0), nRi: 3, nCols: 100),
          const RowRange(0, 0));
    });
  });

  group('against the engine order', () {
    test('a block read returns every cell of the image, and only padding besides',
        () {
      const nCols = 200, nRi = 9;
      final (ci, ri) = physicalOrder(nCols, nRi);
      for (final range in const [CiRange(0, 37), CiRange(37, 37), CiRange(150, 50), CiRange(199, 1)]) {
        final rows = MortonLayout.blockRows(range, nRi: nRi, nCols: nCols);
        final sliceCi = ci.sublist(rows.offset, rows.end);
        final sliceRi = ri.sublist(rows.offset, rows.end);
        expect(MortonLayout.sliceCovers(sliceCi, sliceRi, range, nRi: nRi), isTrue,
            reason: 'block rows must contain all of $range');
        // Padding is bounded by the block size on each side.
        for (final c in sliceCi) {
          expect(c, greaterThanOrEqualTo(range.start - 15));
          expect(c, lessThan(range.end + 15));
        }
      }
    });

    test('with more than 16 row variables the layout is NOT column-blocked', () {
      // The premise fails here, which is why canSlice refuses nRi > 16.
      const nCols = 64, nRi = 20;
      final (ci, ri) = physicalOrder(nCols, nRi);
      const range = CiRange(16, 16);
      final rows = MortonLayout.blockRows(range, nRi: nRi, nCols: nCols);
      expect(MortonLayout.canSlice(nRi: nRi, nCols: nCols, qtRows: nCols * nRi), isFalse);
      expect(
          MortonLayout.sliceCovers(
              ci.sublist(rows.offset, rows.end), ri.sublist(rows.offset, rows.end), range, nRi: nRi),
          isFalse);
    });
  });

  group('MortonLayout.sliceCovers', () {
    test('rejects a missing cell, a duplicate cell and a bad row index', () {
      const range = CiRange(4, 2);
      final ci = [4, 4, 5, 5], ri = [0, 1, 0, 1];
      expect(MortonLayout.sliceCovers(ci, ri, range, nRi: 2), isTrue);
      expect(MortonLayout.sliceCovers([4, 4, 5], [0, 1, 0], range, nRi: 2), isFalse);
      expect(MortonLayout.sliceCovers([4, 4, 5, 5], [0, 0, 0, 1], range, nRi: 2), isFalse);
      expect(MortonLayout.sliceCovers([4, 4, 5, 5], [0, 1, 0, 7], range, nRi: 2), isFalse);
      expect(MortonLayout.sliceCovers([4, 4, 5], [0, 1, 0, 1], range, nRi: 2), isFalse);
    });
    test('ignores padding columns outside the range', () {
      const range = CiRange(4, 1);
      expect(MortonLayout.sliceCovers([3, 4, 4, 5], [0, 0, 1, 1], range, nRi: 2), isTrue);
    });
  });

  group('chunkRows', () {
    test('splits into consecutive chunks with a short tail', () {
      expect(chunkRows(10, 4), const [RowRange(0, 4), RowRange(4, 4), RowRange(8, 2)]);
      expect(chunkRows(4, 4), const [RowRange(0, 4)]);
      expect(chunkRows(0, 4), isEmpty);
      expect(chunkRows(4, 0), isEmpty);
    });
  });

  group('LoadProgress', () {
    test('fraction and completion', () {
      expect(const LoadProgress('rows', 5, 10).fraction, 0.5);
      expect(const LoadProgress('rows', 10, 10).isComplete, isTrue);
      expect(const LoadProgress('rows', 0, 0).fraction, isNull);
      expect(const LoadProgress('rows', 12, 10).fraction, 1.0);
    });
  });
}
