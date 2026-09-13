# Pamsoft Grid Checker

A Flutter desktop/web application for quality control review of automated fiducial grid fitting on Pamstation experiment TIFF images.

## Overview

Pamsoft Grid Checker is a QC tool designed for reviewing and adjusting the automated grid fitting performed on images from PamGene's Pamstation scientific instrument. The application allows operators to:

- View TIFF images from Pamstation experiments
- Review the automatically fitted 14x14 peptide grid with reference fiducials
- Manually adjust individual fiducial positions or the entire grid
- Navigate between wells and time points within an experiment
- Adjust image brightness and contrast for better visibility
- Re-run grid fitting algorithms when needed

## Features

- **Grid Overlay Visualization**: Interactive display of fiducial grid overlaid on experiment images
- **Drag-and-Drop Adjustment**: Move individual fiducials or the entire grid by dragging
- **Image Controls**: Brightness (-0.5 to 0.5) and contrast (0.2 to 4.0) adjustment
- **Experiment Navigation**: Browse between grid images and associated time points
- **Status Tracking**: Visual indicators showing processed vs. modified grid status
- **Light/Dark Theme**: Toggle between light and dark mode
- **Keyboard Navigation**: Arrow keys for quick grid navigation

## Loading and saving (0.0.9)

The grid data lives in the step's crosstab: one column per spot per image, one
row per variable. On a large run (4.6 M cells) pulling all of it before the
first grid took tens of seconds while the image was already on screen.

- **First grid first.** The current grid image's cells are read as one
  contiguous block of the crosstab (the engine stores crosstabs in Morton
  order, so with at most 16 row variables an image's columns are one run of
  16-column blocks — see `lib/utils/block_slice.dart`). The block is verified
  cell by cell before it is trusted; if the layout is not what is predicted the
  app waits for the full load instead. Under a megabyte, about a second.
- **Everything else streams in behind it**, 250 k cells per request, two
  requests in flight, into flat typed arrays. A bar at the bottom of the image
  shows how far it is. Saving needs all of it (the output is one row per spot
  for every image); browsing does not.
- **Save and finish** replaces the old *Run* button. It saves every grid,
  modified or not, then waits for the platform to mark the step complete and
  shows *Step complete*. It never reverts to its initial label after a
  successful save, and the browser warns before the tab is closed while the
  upload is in flight. The line under it shows how many grids were modified.

## Review progress (0.0.10)

The header names the state of the grid on screen — **Not viewed** (blue
outline), **Viewed** (green) or **Modified** (amber) — and a line under it
reads e.g. `Grid 12 of 192 · 47 viewed · 3 modified · 145 not yet opened`.
"Viewed" means the grid image was opened in this session; there is no
per-grid approval. Until 0.0.10 an unopened grid was painted green.

The same counts appear under **Save and finish**. Finishing while grids
remain unopened asks first ("145 of 192 grids have not been opened. Their
automatic grids will be saved as they are.") with *Keep checking* as the
safe choice. Counts live in memory for the session.

Since 0.0.11 the result table is uploaded once, not twice: each column used
to carry its data in both `values` and the legacy `cValues` slot, and the
client serialises both. The server reads `values` only. On a 509 k-row
result this halves the upload (148 MB to 73 MB).

## Operator Settings

This operator declares ten properties. **Only three of them affect what the
checker does.** The rest are carried so that a workflow migrating from the
Shiny grid checker keeps its settings, and so they remain available to the
gridding operator upstream — but changing them here has no effect on this app.

| Property | Effect in this operator |
|---|---|
| `Default Cycle` | **Active.** Which image is selected when a grid is opened: `highest` (default), `grid`, or a cycle number. |
| `Spot Pitch` | **Active.** Distance between spot centres, in pixels. `0` auto-detects from the image dimensions (Evolve3 552x413 → 17.0, Evolve2 697x520 → 21.5). Used to size drawn spots where the data carries no measured diameter. |
| `Spot Size` | **Active.** Fraction of the pitch a spot occupies. Used with Spot Pitch as above. |
| `Min Diameter` | **No effect here.** Bounds spot segmentation in the *gridding* operator. |
| `Max Diameter` | **No effect here.** As above. |
| `Saturation Limit` | **No effect here.** Used by the gridding/quantification steps. |
| `EdgeSensitivityLow` | **No effect here.** Segmentation parameter for the gridding operator. |
| `Edge Sensitivity` | **No effect here.** As above. |
| `Segmentation Method` | **No effect here.** As above. |
| `Rotation` | **No effect here.** Template rotation range for the gridding operator. |

### Why the inactive properties exist

The checker displays a grid fit that has already happened — it does not run
spot segmentation. The seven properties marked "no effect here" are inputs to
that earlier fitting step.

They behaved the same way in the Shiny operator this replaces: it declared the
same properties, parsed most of them into memory, and never read them back.
Two of them (`EdgeSensitivityLow`, `Segmentation Method`) had no parsing branch
at all there. They are preserved here so nothing is lost in the migration, not
because they became functional.

If one of these should start affecting the checker, that is new work: the app
would have to re-run segmentation, which neither this operator nor the Shiny
one has ever done.

## Getting Started

### Prerequisites

- Flutter SDK (3.0 or higher)
- Dart SDK

### Installation

```bash
# Clone the repository
git clone https://github.com/tercen/pamsoft_grid_flutter_operator.git

# Navigate to project directory
cd pamsoft_grid_flutter_operator

# Install dependencies
flutter pub get

# Run on web
flutter run -d chrome

# Run on desktop (Windows)
flutter run -d windows
```

## Architecture

The application follows clean architecture principles with:

- **Presentation Layer**: Flutter widgets with Provider state management
- **Domain Layer**: Service abstractions defining business logic interfaces
- **Implementation Layer**: Concrete service implementations (mock for MVP, real for production)

## License

Proprietary - PamGene International B.V.
