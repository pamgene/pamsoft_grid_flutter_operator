import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:pamsoft_grid_flutter_operator/providers/grid_provider.dart';
import 'package:pamsoft_grid_flutter_operator/providers/image_selection_provider.dart';
import 'package:pamsoft_grid_flutter_operator/utils/constants.dart';
import 'package:pamsoft_grid_flutter_operator/widgets/grid_dropdown.dart';
import 'package:pamsoft_grid_flutter_operator/widgets/navigation_buttons.dart';
import 'package:pamsoft_grid_flutter_operator/widgets/image_list.dart';
import 'package:pamsoft_grid_flutter_operator/widgets/pagination_controls.dart';
import 'package:pamsoft_grid_flutter_operator/widgets/image_viewer.dart';
import 'package:pamsoft_grid_flutter_operator/widgets/status_indicator.dart';
import 'package:pamsoft_grid_flutter_operator/widgets/brightness_contrast_sliders.dart';
import 'package:pamsoft_grid_flutter_operator/widgets/action_buttons.dart';
import 'package:pamsoft_grid_flutter_operator/widgets/theme_toggle.dart';

/// Main home screen of the application.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Load experiment data when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final imageProvider = context.read<ImageSelectionProvider>();
    final gridProvider = context.read<GridProvider>();

    await imageProvider.loadExperiment();

    // Load grid for first grid image
    final gridImage = imageProvider.currentGridImage;
    if (gridImage != null) {
      await gridProvider.loadGrid(gridImage.id);
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      final imageProvider = context.read<ImageSelectionProvider>();
      final gridProvider = context.read<GridProvider>();

      if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        if (imageProvider.canGoPreviousGrid) {
          imageProvider.previousGrid();
          _loadGridForCurrentSelection(gridProvider, imageProvider);
        }
      } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
        if (imageProvider.canGoNextGrid) {
          imageProvider.nextGrid();
          _loadGridForCurrentSelection(gridProvider, imageProvider);
        }
      }
    }
  }

  void _loadGridForCurrentSelection(
    GridProvider gridProvider,
    ImageSelectionProvider imageProvider,
  ) {
    final gridImage = imageProvider.currentGridImage;
    if (gridImage != null) {
      gridProvider.loadGrid(gridImage.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(AppConstants.appTitle),
          backgroundColor: const Color(0xFF005f75),
          foregroundColor: Colors.white,
          actions: const [
            ThemeToggle(),
            SizedBox(width: 8),
          ],
        ),
        body: Consumer<ImageSelectionProvider>(
          builder: (context, imageProvider, child) {
            if (imageProvider.isLoading) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (imageProvider.error != null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('Error: ${imageProvider.error}'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadData,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            return Row(
              children: [
                // Left panel
                SizedBox(
                  width: AppConstants.leftPanelWidth,
                  child: _buildLeftPanel(context, imageProvider),
                ),
                // Divider
                const VerticalDivider(width: 1),
                // Main content area
                Expanded(
                  child: _buildMainContent(context),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildLeftPanel(BuildContext context, ImageSelectionProvider imageProvider) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Grid Image dropdown
          const GridDropdown(),
          const SizedBox(height: 16),

          // Grid navigation buttons
          GridNavigationButtons(),
          const SizedBox(height: 8),

          // Image navigation buttons
          const ImageNavigationButtons(),
          const SizedBox(height: 16),

          // Image list
          Expanded(
            child: Card(
              child: const ImageList(),
            ),
          ),
          const SizedBox(height: 8),

          // Pagination controls
          const PaginationControls(),
        ],
      ),
    );
  }

  Widget _buildMainContent(BuildContext context) {
    return Consumer2<ImageSelectionProvider, GridProvider>(
      builder: (context, imageProvider, gridProvider, child) {
        final gridImage = imageProvider.currentGridImage;

        return Column(
          children: [
            // Title bar with status indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  StatusIndicator(status: gridProvider.currentStatus),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      gridImage?.displayName ?? 'No grid selected',
                      style: Theme.of(context).textTheme.titleMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            // Image viewer
            Expanded(
              child: const ImageViewer(),
            ),

            // Controls at bottom
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Brightness and Contrast sliders
                  Row(
                    children: [
                      Expanded(child: const BrightnessSlider()),
                      const SizedBox(width: 32),
                      Expanded(child: const ContrastSlider()),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Action buttons
                  const ActionButtons(),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
