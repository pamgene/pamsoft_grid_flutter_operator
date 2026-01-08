import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pamsoft_grid_flutter_operator/models/grid_data.dart';
import 'package:pamsoft_grid_flutter_operator/providers/grid_provider.dart';
import 'package:pamsoft_grid_flutter_operator/utils/constants.dart';

/// Interactive canvas for displaying and manipulating the grid overlay.
class GridCanvas extends StatefulWidget {
  final double containerWidth;
  final double containerHeight;

  const GridCanvas({
    super.key,
    required this.containerWidth,
    required this.containerHeight,
  });

  @override
  State<GridCanvas> createState() => _GridCanvasState();
}

class _GridCanvasState extends State<GridCanvas> {
  String? _draggingFiducialId;
  Offset? _lastDragPosition;

  @override
  Widget build(BuildContext context) {
    return Consumer<GridProvider>(
      builder: (context, gridProvider, child) {
        final gridData = gridProvider.currentGridData;
        if (gridData == null) {
          return const SizedBox.shrink();
        }

        return GestureDetector(
          onPanStart: (details) =>
              _onPanStart(details, gridData, gridProvider),
          onPanUpdate: (details) => _onPanUpdate(details, gridProvider, gridData),
          onPanEnd: (_) => _onPanEnd(),
          child: CustomPaint(
            size: Size(widget.containerWidth, widget.containerHeight),
            painter: GridPainter(
              gridData: gridData,
              containerWidth: widget.containerWidth,
              containerHeight: widget.containerHeight,
            ),
          ),
        );
      },
    );
  }

  void _onPanStart(
    DragStartDetails details,
    GridData gridData,
    GridProvider provider,
  ) {
    final localPosition = details.localPosition;

    // Check if we're clicking on a fiducial
    for (final fiducial in gridData.fiducials) {
      final fiducialPos = Offset(
        fiducial.x + gridData.globalOffsetX,
        fiducial.y + gridData.globalOffsetY,
      );

      if ((localPosition - fiducialPos).distance <=
          AppConstants.fiducialHitTestRadius) {
        _draggingFiducialId = fiducial.id;
        _lastDragPosition = localPosition;
        return;
      }
    }

    // Not on a fiducial, will drag whole grid
    _draggingFiducialId = null;
    _lastDragPosition = localPosition;
  }

  void _onPanUpdate(DragUpdateDetails details, GridProvider provider, GridData gridData) {
    if (_lastDragPosition == null) return;

    final delta = details.localPosition - _lastDragPosition!;
    _lastDragPosition = details.localPosition;

    // Calculate constrained delta to keep grid within bounds
    final constrainedDelta = _constrainDelta(delta, gridData);

    if (_draggingFiducialId != null) {
      // Dragging individual fiducial
      provider.moveFiducial(_draggingFiducialId!, constrainedDelta.dx, constrainedDelta.dy);
    } else {
      // Dragging whole grid
      provider.moveWholeGrid(constrainedDelta.dx, constrainedDelta.dy);
    }
  }

  Offset _constrainDelta(Offset delta, GridData gridData) {
    // Get current grid bounds
    double minX = double.infinity;
    double maxX = double.negativeInfinity;
    double minY = double.infinity;
    double maxY = double.negativeInfinity;

    for (final fiducial in gridData.fiducials) {
      final x = fiducial.x + gridData.globalOffsetX;
      final y = fiducial.y + gridData.globalOffsetY;
      minX = x < minX ? x : minX;
      maxX = x > maxX ? x : maxX;
      minY = y < minY ? y : minY;
      maxY = y > maxY ? y : maxY;
    }

    // Account for circle radius
    final radius = AppConstants.fiducialRadius;
    minX -= radius;
    maxX += radius;
    minY -= radius;
    maxY += radius;

    // Calculate how much we can move in each direction
    double constrainedDx = delta.dx;
    double constrainedDy = delta.dy;

    // Constrain to keep grid within container bounds
    if (minX + delta.dx < 0) {
      constrainedDx = -minX;
    } else if (maxX + delta.dx > widget.containerWidth) {
      constrainedDx = widget.containerWidth - maxX;
    }

    if (minY + delta.dy < 0) {
      constrainedDy = -minY;
    } else if (maxY + delta.dy > widget.containerHeight) {
      constrainedDy = widget.containerHeight - maxY;
    }

    return Offset(constrainedDx, constrainedDy);
  }

  void _onPanEnd() {
    _draggingFiducialId = null;
    _lastDragPosition = null;
  }
}

/// Custom painter for rendering the grid overlay.
class GridPainter extends CustomPainter {
  final GridData gridData;
  final double containerWidth;
  final double containerHeight;

  GridPainter({
    required this.gridData,
    required this.containerWidth,
    required this.containerHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppConstants.fiducialColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = AppConstants.fiducialStrokeWidth;

    // Clip to container bounds
    canvas.clipRect(Rect.fromLTWH(0, 0, containerWidth, containerHeight));

    for (final fiducial in gridData.fiducials) {
      final center = Offset(
        fiducial.x + gridData.globalOffsetX,
        fiducial.y + gridData.globalOffsetY,
      );

      canvas.drawCircle(center, AppConstants.fiducialRadius, paint);
    }
  }

  @override
  bool shouldRepaint(GridPainter oldDelegate) {
    return true; // Always repaint for now, can optimize later
  }
}
