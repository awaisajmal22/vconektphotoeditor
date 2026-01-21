// lib/data/repositories/image_repository_impl.dart
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:gal/gal.dart' as gal;
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;

import 'package:google_fonts/google_fonts.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photo_editor/core/model/image_model.dart';
import 'package:photo_editor/core/utils/utils.dart';
import 'package:photo_editor/features/domain/repository/image_repository.dart';

class ImageRepositoryImpl implements ImageRepository {
  final ImagePicker _picker = ImagePicker();

  @override
  Future<ImageModel?> pickImage({ImageSource source = ImageSource.gallery}) async {
    final XFile? picked = await _picker.pickImage(source: source);
    if (picked != null) {
      return ImageModel(file: File(picked.path));
    }
    return null;
  }

  @override
  Future<List<ImageModel>?> pickMultipleImages({int maxImages = 6, int minImages = 2}) async {
    final List<XFile>? picked = await _picker.pickMultiImage(
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
      limit: maxImages,
    );
    if (picked != null && picked.length >= minImages) {
      return picked.map((xfile) => ImageModel(file: File(xfile.path))).toList();
    }
    return null;
  }

  @override
  Future<File?> createCollage(List<File> images) async {
    if (images.isEmpty || images.length < 2) return null;

    final int numImages = images.length;
    final int canvasWidth = 900;
    int canvasHeight = 900;

    // Determine layout
    List<Rect> cellRects = [];
    if (numImages == 2) {
      canvasHeight = 600;
      cellRects = [
        Rect.fromLTWH(0, 0, canvasWidth / 2, canvasHeight.toDouble()),
        Rect.fromLTWH(canvasWidth / 2, 0, canvasWidth / 2, canvasHeight.toDouble()),
      ];
    } else if (numImages == 3) {
      canvasHeight = 900;
      cellRects = [
        Rect.fromLTWH(0, 0, canvasWidth / 2, canvasHeight / 2),
        Rect.fromLTWH(canvasWidth / 2, 0, canvasWidth / 2, canvasHeight / 2),
        Rect.fromLTWH(0, canvasHeight / 2, canvasWidth.toDouble(), canvasHeight / 2),
      ];
    } else if (numImages == 4) {
      canvasHeight = 900;
      cellRects = [
        Rect.fromLTWH(0, 0, canvasWidth / 2, canvasHeight / 2),
        Rect.fromLTWH(canvasWidth / 2, 0, canvasWidth / 2, canvasHeight / 2),
        Rect.fromLTWH(0, canvasHeight / 2, canvasWidth / 2, canvasHeight / 2),
        Rect.fromLTWH(canvasWidth / 2, canvasHeight / 2, canvasWidth / 2, canvasHeight / 2),
      ];
    } else if (numImages == 5) {
      canvasHeight = 1200;
      cellRects = [
        Rect.fromLTWH(0, 0, canvasWidth / 2, canvasHeight / 3),
        Rect.fromLTWH(canvasWidth / 2, 0, canvasWidth / 2, canvasHeight / 3),
        Rect.fromLTWH(0, canvasHeight / 3, canvasWidth / 2, canvasHeight / 3),
        Rect.fromLTWH(canvasWidth / 2, canvasHeight / 3, canvasWidth / 2, canvasHeight / 3),
        Rect.fromLTWH(0, 2 * canvasHeight / 3, canvasWidth.toDouble(), canvasHeight / 3),
      ];
    } else {
      // Default grid for 6 or more
      int cols = 3;
      int rows = (numImages / cols).ceil();
      canvasHeight = (canvasWidth * rows / cols).round();
      double cellW = canvasWidth / cols;
      double cellH = canvasHeight / rows;
      for (int i = 0; i < numImages; i++) {
        int r = i ~/ cols;
        int c = i % cols;
        cellRects.add(Rect.fromLTWH(c * cellW, r * cellH, cellW, cellH));
      }
    }

    final img.Image canvas = img.Image(
      width: canvasWidth,
      height: canvasHeight,
      backgroundColor: img.ColorRgb8(255, 255, 255),
    );

    for (int i = 0; i < numImages; i++) {
      if (i >= cellRects.length) break;
      if (!await images[i].exists()) continue;

      final Uint8List bytes = await images[i].readAsBytes();
      img.Image? subImg = img.decodeImage(bytes);
      if (subImg == null) continue;

      final rect = cellRects[i];
      // Fix aspect ratio: Crop and resize to fill the cell
      subImg = _cropToFit(subImg, rect.width.round(), rect.height.round());

      img.compositeImage(canvas, subImg, dstX: rect.left.round(), dstY: rect.top.round());
    }

    // Optional: Add subtle borders
    for (final rect in cellRects) {
      img.drawRect(canvas, 
        x1: rect.left.round(), y1: rect.top.round(), 
        x2: rect.right.round(), y2: rect.bottom.round(), 
        color: img.ColorRgb8(240, 240, 240), thickness: 2);
    }

    final Uint8List outputBytes = img.encodeJpg(canvas, quality: 95);
    final tempDir = await getTemporaryDirectory();
    final fileName = 'collage_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final tempFile = File('${tempDir.path}/$fileName');
    await tempFile.writeAsBytes(outputBytes);

    if (!await tempFile.exists()) {
      debugPrint('Temp file creation failed: ${tempFile.path}');
      return null;
    }

    return tempFile;
  }

