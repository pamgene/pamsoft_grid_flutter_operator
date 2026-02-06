# UI Transition Plan: Pamsoft Grid to Tercen Style

## Executive Summary

Refactor the Pamsoft Grid Flutter Operator UI from its current custom Material theme to the new Tercen Design System while preserving all Pamgene domain functionality (fiducial grid positioning, TIFF conversion, image processing).

---

## Current State Analysis

### Current UI Structure

- **Layout**: Scaffold with AppBar + Row (300px left panel + main content)
- **AppBar**: Custom teal color (#005f75) with title, version, theme toggle
- **Left Panel**: 300px fixed width, no collapse, custom controls layout
- **Theme**: Material 3 with green seed color
- **State Management**: Provider pattern (4 ChangeNotifiers) - *KEEP AS-IS*

### Key Differences from Tercen Style

| Aspect | Current | Tercen Style |
| ------ | ------- | ------------ |
| Panel width | 300px fixed | 280px default, 280-400px resize, 48px collapsed |
| Panel header | Traditional AppBar | Accent-colored panel header (primary blue #1E40AF) |
| Collapse | Not supported | Required (48px icon strip) |
| Theme toggle | AppBar action | Left panel header |
| Sections | Mixed layout | UPPERCASE labels + icons, vertical scroll |
| Primary color | Green/Teal | Blue (#1E40AF) |
| Spacing | Mixed (10px, 12px...) | 8px grid (4, 8, 16, 24, 32, 48) |
| INFO section | None | Required (with GitHub link) |

---

## Critical Functionality to Preserve

**DO NOT MODIFY these domain-specific components:**

1. **Grid Configuration** (`lib/models/grid_configuration.dart`)
   - Equipment parameters: Evolve3 (spotPitch=17.0), Evolve2 (spotPitch=21.5)
   - Grid dimensions: 14x14 peptides, 8 reference fiducials
   - Image center calculations

2. **Position Algorithm** (`lib/models/grid_data.dart`)
   - Separate midpoints: references (3.5, 10.5) vs peptides (6.5, 6.5)
   - Base position calculations
   - Individual/global offset handling

3. **TIFF Converter** (`lib/utils/tiff_converter.dart`)
   - 16-bit to 8-bit conversion (12-bit data)
   - Byte order detection

4. **Image Filters** (`lib/utils/image_filters.dart`)
   - Brightness/contrast matrix

5. **Grid Canvas Interaction** (`lib/widgets/grid_canvas.dart`)
   - Hit testing for fiducials
   - Drag/rotate operations
   - Coordinate transformation

6. **All Providers** (`lib/providers/`)
   - GridProvider, ImageSelectionProvider, SettingsProvider, ThemeProvider
   - Keep business logic intact

---

## Implementation Plan

### Phase 1: Theme Foundation

**Create centralized theme files:**

```text
lib/core/theme/
├── app_theme.dart        # Material 3 configuration
├── app_colors.dart       # Tercen color palette
├── app_spacing.dart      # 8px grid spacing constants
└── app_text_styles.dart  # Typography (Fira Sans)
```

**Files to modify:**

- `lib/main.dart` - Update theme configuration
- `lib/utils/constants.dart` - Keep domain constants, move UI constants to theme

**Key values:**

```dart
// app_colors.dart
static const primary = Color(0xFF1E40AF);
static const primaryDarker = Color(0xFF1E3A8A);
static const green = Color(0xFF047857);  // Success/status
static const amber = Color(0xFFB45309);  // Warning
static const neutral100 = Color(0xFFF3F4F6);
static const neutral900 = Color(0xFF111827);

// app_spacing.dart
static const double xs = 4.0;
static const double sm = 8.0;
static const double md = 16.0;
static const double lg = 24.0;
static const double xl = 32.0;
static const double panelWidth = 280.0;
static const double panelCollapsedWidth = 48.0;
static const double headerHeight = 48.0;
```

---

### Phase 2: App Frame Restructure

**Remove traditional Scaffold/AppBar pattern, implement Tercen app frame:**

```text
Current:
┌──────────────────────────────────────────┐
│  AppBar (title, version, theme toggle)   │
├────────────┬─────────────────────────────┤
│ Left Panel │       Main Content          │
│  (300px)   │                             │
└────────────┴─────────────────────────────┘

New:
┌────────────┬─────────────────────────────┐
│ Left Panel │  Top Bar (optional)         │
│  Header    ├─────────────────────────────┤
│  (accent)  │                             │
├────────────┤       Main Content          │
│  Sections  │                             │
│  (scroll)  │                             │
└────────────┴─────────────────────────────┘
```

**Files to modify:**

- `lib/screens/home_screen.dart` - Major restructure

**Files to create:**

- `lib/presentation/widgets/app_shell.dart` - Overall frame
- `lib/presentation/widgets/left_panel/left_panel.dart` - Panel container
- `lib/presentation/widgets/left_panel/left_panel_header.dart` - Accent header
- `lib/presentation/widgets/left_panel/left_panel_section.dart` - Section component

---

### Phase 3: Left Panel Implementation

**Header (48px, accent background):**

- App icon (click to expand when collapsed)
- App title "Pamsoft Grid" (hidden when collapsed)
- Theme toggle: moon/sun icons (hidden when collapsed)
- Collapse chevron (always visible)

**Sections (always expanded, vertical scroll):**

| Section | Icon | Content |
| ------- | ---- | ------- |
| NAVIGATION | fa-compass | Grid dropdown, Grid nav buttons, Image nav buttons |
| IMAGES | fa-images | Image list (paginated), Pagination controls |
| DISPLAY | fa-sliders | Brightness slider, Contrast slider |
| ACTIONS | fa-bolt | New Grid button, Run button |
| INFO | fa-info-circle | GitHub link (version/commit) |

**Collapse behaviour:**

- Panel width animates 280px → 48px
- Shows icon strip for sections
- Click icon → expand + scroll to section

**Files to modify/create:**

- Refactor existing widgets into new panel sections
- `lib/widgets/grid_dropdown.dart` → move to NAVIGATION section
- `lib/widgets/navigation_buttons.dart` → move to NAVIGATION section
- `lib/widgets/image_list.dart` → move to IMAGES section
- `lib/widgets/brightness_contrast_sliders.dart` → move to DISPLAY section
- `lib/widgets/action_buttons.dart` → move to ACTIONS section

---

### Phase 4: Main Content Area

**Keep core functionality, update styling:**

- Status header with status indicator + title
- Rotation hint text
- ImageViewer with GridCanvas overlay
- Remove controls (moved to left panel)

**Files to modify:**

- `lib/widgets/image_viewer.dart` - Update styling only
- `lib/widgets/grid_canvas.dart` - NO CHANGES (preserve interaction)
- `lib/widgets/status_indicator.dart` - Update colours to Tercen palette

---

### Phase 5: Component Styling Updates

**Update existing widgets to Tercen style:**

| Widget | Changes |
| ------ | ------- |
| GridDropdown | Border radius 8px, neutral borders, primary focus |
| BrightnessSlider | Primary colour accent, label styling |
| ContrastSlider | Primary colour accent, label styling |
| ActionButtons | Primary/Secondary button styles |
| StatusIndicator | Map to Tercen semantic colours |
| ImageList | Hover states, selection background |
| PaginationControls | Dropdown styling |

---

### Phase 6: Context Detection & Top Bar

**Add context detection:**

```dart
bool get isInDataStep => Uri.base.queryParameters.containsKey('taskId');
bool get shouldShowTopBar => !isInDataStep;
```

**Top Bar (when not embedded):**

- Height: 48px
- Content: "FULL SCREEN MODE" badge + Close button
- Background: surface with bottom border

---

## File Change Summary

### New Files

```text
lib/core/theme/
├── app_theme.dart
├── app_colors.dart
├── app_spacing.dart
└── app_text_styles.dart

lib/presentation/widgets/
├── app_shell.dart
├── top_bar.dart
└── left_panel/
    ├── left_panel.dart
    ├── left_panel_header.dart
    ├── left_panel_section.dart
    └── info_section.dart

lib/core/version/
└── version_info.dart

scripts/
└── generate_version.dart
```

### Modified Files

```text
lib/main.dart                           # Theme config
lib/screens/home_screen.dart            # Major restructure
lib/utils/constants.dart                # Split UI/domain constants
lib/widgets/grid_dropdown.dart          # Styling
lib/widgets/navigation_buttons.dart     # Styling
lib/widgets/image_list.dart             # Styling
lib/widgets/brightness_contrast_sliders.dart  # Styling
lib/widgets/action_buttons.dart         # Styling + button variants
lib/widgets/status_indicator.dart       # Colours
lib/widgets/pagination_controls.dart    # Styling
lib/widgets/image_viewer.dart           # Remove controls layout
```

### Unchanged Files (Domain Logic)

```text
lib/models/                             # ALL models unchanged
lib/providers/                          # ALL providers unchanged
lib/services/                           # ALL services unchanged
lib/implementations/                    # ALL implementations unchanged
lib/utils/tiff_converter.dart           # Unchanged
lib/utils/image_filters.dart            # Unchanged
lib/widgets/grid_canvas.dart            # Unchanged (critical)
lib/di/service_locator.dart             # Unchanged
```

---

## Verification Plan

1. **Visual Verification**
   - Panel collapses to 48px correctly
   - Theme toggle works (light/dark)
   - Section labels are UPPERCASE with icons
   - Colours match Tercen palette

2. **Functional Verification**
   - Grid dropdown still loads grids
   - Image navigation works (keyboard + buttons)
   - Image list selection works
   - Brightness/contrast sliders work
   - Grid interaction unchanged:
     - Drag whole grid
     - Shift+drag to rotate
     - Click+drag individual fiducials
   - New Grid button resets grid
   - Run button shows processing state
   - Status indicator changes green/amber

3. **Domain Verification**
   - TIFF images load and convert correctly
   - Fiducial positions match original app
   - Grid overlay aligns with image
   - Reference vs peptide positioning correct

4. **Build Verification**
   - `flutter build web` succeeds
   - No Dart errors
   - Web app runs in browser

---

## Design Decisions (Confirmed)

1. **Status Indicator Colours**: Map to Tercen semantic colours
   - Processed: Tercen green `#047857` (was `Colors.green`)
   - Modified: Tercen amber `#B45309` (was `Colors.yellow`)

2. **Fiducial Overlay Colour**: Keep green
   - Green provides good contrast on grayscale TIFF images
   - Established convention in Pamgene workflows
   - NO CHANGE to `fiducialColor` in constants

3. **Panel Collapse**: Include full implementation
   - 280px default → 48px collapsed
   - Icon strip for sections when collapsed
   - Click to expand + scroll to section

---

## Risk Mitigation

1. **Grid Canvas** - NO CHANGES to preserve exact coordinate calculations
2. **Position Algorithm** - NO CHANGES to GridData.calculatePositions()
3. **TIFF Conversion** - NO CHANGES to TiffConverter
4. **Provider Logic** - Keep all business logic, only update UI bindings

---

## Dependencies

- FontAwesome 6 Solid icons (add font_awesome_flutter package)
- Fira Sans font (add to pubspec.yaml)
- url_launcher (for INFO section GitHub links)

---

## Estimated Scope

- **New files**: ~12 files
- **Modified files**: ~12 files
- **Unchanged files**: ~15+ files (all domain logic)
- **Lines of code**: ~1500-2000 new/modified lines
