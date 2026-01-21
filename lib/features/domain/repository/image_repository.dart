import 'dart:io';
import 'dart:ui' as ui;

import 'package:image_picker/image_picker.dart';
import 'package:photo_editor/core/model/image_model.dart';
import 'package:photo_editor/core/model/overlay_model.dart';

abstract class ImageRepository {
  Future<ImageModel?> pickImage({ImageSource source});
  Future<List<ImageModel>?> pickMultipleImages({int maxImages = 6, int minImages = 2});
  Future<File?> createCollage(List<File> images);
  Future<File> applyFilter(File imageFile, String filterType);
  Future<bool> saveImage(File imageFile);
  Future<File?> cropImage(File imageFile);
  Future<File?> addTextOverlay(File imageFile, String text, {int x = 50, int y = 50, double fontSize = 32, ui.Color? textColor});
  Future<File?> addSticker(File imageFile, String stickerPath, {int x = 100, int y = 100, double scale = 1.0});
  Future<File?> addDrawingOverlay(File imageFile, List<ui.Path> paths, ui.Color color, double brushSize);
  Future<File?> addEmojiOverlay(File imageFile, String emoji, {int x = 100, int y = 100, double fontSize = 64});
  Future<File?> applyBatchOverlays(File imageFile, List<OverlayModel> overlays);
}