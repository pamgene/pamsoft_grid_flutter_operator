import 'package:flutter_test/flutter_test.dart';
import 'package:pamsoft_grid_flutter_operator/utils/review_progress.dart';

void main() {
  test('counts and lines on the 12 September dataset shape', () {
    const p = ReviewProgress(total: 192, viewed: 47, modified: 3);
    expect(p.unopened, 145);
    expect(p.allViewed, isFalse);
    expect(
      p.headerLine(11),
      'Grid 12 of 192  ·  47 viewed  ·  3 modified  ·  145 not yet opened',
    );
    expect(p.readyLine(), '3 grids modified  ·  145 not yet opened');
    expect(p.needsConfirmation, isTrue);
    expect(
      p.confirmationBody,
      '145 of 192 grids have not been opened. Their automatic grids will be saved as they are.',
    );
  });

  test('everything opened, nothing changed', () {
    const p = ReviewProgress(total: 5, viewed: 5, modified: 0);
    expect(p.unopened, 0);
    expect(p.allViewed, isTrue);
    expect(p.needsConfirmation, isFalse);
    expect(p.headerLine(4), 'Grid 5 of 5  ·  5 viewed  ·  0 modified');
    expect(p.readyLine(), contains('accepts the automatic grids'));
  });

  test('singular and zero forms', () {
    expect(
      const ReviewProgress(total: 3, viewed: 3, modified: 1).readyLine(),
      '1 grid modified',
    );
    expect(
      const ReviewProgress(total: 3, viewed: 1, modified: 0).readyLine(),
      'No grid modified  ·  2 not yet opened',
    );
    expect(
      const ReviewProgress(total: 0, viewed: 0, modified: 0).headerLine(0),
      'No grid images',
    );
  });

  test('viewed can never exceed total in the unopened count', () {
    const p = ReviewProgress(total: 3, viewed: 4, modified: 0);
    expect(p.unopened, 0);
    expect(p.needsConfirmation, isFalse);
  });
}