  img.Image _cropToFit(img.Image image, int targetWidth, int targetHeight) {
    final double imageAspect = image.width / image.height;
    final double targetAspect = targetWidth / targetHeight;

    int cropWidth, cropHeight, cropX, cropY;

    if (imageAspect > targetAspect) {
      // Image is wider than target aspect ratio
      cropHeight = image.height;
      cropWidth = (image.height * targetAspect).round();
      cropX = (image.width - cropWidth) ~/ 2;
      cropY = 0;
    } else {
      // Image is taller than target aspect ratio
      cropWidth = image.width;
      cropHeight = (image.width / targetAspect).round();
      cropX = 0;
      cropY = (image.height - cropHeight) ~/ 2;
    }

    final cropped = img.copyCrop(image, x: cropX, y: cropY, width: cropWidth, height: cropHeight);
    return img.copyResize(cropped, width: targetWidth, height: targetHeight);
  }

  @override
  Future<File> applyFilter(File imageFile, String filterType) async {
    if (!await imageFile.exists()) {
      debugPrint('Apply filter input file not found: ${imageFile.path}');
      return imageFile;
    }

    final Uint8List bytes = await imageFile.readAsBytes();
    final img.Image? original = img.decodeImage(bytes);
    if (original == null) return imageFile;

    img.Image processed = original;
    switch (filterType) {
      case 'none': processed = original; break;
      case 'grayscale': processed = FilterUtils.grayscale(original); break;
      case 'sepia': processed = FilterUtils.sepia(original); break;
      case 'brightness': processed = FilterUtils.brightness(original, 1.2); break;
      case 'vintage': processed = FilterUtils.vintage(original); break;
      case 'retro': processed = FilterUtils.retro(original); break;
      case 'high_contrast_bw': processed = FilterUtils.highContrastBw(original); break;
      case 'teal_and_orange': processed = FilterUtils.tealAndOrange(original); break;
      case 'soft_focus': processed = FilterUtils.softFocus(original); break;
      case 'glow': processed = FilterUtils.glow(original); break;
      case 'vibrant': processed = FilterUtils.vibrant(original); break;
      case 'fresh': processed = FilterUtils.fresh(original); break;
      case 'warmth': processed = FilterUtils.warmth(original); break;
      case 'faded_film': processed = FilterUtils.fadedFilm(original); break;
      case 'lomo': processed = FilterUtils.lomo(original); break;
      case 'sketch': processed = FilterUtils.sketch(original); break;
      case 'night_vision': processed = FilterUtils.nightVision(original); break;
      case 'haze': processed = FilterUtils.haze(original); break;
    }

    final Uint8List outputBytes = img.encodeJpg(processed, quality: 95);
    final tempDir = await getTemporaryDirectory();
    final fileName = 'filtered_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final tempFile = File('${tempDir.path}/$fileName');
    await tempFile.writeAsBytes(outputBytes);

    if (!await tempFile.exists()) {
      debugPrint('Filter temp file creation failed: ${tempFile.path}');
      return imageFile;
    }

    return tempFile;
  }

  @override
  Future<bool> saveImage(File imageFile) async {
    try {
      if (!await imageFile.exists()) {
        debugPrint('Save file not found: ${imageFile.path}');
        return false;
      }
      await gal.Gal.putImage(imageFile.path);
      return true;
    } catch (e) {
      debugPrint('Save error: $e');
      return false;
    }
  }

