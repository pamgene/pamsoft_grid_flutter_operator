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
