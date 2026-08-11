/// Operator properties declared in `operator.json` that this checker actually
/// consumes.
///
/// The upstream Shiny operator (`tercen/pamsoft_grid_shiny_operator`) declared
/// a larger set (Min/Max Diameter, Saturation Limit, Edge Sensitivity,
/// Segmentation Method, Rotation), but those drive the *gridding* operator, not
/// this viewer. Only the three below affect what the checker renders, so only
/// these are declared here.
class OperatorProperties {
  /// Consumed: half of `spotPitch * spotSize` is the drawn spot radius.
  /// A value of 0 means "auto-detect from the image dimensions" — see
  /// [resolveSpotPitch].
  final double spotPitch;

  /// Consumed: fraction of the pitch that a spot occupies.
  final double spotSize;

  /// Which image to select when a grid is opened.
  ///
  /// * `highest` — the highest-numbered cycle available (the default).
  /// * `grid` — the grid image itself, i.e. the pre-0.0.4 behaviour.
  /// * a number, e.g. `94` — that cycle, falling back to `highest` when the
  ///   cycle is not present for the selected grid.
  final String defaultCycle;

  const OperatorProperties({
    this.spotPitch = 0,
    this.spotSize = 0.66,
    this.defaultCycle = 'highest',
  });

  /// Property defaults, matching `operator.json`.
  static const OperatorProperties defaults = OperatorProperties();

  /// Resolves a spot pitch in image pixels.
  ///
  /// Shiny left `Spot Pitch` at 0 by default and detected the image set from
  /// the TIFF header (`get_imageset_type`): 552x413 is an Evolve3 and 697x520
  /// an Evolve2. A non-zero property always wins.
  ///
  /// Unknown dimensions fall back to the Evolve3 pitch rather than throwing —
  /// Shiny raised "Cannot automatically detect Spot Pitch", but aborting the
  /// whole viewer over a spot radius is a poor trade in a QC tool.
  static double resolveSpotPitch(
    double spotPitch,
    double imageWidth,
    double imageHeight,
  ) {
    if (spotPitch > 0) return spotPitch;
    if (imageWidth == 697 && imageHeight == 520) return 21.5; // Evolve2
    return 17.0; // Evolve3
  }

  @override
  String toString() => 'OperatorProperties(spotPitch: $spotPitch, '
      'spotSize: $spotSize, defaultCycle: $defaultCycle)';
}