  @override
  Future<File?> cropImage(File imageFile) async {
    if (!await imageFile.exists()) {
      debugPrint('Crop input file not found: ${imageFile.path}');
      return null;
    }

    final ImageCropper cropper = ImageCropper();
    final CroppedFile? croppedFile = await cropper.cropImage(
      sourcePath: imageFile.path,
      compressFormat: ImageCompressFormat.jpg,
      compressQuality: 100,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Image',
          toolbarColor: Colors.deepPurple,
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: false,
          aspectRatioPresets: [
            CropAspectRatioPreset.square,
            CropAspectRatioPreset.ratio3x2,
            CropAspectRatioPreset.original,
            CropAspectRatioPreset.ratio4x3,
            CropAspectRatioPreset.ratio16x9,
          ],
        ),
        IOSUiSettings(
          title: 'Crop Image',
          aspectRatioLockEnabled: false,
          aspectRatioPresets: [
            CropAspectRatioPreset.square,
            CropAspectRatioPreset.ratio3x2,
            CropAspectRatioPreset.original,
            CropAspectRatioPreset.ratio4x3,
            CropAspectRatioPreset.ratio16x9,
          ],
        ),
      ],
    );

    if (croppedFile != null) {
      final cropped = File(croppedFile.path);
      if (await cropped.exists()) {
        return cropped;
      } else {
        debugPrint('Crop output file not found: ${cropped.path}');
        return null;
      }
    }
    return null;
  }

  @override
  Future<File?> addTextOverlay(File imageFile, String text, {int x = 50, int y = 50, double fontSize = 32, ui.Color? textColor}) async {
    if (!await imageFile.exists()) {
      debugPrint('Text overlay input file not found: ${imageFile.path}');
      return null;
    }

    final Uint8List bytes = await imageFile.readAsBytes();
    img.Image? base = img.decodeImage(bytes);
    if (base == null) return null;

    final ui.Color color = textColor ?? const ui.Color.fromRGBO(255, 255, 255, 1.0);

    // Render high-quality text using ui.Canvas
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);

    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: GoogleFonts.roboto(
          fontSize: fontSize,
          color: color,
          fontWeight: FontWeight.bold,
          shadows: const [
            Shadow(
              blurRadius: 4.0,
              color: ui.Color.fromARGB(180, 0, 0, 0),
              offset: Offset(2.0, 2.0),
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(canvas, Offset.zero);

    final picture = recorder.endRecording();
    final uiImage = await picture.toImage(
      textPainter.width.ceil().clamp(1, 10000),
      textPainter.height.ceil().clamp(1, 10000),
    );

    final byteData = await uiImage.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) return null;

    final img.Image? textOverlay = img.decodePng(byteData.buffer.asUint8List());
    if (textOverlay == null) return null;

    // Composite high-quality text overlay onto the base image
    img.compositeImage(base, textOverlay, dstX: x, dstY: y);

    final Uint8List outputBytes = img.encodeJpg(base, quality: 95);
    final tempDir = await getTemporaryDirectory();
    final tempFile = File('${tempDir.path}/text_overlay_${DateTime.now().millisecondsSinceEpoch}.jpg');
    await tempFile.writeAsBytes(outputBytes);

    if (!await tempFile.exists()) {
      debugPrint('Text overlay temp file creation failed: ${tempFile.path}');
      return null;
    }

    return tempFile;
  }

  @override
  Future<File?> addSticker(File imageFile, String stickerPath, {int x = 100, int y = 100, double scale = 1.0}) async {
    if (!await imageFile.exists()) {
      debugPrint('Sticker input file not found: ${imageFile.path}');
      return null;
    }
    final stickerFile = File(stickerPath);
    if (!await stickerFile.exists()) {
      debugPrint('Sticker file not found: $stickerPath');
      return null;
    }

    final Uint8List bytes = await imageFile.readAsBytes();
    img.Image? base = img.decodeImage(bytes);
    if (base == null) return null;

    final Uint8List stickerBytes = await stickerFile.readAsBytes();
    img.Image? sticker = img.decodeImage(stickerBytes);
    if (sticker == null) return null;

    sticker = img.copyResize(sticker, width: (sticker.width * scale).round(), height: (sticker.height * scale).round());
    img.compositeImage(base, sticker, dstX: x, dstY: y);

    final Uint8List outputBytes = img.encodeJpg(base, quality: 95);
    final tempDir = await getTemporaryDirectory();
    final tempFile = File('${tempDir.path}/sticker_${DateTime.now().millisecondsSinceEpoch}.jpg');
    await tempFile.writeAsBytes(outputBytes);

    if (!await tempFile.exists()) {
      debugPrint('Sticker temp file creation failed: ${tempFile.path}');
      return null;
    }

    return tempFile;
  }

  @override
  Future<File?> addDrawingOverlay(File imageFile, List<ui.Path> paths, Color color, double brushSize) async {
    if (!await imageFile.exists()) {
      debugPrint('Drawing overlay input file not found: ${imageFile.path}');
      return null;
    }

    final Uint8List bytes = await imageFile.readAsBytes();
    img.Image? base = img.decodeImage(bytes);
    if (base == null) return null;

    final int r = color.red;
    final int g = color.green;
    final int b = color.blue;
    final int thickness = brushSize.round();

    // Convert Flutter Paths to img lines (simplified: sample points and draw lines)
    for (final path in paths) {
      final pathMetrics = path.computeMetrics();
      for (final metric in pathMetrics) {
        if (metric.length > 0) {
          final tangent = metric.getTangentForOffset(0.0);
          Offset start = tangent?.position ?? Offset.zero;
          for (double distance = 0; distance < metric.length; distance += 5.0) {  // Sample every 5px
            final tangent = metric.getTangentForOffset(distance);
            final end = tangent?.position ?? start;
            img.drawLine(base, x1: start.dx.round(), y1: start.dy.round(), x2: end.dx.round(), y2: end.dy.round(), 
                         color: img.ColorRgb8(r, g, b), thickness: thickness);
            start = end;
          }
        }
      }
    }

    final Uint8List outputBytes = img.encodeJpg(base, quality: 95);
    final tempDir = await getTemporaryDirectory();
    final tempFile = File('${tempDir.path}/drawing_${DateTime.now().millisecondsSinceEpoch}.jpg');
    await tempFile.writeAsBytes(outputBytes);

    if (!await tempFile.exists()) {
      debugPrint('Drawing temp file creation failed: ${tempFile.path}');
      return null;
    }

    return tempFile;
  }
}