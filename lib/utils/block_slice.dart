import 'dart:math' as math;

/// A contiguous range of column indices (`.ci`) in the crosstab.
class CiRange {
  final int start;
  final int count;
  const CiRange(this.start, this.count);
  int get end => start + count; // exclusive
  bool contains(int ci) => ci >= start && ci < end;

  @override
  bool operator ==(Object other) =>
      other is CiRange && other.start == start && other.count == count;
  @override
  int get hashCode => Object.hash(start, count);
  @override
  String toString() => 'CiRange($start, $count)';
}

/// Physical row range of a crosstab select, as `offset` and `limit`.
class RowRange {
  final int offset;
  final int limit;
  const RowRange(this.offset, this.limit);
  int get end => offset + limit;

  @override
  bool operator ==(Object other) =>
      other is RowRange && other.offset == offset && other.limit == limit;
  @override
  int get hashCode => Object.hash(offset, limit);
  @override
  String toString() => 'RowRange(offset: $offset, limit: $limit)';
}

/// How the engine lays a crosstab out on disk, and what that lets us slice.
///
/// Sarno sorts every non-pairwise crosstab on `.cri`, a Morton code that puts
/// the column index `.ci` in the even bits and the row index `.ri` in the odd
/// bits (`endpoint/src/cube_query/z_order_processor.rs` + `sort_processor.rs`).
/// When the crosstab has at most 16 row variables, `.ri` only reaches code bits
/// 1, 3, 5 and 7, so every bit from 8 upwards comes from `.ci >> 4`: the table
/// is physically ordered by blocks of [blockCols] columns, Z-shuffled inside
/// each block. With one cell per (`.ci`, `.ri`) pair, block `b` occupies rows
/// `[b * 16 * nRi, (b + 1) * 16 * nRi)`.
///
/// One grid image is a run of consecutive columns (the column table is sorted
/// by its factors, image first), so its cells sit in one contiguous stretch of
/// whole blocks, padded by at most 15 neighbouring columns on each side. The
/// operator context's `select(offset, limit)` reads exactly that stretch — no
/// server-side filter needed. This is an implementation fact of the engine,
/// not an API contract, so callers verify what comes back with [sliceCovers]
/// and fall back to a full load if the layout is not what this predicts.
class MortonLayout {
  static const int blockCols = 16;

  /// Whether the block arithmetic applies: few enough row variables that the
  /// row index stays within the low byte of the Morton code, and a dense
  /// crosstab (every column carries every row variable).
  static bool canSlice({required int nRi, required int nCols, required int qtRows}) =>
      nRi > 0 && nRi <= blockCols && nCols > 0 && qtRows == nCols * nRi;

  /// The physical rows that hold every cell of the columns in [range]: the
  /// whole blocks covering it, clamped to the table.
  static RowRange blockRows(CiRange range, {required int nRi, required int nCols}) {
    if (range.count <= 0) return const RowRange(0, 0);
    final firstBlockCol = (range.start ~/ blockCols) * blockCols;
    final lastBlockEndCol = math.min(
        ((range.end - 1) ~/ blockCols + 1) * blockCols, nCols);
    return RowRange(firstBlockCol * nRi, (lastBlockEndCol - firstBlockCol) * nRi);
  }

  /// True when the rows returned for a block read contain every (`.ci`, `.ri`)
  /// of [range], exactly once each. Anything else means the physical layout is
  /// not the one predicted and the caller must not trust the slice.
  static bool sliceCovers(List<int> ci, List<int> ri, CiRange range, {required int nRi}) {
    if (ci.length != ri.length) return false;
    final seen = List<int>.filled(range.count * nRi, 0);
    for (var i = 0; i < ci.length; i++) {
      final c = ci[i];
      if (!range.contains(c)) continue; // padding from neighbouring columns
      final r = ri[i];
      if (r < 0 || r >= nRi) return false;
      final k = (c - range.start) * nRi + r;
      if (seen[k]++ != 0) return false;
    }
    for (final s in seen) {
      if (s != 1) return false;
    }
    return true;
  }
}

/// Splits `[0, total)` into consecutive chunks of at most [chunk] rows.
List<RowRange> chunkRows(int total, int chunk) {
  if (total <= 0 || chunk <= 0) return const [];
  final out = <RowRange>[];
  for (var offset = 0; offset < total; offset += chunk) {
    out.add(RowRange(offset, math.min(chunk, total - offset)));
  }
  return out;
}

/// Where a long load stands, for a determinate progress bar.
class LoadProgress {
  final String phase;
  final int done;
  final int total;
  const LoadProgress(this.phase, this.done, this.total);

  double? get fraction => total > 0 ? (done / total).clamp(0.0, 1.0) : null;
  bool get isComplete => total > 0 && done >= total;

  @override
  String toString() => 'LoadProgress($phase $done/$total)';
}

/// The finishing action's lifecycle. It never goes backwards from [done].
enum SaveState { idle, saving, done, failed }
