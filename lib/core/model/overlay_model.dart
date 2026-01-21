import 'dart:ui' as ui;

abstract class OverlayModel {
  final double x;
  final double y;

  OverlayModel({required this.x, required this.y});
}

class TextOverlayModel extends OverlayModel {
  final String text;
  final ui.Color color;
  final double fontSize;

  TextOverlayModel({
    required super.x,
    required super.y,
    required this.text,
    required this.color,
    required this.fontSize,
  });
}

class EmojiOverlayModel extends OverlayModel {
  final String emoji;
  final double fontSize;

  EmojiOverlayModel({
    required super.x,
    required super.y,
    required this.emoji,
    required this.fontSize,
  });
}

class DrawingOverlayModel extends OverlayModel {
  final List<ui.Path> paths;
  final ui.Color color;
  final double brushSize;

  DrawingOverlayModel({
    required this.paths,
    required this.color,
    required this.brushSize,
  }) : super(x: 0, y: 0);
}
