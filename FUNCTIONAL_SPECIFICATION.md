# Pamsoft Grid Checker - Functional Specification v0.1.0

**Created:** 2026-01-07

**Version:** 0.1.0

**Status:** Draft

**Repository:** pamsoft_grid_flutter_operator

---

## Document Overview

This document specifies the functional requirements, user workflows, and UI/UX design for the **Pamsoft Grid Checker** application. This Flutter application replaces the existing Shiny application and serves as a quality control tool for reviewing automated fiducial grid fitting on TIFF images from Pamstation experiments.

---

## Product Overview

### Purpose

The **Pamsoft Grid Checker** is a quality control application used in the Pamstation image analysis pipeline. It allows users to manually review and adjust automated fiducial grid fitting results before downstream processing.

### Context

- **Scientific Instrument**: Pamstation (manufactured by Pamgene - https://pamgene.com/)
- **Pipeline Position**: Quality control step between automated grid fitting and downstream analysis
- **User Role**: Scientists/technicians performing manual QC review of automated results
- **Replacement**: Deprecates existing Shiny application with equivalent functionality in Flutter

### Key Value Proposition

- Manual quality control checkpoint for automated grid fitting
- Ability to correct algorithm errors through micro-adjustments
- Visual feedback on processing status
- Efficient navigation through multiple grid images
- Preservation of manual adjustments across navigation

---

## Version 0.1.0 Scope

Version 0.1.0 is a **Minimum Viable Product (MVP)** focused on replicating core Shiny application functionality with mock data.

### Goals
- Replicate Shiny app UI layout and core functionality
- Implement grid visualization with image overlay
- Enable whole-grid and individual fiducial dragging
- Provide navigation between grid images and time points
- Implement keyboard navigation (arrow keys for grid selection)
- Implement status tracking (Green/Yellow indicators)
- Support brightness/contrast adjustments (functional display adjustments)
- Implement light/dark mode theme switcher
- Simulate "Run" processing with mock delay
- Demonstrate architecture for future real backend integration
- Support web deployment (primary) and desktop execution

### Non-Goals (Deferred to Future Versions)
- Real backend API integration
- Actual algorithm execution
- File system integration for loading experiments
- Persistent storage/database
- Undo/redo functionality
- Advanced zoom/pan controls beyond browser native
- Unsaved changes warnings
- Multi-user or collaboration features
- Authentication/authorization

---

## User Workflows

### Primary Workflow: Grid Review and Adjustment

1. **Application Launch**
   - App opens with pre-loaded experiment data (simulated by mock service)
   - First grid image displayed (e.g., `641070511_W1_F1_T100_P95_A29`)
   - Grid overlay shown with algorithm's fitted positions
   - Status indicator shows **Green** (processed by algorithm)

2. **Review Grid Fit**
   - User visually inspects grid overlay against TIFF image bright spots
   - User adjusts brightness/contrast sliders if needed for better visibility

3. **Make Adjustments** (if needed)
   - **Option A: Whole Grid Adjustment**
     - Click image area (not on circles) and drag to move entire grid
     - Status indicator changes to **Yellow** (modified)

   - **Option B: Individual Fiducial Adjustment**
     - Click directly on a circle outline and drag to move that fiducial
     - Status indicator changes to **Yellow** (modified)

   - Adjustments are **automatically persisted** when navigating away

4. **Process Adjustments**
   - Click **"Run"** button to process the adjusted grid
   - 5-second processing delay (mock implementation)
   - Status indicator returns to **Green** (processed)
   - Grid coordinates saved for downstream processing

5. **Navigate to Next Grid**
   - Click **Grid>>** or select from Grid Image dropdown
   - Move to next Well/Field combination
   - Repeat steps 2-4 for all grid images

6. **Review Associated Time Points** (optional)
   - Use **Image>** / **<Image** to view other time points in the current Well/Field group
   - Fitted grid from Grid image is applied to all time points

### Secondary Workflow: Catastrophic Failure Recovery

1. User encounters grid that is completely misaligned (debris, equipment failure)
2. User clicks **"New Grid"** button
3. Default grid from control file is loaded (ignoring algorithm fit)
4. User performs manual re-gridding from scratch
5. User clicks **"Run"** to process the manually fitted grid

---

## UI/UX Requirements

### Application Layout

```
┌─────────────────────────────────────────────────────────────────┐
│ Pamsoft Grid Checker                              [Light/Dark] │
├──────────────────┬──────────────────────────────────────────────┤
│                  │                                              │
│  Left Panel      │         Main Image Display Area             │
│  (280-320px)     │                                              │
│                  │                                              │
│ ┌──────────────┐ │  ┌─────────────────────────────────────┐   │
│ │Grid Image ▾  │ │  │ [Status] Grid Image Filename        │   │
│ └──────────────┘ │  └─────────────────────────────────────┘   │
│                  │                                              │
│ [<<Grid] [Grid>>]│  ┌─────────────────────────────────────┐   │
│                  │  │                                       │   │
│ [<Image][Image>] │  │                                       │   │
│                  │  │        TIFF Image + Grid Overlay      │   │
│ ┌──────────────┐ │  │                                       │   │
│ │ Image List   │ │  │                                       │   │
│ │              │ │  │                                       │   │
│ │ [G] W1_F1... │ │  └─────────────────────────────────────┘   │
│ │     W1_F1_T10│ │                                              │
│ │     W1_F1_T25│ │  ┌─────────────────┐ ┌──────────────────┐  │
│ │     W1_F1_T5 │ │  │ Brightness: ━━◉━│ │ Contrast: ━━━◉━━ │  │
│ │     ...      │ │  └─────────────────┘ └──────────────────┘  │
│ │              │ │                                              │
│ └──────────────┘ │  [New Grid]                         [Run]   │
│                  │                                              │
│ Show [10▾] entries│                                             │
│ Showing 1-12 of 50│                                             │
│ [<] [1] [2] [>]  │                                              │
└──────────────────┴──────────────────────────────────────────────┘
```

### Left Panel Components

#### 1. Grid Image Dropdown
- **Label**: "Grid Image"
- **Function**: Select which Well/Field combination to review
- **Content**: List of all grid images in the experiment
- **Sorting**: Reverse time point order within each Well/Field group
- **Format**: `{ExperimentID}_{Well}_{Field}_{Time}_{Position}_{Image}_{Array}.tif`
- **Example**: `641070511_W1_F1_T100_P95_A29`

#### 2. Grid Navigation Buttons
- **<<Grid**: Navigate to previous grid image in dropdown
- **Grid>>**: Navigate to next grid image in dropdown
- **Layout**: Horizontal pair, full width of panel
- **Keyboard**: Left/Right arrow keys for grid navigation

#### 3. Image Navigation Buttons
- **<Image**: Navigate to previous image in image list
- **Image>**: Navigate to next image in image list
- **Layout**: Horizontal pair, full width of panel

#### 4. Image List Box
- **Function**: Display all images associated with current grid
- **Content**:
  - First item: Grid image with **"G"** badge
  - Remaining items: Other time points in reverse order (T50, T25, T10, T5)
- **Selection**: Single selection, highlights selected row
- **Click behavior**: Load selected image in main display area
- **Visual indicator**: Blue highlight for selected item

#### 5. Pagination Controls
- **Show Entries Dropdown**: Options: 10, 25, 50, 100, All
- **Display Label**: "Showing X to Y of Z entries"
- **Navigation**: Previous/Next buttons, page numbers
- **Default**: Show All

### Header Bar Components

#### 1. Application Title

- **Text**: "Pamsoft Grid Checker"
- **Position**: Left side of header
- **Style**: Bold, prominent font size

#### 2. Theme Toggle (Light/Dark Mode)

- **Position**: Right side of header (top-right corner)
- **Component**: Icon button or toggle switch
- **Icons**: Sun icon (light mode) / Moon icon (dark mode)
- **Behavior**: Click to toggle between light and dark themes
- **Persistence**: Session only (resets to default on app restart)
- **Default**: Light mode (or follow system preference)

### Main Display Area Components

#### 1. Grid Image Title Bar
- **Position**: Above image viewer
- **Content**:
  - Status indicator (colored square)
  - Grid image filename
- **Format**: `[●] {filename}.tif`
- **Colors**:
  - Green square: Processed (Run completed)
  - Yellow square: Modified (adjustments made, not yet run)
- **Example**: `[●] 641070511_W1_F1_T100_P95_A29.tif`

#### 2. Image Viewer Canvas
- **Function**: Display TIFF image with interactive grid overlay
- **Size**: Responsive, fills available space
- **Background**: Black
- **Image rendering**: TIFF displayed with adjustable brightness/contrast

#### 3. Grid Overlay
- **Fiducial markers**: Drawn as circle outlines (unfilled)
- **Color**: Green
- **Components**:
  - 196 peptide spots (14×14 grid)
  - ~8 reference fiducials positioned around edges
- **Interactive**: All circles are draggable

#### 4. Brightness Slider
- **Label**: "Brightness"
- **Range**: -0.5 to 0.5
- **Default**: 0
- **Persistence**: Global for session, resets on app restart

#### 5. Contrast Slider
- **Label**: "Contrast"
- **Range**: 0.2 to 4.0
- **Default**: 1
- **Persistence**: Global for session, resets on app restart

#### 6. New Grid Button
- **Label**: "New Grid"
- **Color**: Green
- **Function**: Load fresh grid from control file, discarding algorithm fit
- **Use case**: Catastrophic fitting failures

#### 7. Run Button
- **Label**: "Run"
- **Color**: Green
- **Function**: Process current grid adjustments
- **Behavior**:
  - Show 5-second processing delay (mock)
  - Change status from Yellow → Green
  - Save grid coordinates (mock)

---

## Feature Specifications

### Feature 1: Grid Overlay Visualization

**Description**: Display fiducial grid overlay on TIFF images

**Components**:
- Parse control file (`Array Layout.txt`) to get grid positions
- Render circles at specified Row/Col coordinates with Xoff/Yoff
- Apply algorithm-fitted adjustments (mock data in v0.1.0)

**Visual Specifications**:
- Circle color: Green (#00FF00 or similar)
- Circle style: Outline only (stroke, no fill)
- Circle radius: ~3-5 pixels (adjust for visibility)
- Line width: 1-2 pixels

**Data Source** (v0.1.0):
- Mock grid coordinates based on sample control file
- 196 peptide positions + 8 reference fiducials

---

### Feature 2: Grid Interaction - Whole Grid Dragging

**Description**: User can drag entire grid as a unit

**Interaction Model**:
- **Trigger**: Mouse down on image canvas (not on circle outline)
- **Action**:
  - Mouse drag moves entire grid
  - All fiducials move together maintaining relative positions
- **Visual Feedback**:
  - Grid follows cursor during drag
  - Status indicator changes to Yellow
- **Persistence**: Position automatically saved when navigating away

**Technical Notes**:
- Track grid offset (dx, dy) from original position
- Apply offset to all fiducial coordinates when rendering

---

### Feature 3: Grid Interaction - Individual Fiducial Dragging

**Description**: User can drag individual fiducials independently

**Interaction Model**:
- **Trigger**: Mouse down on circle outline
- **Hit Detection**: Click must be on/near the circle stroke (not inside or far outside)
- **Action**:
  - Mouse drag moves only that specific fiducial
  - Other fiducials remain fixed
- **Visual Feedback**:
  - Circle follows cursor during drag
  - Status indicator changes to Yellow (if not already)
- **Persistence**: Position automatically saved when navigating away

**Technical Notes**:
- Track individual fiducial offsets separately
- Hit detection radius: ~5-10 pixels from circle center

---

### Feature 4: Status Tracking

**Description**: Visual indicator of grid processing state

**Status States**:

| Status | Color | Meaning |
|--------|-------|---------|
| Processed | Green | Grid has been run through algorithm or user clicked Run |
| Modified | Yellow | User has made manual adjustments, not yet processed |

**State Transitions**:
- App loads → Green (default)
- User drags grid/fiducial → Yellow
- User clicks Run → Green
- User navigates away/back → Status preserved

**Visual Representation**:
- Small colored square (10-15px) in title bar
- Positioned before filename

---

### Feature 5: Navigation Between Grid Images

**Description**: Navigate between different Well/Field combinations

**Navigation Methods**:
1. **Grid Image Dropdown**: Click and select from list
2. **<<Grid Button**: Move to previous grid image
3. **Grid>>Button**: Move to next grid image

**Behavior**:
- Load new grid image and associated image list
- Load grid coordinates (algorithm fit + any saved adjustments)
- Preserve brightness/contrast settings
- Reset image list selection to Grid image (top of list)

**Dropdown Content**:
- All Well/Field combinations from experiment
- Sorted by Well (W1, W2, W3, W4), then Field (F1, F2, F3...)
- Time point sorted in reverse order (T100, T50, T25, T10, T5)

---

### Feature 6: Navigation Between Time Points

**Description**: Navigate between time points within current Well/Field group

**Navigation Methods**:
1. **Image List**: Click on any image in the list
2. **<Image Button**: Move to previous image in list
3. **Image> Button**: Move to next image in list

**Behavior**:
- Load selected TIFF image
- Apply current grid coordinates (from Grid image)
- Preserve brightness/contrast settings
- Highlight selected row in image list

**Grid Application**:
- Grid fitted on the Grid image (marked with "G") applies to all time points
- User cannot adjust grid on non-Grid images
- Non-Grid images are for review only

---

### Feature 7: Brightness and Contrast Adjustment

**Description**: Adjust image display for better visibility

**Brightness Control**:

- Slider range: -0.5 to 0.5
- Default: 0
- Effect: Additive adjustment to pixel values
- Persistence: Global for session

**Contrast Control**:

- Slider range: 0.2 to 4.0
- Default: 1
- Effect: Multiplicative adjustment to pixel values
- Persistence: Global for session

**Behavior**:
- Adjustments apply to currently displayed image
- Settings preserved when navigating between images
- Settings reset to default on app restart
- Does not affect saved TIFF files, only display

---

### Feature 8: Run Processing

**Description**: Process adjusted grid coordinates

**Button Behavior**:
- Click "Run" button
- Display processing state (5-second delay for mock)
- Status indicator: Yellow → Green
- (Future) Save coordinates to output file

**Mock Implementation**:
- Show loading spinner or progress indicator
- Delay for 5 seconds
- Update status state
- Log mock output data to console

**Real Implementation** (Future):
- Run algorithm with manual adjustments as input
- Generate output data file with grid coordinates
- Apply fitted grid to all time points in group
- Save for downstream processing

---

### Feature 9: New Grid Reset

**Description**: Load fresh grid from control file

**Button Behavior**:
- Click "New Grid" button
- Discard all adjustments (both algorithm and manual)
- Load default grid from control file (Row, Col, Xoff, Yoff)
- Status remains current state (or resets to Yellow?)

**Use Case**:
- Catastrophic algorithm failure
- Debris or equipment issues causing misalignment
- User wants to start from scratch

**Confirmation** (Optional Future Enhancement):
- Show warning dialog before discarding adjustments
- "Are you sure? This will discard all adjustments."

---

### Feature 10: Light/Dark Mode Theme

**Description**: Toggle between light and dark color themes

**Toggle Behavior**:

- Click theme toggle button in top-right header
- Instantly switch between light and dark themes
- All UI components update to match selected theme

**Light Mode** (Default):

- Light background colors
- Dark text
- Standard Material Design light palette

**Dark Mode**:

- Dark background colors
- Light text
- Standard Material Design dark palette

**Persistence**:

- Theme preference stored for session only
- Resets to light mode (default) on app restart
- Future enhancement: persist preference in local storage

**Components Affected**:

- Header bar
- Left panel background and text
- Image list styling
- Buttons and controls
- Sliders and dropdowns
- Image viewer background (remains black in both modes for contrast)

---

### Feature 11: Pagination

**Description**: Manage display of large image lists

**Show Entries Dropdown**:
- Options: 10, 25, 50, 100, All
- Default: All
- Controls items per page in image list

**Pagination Controls**:
- Previous/Next buttons
- Page number buttons (1, 2, 3...)
- Display label: "Showing X to Y of Z entries"

**Behavior**:
- Only affects image list display
- Does not affect grid dropdown
- Selection preserved when changing pages

---

## Data Requirements

### Input Data

#### 1. Experiment Folder Structure
```
Experiment_Name/
├── {ExperimentID}_{etc} Array Layout.txt   # Control file
└── ImageResults/
    ├── {ExperimentID}_W1_F1_T100_P95_A29.tif
    ├── {ExperimentID}_W1_F1_T10_P95_A29.tif
    ├── {ExperimentID}_W1_F1_T25_P95_A29.tif
    └── ... (1000+ TIFF files)
```

#### 2. Control File Format
Tab-separated text file with columns:
- `Row`: Grid row number (-6 to 14)
- `Col`: Grid column number (-20 to 14)
- `ID`: Peptide identifier (e.g., "EFS_246_258") or "#REF" for reference fiducials
- `Sequence`: Peptide sequence (or "NA" for reference)
- `Tyr`: Tyrosine positions in sequence
- `UniprotAccession`: Protein database identifier
- `Xoff`: X-axis offset for grid position
- `Yoff`: Y-axis offset for grid position

**Example Lines**:
```
Row	Col	ID	Sequence	Tyr	UniprotAccession	Xoff	Yoff
-1	-1	#REF	NA	NA	NA	0	0
1	1	EFS_246_258	GGTDEGIYDVPLL	[253]	O43281	0	0
```

#### 3. TIFF Image Files
- Format: `.tif` or `.tiff`
- Naming convention: `{ExperimentID}_{Well}_{Field}_{Time}_{Position}_{Image}_{Array}.tif`
- Components:
  - **ExperimentID**: Unique run identifier (e.g., 641070511)
  - **Well**: W1, W2, W3, W4
  - **Field**: F1, F2, F3, ...
  - **Time**: T5, T10, T25, T50, T100 (minutes)
  - **Position**: P32-P95 (varies)
  - **Image**: I1-I480+ (sequential)
  - **Array**: A29, A30

**Example**: `641070511_W1_F1_T100_P95_A29.tif`

#### 4. Algorithm Fitted Grid Coordinates (Future)
Format TBD - likely JSON or CSV with:
- Image identifier
- Fiducial positions (x, y coordinates for each spot)
- Fit quality metrics (optional)

### Output Data

#### 1. Adjusted Grid Coordinates (Future)
Format TBD - likely JSON or CSV with:
- Image identifier
- Adjusted fiducial positions
- Modification timestamp
- User identifier (optional)
- Status (processed/pending)

### Mock Data (v0.1.0)

For the MVP, use sample data from `PTK_3project.zip`:
- Control file: `641070704_641070619_641070620 86412 Array Layout.txt`
- TIFF files: 1,584 images from `ImageResults/` folder
- Mock grid coordinates: Generate from control file + random offsets to simulate algorithm fit

---

## UI Component Specifications

### Grid Image Dropdown
- **Component**: Dropdown select
- **Width**: Full panel width
- **Max height**: 300px (scrollable)
- **Item format**: Filename without extension
- **Selection**: Single selection, highlights current grid

### Navigation Buttons
- **Style**: Secondary/outlined buttons
- **Size**: Medium
- **Layout**: Horizontal pairs with small gap
- **Disabled state**: Gray out when at start/end of list

### Image List
- **Component**: Scrollable list with single selection
- **Item height**: 30-40px
- **Badge**: "G" badge on first item (Grid image)
- **Badge style**: Small, circular or rectangular, contrasting color
- **Selection highlight**: Blue background
- **Hover state**: Light gray background

### Status Indicator
- **Shape**: Square
- **Size**: 12-15px
- **Colors**:
  - Green: `#00FF00` or Material Green
  - Yellow: `#FFFF00` or Material Amber
- **Position**: Inline before filename in title bar

### Sliders
- **Style**: Material Design sliders
- **Track height**: 4px
- **Thumb size**: 12px
- **Labels**: Show current value
- **Width**: 200-300px

### Action Buttons
- **Style**: Contained buttons
- **Color**: Green (Material Green or custom)
- **Size**: Medium to Large
- **Layout**: "New Grid" left-aligned, "Run" right-aligned

---

## User Experience Specifications

### Interaction Feedback

1. **Button Hover**: Slight color change or elevation
2. **Button Click**: Ripple effect (Material Design)
3. **Dragging Grid**: Smooth movement, low latency
4. **Processing**: Loading spinner or progress bar during "Run"
5. **Navigation**: Smooth transitions between images

### Loading States

1. **Initial Load**: Show loading spinner while loading experiment data
2. **Image Load**: Show placeholder while TIFF loads
3. **Run Processing**: Show "Processing..." message and disable controls

### Error States

1. **Failed Image Load**: Show error message in image area
2. **Invalid Grid Coordinates**: Show warning message
3. **Navigation Errors**: Gracefully handle missing images

### Responsive Behavior

1. **Minimum Width**: 1024px (primary desktop/web target)
2. **Panel Resize**: Left panel fixed width, main area flexible
3. **Image Scaling**: TIFF scales to fit available space, maintains aspect ratio

---

## Accessibility Requirements

1. **Keyboard Navigation**: Support tab navigation and arrow keys
2. **Screen Reader**: Proper ARIA labels on interactive elements
3. **Color Contrast**: Ensure status indicators meet WCAG standards
4. **Focus Indicators**: Visible focus states on all interactive elements

---

## Technical Constraints

### Platform Support
- **Primary**: Web (Chrome, Firefox, Edge, Safari)
- **Secondary**: Desktop (Windows, macOS, Linux via Flutter)
- **Not Required**: Mobile (phone/tablet)

### Performance Targets
- **Image Load Time**: < 2 seconds for TIFF display
- **Grid Rendering**: 60fps during drag operations
- **Navigation**: < 500ms to switch between images
- **Memory**: Handle 1000+ images without performance degradation

### Browser Compatibility
- **Minimum**: Modern browsers with ES6+ support
- **TIFF Rendering**: Use appropriate library (e.g., tiff.js, Flutter image package)
- **Canvas/WebGL**: May be needed for efficient grid overlay

---

## Mock Implementation Details (v0.1.0)

### Mock Services Required

1. **MockImageService**
   - Load image list from bundled PNG assets
   - Parse filenames to extract metadata
   - Group images by ExperimentID_Well_Field
   - Identify Grid images (last time point per group)
   - Cycle through 3 sample images for display variety

2. **MockGridService**
   - Parse control file to get grid structure
   - Generate mock algorithm-fitted coordinates (control file + small random offsets)
   - Store manual adjustments in memory
   - Simulate "Run" processing with 5-second delay

3. **MockStorageService**
   - Store grid adjustments in memory (session only)
   - Track status states (Green/Yellow) per grid image
   - Store brightness/contrast settings globally
   - Store theme preference (light/dark)

### Sample Images (Pre-converted PNG)

Three sample images converted from TIFF to PNG for mock implementation:

| Filename                                 | Time Point | Purpose                        |
| ---------------------------------------- | ---------- | ------------------------------ |
| `641070511_W1_F1_T100_P94_I473_A29.png`  | T100       | Brightest (Grid image example) |
| `641070511_W1_F1_T50_P94_I472_A29.png`   | T50        | Medium brightness              |
| `641070511_W1_F1_T5_P94_I469_A29.png`    | T5         | Dimmest                        |

**Location**: `assets/images/`

**Usage**: These 3 images are reused/cycled for all mock image displays. They do not need to match the actual experiment data exactly - they demonstrate visual changes when navigating.

### Brightness/Contrast Implementation

The brightness and contrast sliders provide **functional display adjustments**:

**Brightness** (Range: -0.5 to 0.5, Default: 0):

- Additive adjustment to pixel values
- Positive values make the image lighter, negative values make it darker
- Implementation: Apply color filter or shader to image widget

**Contrast** (Range: 0.2 to 4.0, Default: 1):

- Multiplicative adjustment to pixel values
- Values > 1 increase contrast, values < 1 decrease contrast
- Implementation: Apply color filter or shader to image widget

**Flutter Implementation Approach**:

```dart
ColorFiltered(
  colorFilter: ColorFilter.matrix([
    contrast, 0, 0, 0, brightness,
    0, contrast, 0, 0, brightness,
    0, 0, contrast, 0, brightness,
    0, 0, 0, 1, 0,
  ]),
  child: Image.asset('assets/images/sample.png'),
)
```

### Sample Data Reference

Original data from `PTK_3project.zip` (for reference, not bundled in app):

- Control file: `641070704_641070619_641070620 86412 Array Layout.txt`
- Original images: 1,584 TIFF files from `ImageResults/` folder
- Experiment ID: `641070511`
- Wells: W1, W2, W3, W4
- Time points: T5, T10, T25, T50, T100

### Mock Data Generation

**Grid Coordinates**:
```dart
// Pseudo-code
List<FiducialPosition> generateMockGrid(ControlFile control) {
  var positions = [];
  for (entry in control.entries) {
    // Base position from control file
    var x = calculateXFromRowCol(entry.row, entry.col) + entry.xoff;
    var y = calculateYFromRowCol(entry.row, entry.col) + entry.yoff;

    // Add small random offset to simulate algorithm fit
    x += random(-5, 5);
    y += random(-5, 5);

    positions.add(FiducialPosition(
      id: entry.id,
      row: entry.row,
      col: entry.col,
      x: x,
      y: y,
      isReference: entry.id == "#REF",
    ));
  }
  return positions;
}
```

---

## Future Enhancements (Post v0.1.0)

### Planned for v0.2.0+

1. **Undo/Redo**: Multi-level undo for grid adjustments
2. **Additional Keyboard Shortcuts**: Ctrl+Z for undo, other shortcuts
3. **Zoom/Pan Controls**: Built-in zoom (beyond browser zoom)
4. **Comparison View**: Side-by-side before/after
5. **Unsaved Changes Warning**: Prompt before navigation with unsaved changes
6. **Export Report**: Generate QC report with adjustment summary
7. **Batch Processing**: Mark multiple grids as approved/flagged
8. **Advanced Filtering**: Filter image list by status, time point, etc.
9. **Persistent Theme Preference**: Save light/dark mode choice to local storage

### Backend Integration (Future)
1. **File System Integration**: Load experiments from file system
2. **Real Algorithm Execution**: Run actual grid fitting algorithm
3. **Output File Generation**: Save coordinates to specified format
4. **Persistent Storage**: Database for tracking processed images
5. **Multi-user Support**: Track which user processed which grids

---

## Success Criteria

Version 0.1.0 will be considered successful if:

1. Application loads and displays mock experiment data
2. Users can navigate between grid images and time points
3. Arrow keys navigate between grid images
4. Users can drag entire grid smoothly
5. Users can drag individual fiducials
6. Status indicators update correctly (Green/Yellow)
7. Brightness/contrast adjustments visually affect the image and persist
8. Light/dark mode toggle works correctly
9. "Run" button simulates processing with 5-second delay
10. "New Grid" button resets to control file coordinates
11. Manual adjustments persist across navigation
12. Application runs on web and desktop
13. UI matches Shiny app layout and functionality
14. Code follows clean architecture pattern from technical spec template

---

## Revision History

| Version | Date       | Author | Changes                                                    |
| ------- | ---------- | ------ | ---------------------------------------------------------- |
| 0.1.0   | 2026-01-07 | Claude | Initial functional specification                           |
| 0.1.1   | 2026-01-08 | Claude | Added arrow key navigation, light/dark mode, mock images   |
