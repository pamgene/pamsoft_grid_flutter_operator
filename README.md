# PS12 Grid Checker

A Flutter desktop/web application for quality control review of automated fiducial grid fitting on Pamstation experiment TIFF images.

## Usage

Click on the forward grid button to examine individual grids. In a previous step, gridding has been done by the `Grid_operator` for all cycles per array and exposure times. In each grid, the image with the latest cycle is shown. 
For `PTK_prewash`, IF needed, use the image button to review individual images within a grid. The names of these images appear under "Images".

There are 2 options to edit the grids:
* drag and drop an individual spot
* click on the side (not on the grid) and drag and drop the whole grid (all spots at once). Rotation is possible by holding the shift.

Editing automatically gets saved. When returning to the replaced grid, the replaced positions are kept.

When all the images have been reviewed, click on the Run button to save the changes.

### Image name explanation:
Example: `641070616_W1_F1_T100_P94_I493_A30.tif`

```
{barcode}_W{well (array)}_F{filter}_T{exposure time}_P{cycle}_I{image number}_A{temperature}.tif
```

## Details

Pamsoft Grid Checker is a QC tool designed for reviewing and adjusting the automated grid fitting performed on images from PamDx's Pamstation scientific instrument. The application allows operators to:

- View TIFF images and the automatically fitted grids 
- Manually adjust individual fiducial positions or the entire grid (drag-and-drop)
- Navigate between images of different wells and time points: with buttons or keyboard arrow keys
- Adjust image brightness and contrast for better visibility
- New Grid button replaces the current fitted grid with a hardcoded grid with uniform spot size, regular spacing, discarding any algorithm-fitted positions and diameters.
- use Light/Dark Theme

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
