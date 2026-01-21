import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart' hide Config;

// Modular: DrawingOverlay Widget
class DrawingOverlay extends StatelessWidget {
  final Function(DragStartDetails) onPanStart;
  final Function(DragUpdateDetails) onPanUpdate;
  final Function(DragEndDetails) onPanEnd;
  final List<ui.Path> paths;
  final ui.Path currentPath;
  final Color color;
  final double brushSize;

  const DrawingOverlay({
    super.key,
    required this.onPanStart,
    required this.onPanUpdate,
    required this.onPanEnd,
    required this.paths,
    required this.currentPath,
    required this.color,
    required this.brushSize,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: onPanStart,
      onPanUpdate: onPanUpdate,
      onPanEnd: onPanEnd,
      child: Container(
        color: Colors.transparent,
        child: CustomPaint(
          size: Size.infinite,
          painter: DrawingPainter(paths, currentPath, color, brushSize),
        ),
      ),
    );
  }
}

// Modular: OverlayManager Widget
class OverlayManager extends StatelessWidget {
  final String inputText;
  final Color textColor;
  final List<String> addedTexts;
  final List<Offset> textPositions;
  final List<Color> textColors;
  final Function(int, Offset) onTextDrag;
  final List<String> addedStickers;
  final List<Offset> stickerPositions;
  final Function(int, Offset) onStickerDrag;

  const OverlayManager({
    super.key,
    required this.inputText,
    required this.textColor,
    required this.addedTexts,
    required this.textPositions,
    required this.textColors,
    required this.onTextDrag,
    required this.addedStickers,
    required this.stickerPositions,
    required this.onStickerDrag,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Live text preview (the one currently being typed)
        if (inputText.isNotEmpty)
          Positioned(
            left: 50,
            top: 50,
            child: Container(
              padding: const EdgeInsets.all(4),
              child: Text(
                inputText,
                style: GoogleFonts.roboto(
                  fontSize: 32,
                  color: textColor.withOpacity(0.5),
                  fontWeight: FontWeight.bold,
                  shadows: const [
                    Shadow(
                      blurRadius: 4.0,
                      color: Colors.black54,
                      offset: Offset(2.0, 2.0),
                    ),
                  ],
                ),
              ),
            ),
          ),
        // Added text overlays
        ...addedTexts.asMap().entries.map(
          (entry) => Positioned(
            left: textPositions[entry.key].dx,
            top: textPositions[entry.key].dy,
            child: GestureDetector(
              onPanUpdate: (details) => onTextDrag(entry.key, details.delta),
              child: Container(
                padding: const EdgeInsets.all(4),
                child: Text(
                  entry.value,
                  style: GoogleFonts.roboto(
                    fontSize: 32,
                    color: textColors[entry.key],
                    fontWeight: FontWeight.bold,
                    shadows: const [
                      Shadow(
                        blurRadius: 4.0,
                        color: Colors.black54,
                        offset: Offset(2.0, 2.0),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        // Sticker overlays
        ...addedStickers.asMap().entries.map(
          (entry) => Positioned(
            left: stickerPositions[entry.key].dx,
            top: stickerPositions[entry.key].dy,
            child: GestureDetector(
              onPanUpdate: (details) => onStickerDrag(entry.key, details.delta),
              child: Container(
                padding: const EdgeInsets.all(4),
                child: Text(entry.value, style: const TextStyle(fontSize: 48)),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Modular: DrawingPainter (CustomPainter for drawing)
class DrawingPainter extends CustomPainter {
  final List<ui.Path> paths;
  final ui.Path currentPath;
  final Color color;
  final double brushSize;

  DrawingPainter(this.paths, this.currentPath, this.color, this.brushSize);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeCap = StrokeCap.round
      ..strokeWidth = brushSize;

    for (final path in paths) {
      canvas.drawPath(path, paint);
    }
    canvas.drawPath(currentPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
