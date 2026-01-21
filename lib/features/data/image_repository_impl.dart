// lib/data/repositories/image_repository_impl.dart
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gal/gal.dart' as gal;
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;

import 'package:google_fonts/google_fonts.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photo_editor/core/model/image_model.dart';
import 'package:photo_editor/core/model/overlay_model.dart';
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

    final List<String> imagePaths = images.map((e) => e.path).toList();
    final tempDir = await getTemporaryDirectory();
    final String outputPath = '${tempDir.path}/collage_${DateTime.now().millisecondsSinceEpoch}.jpg';

    final String? resultPath = await compute(_createCollageIsolate, {
      'imagePaths': imagePaths,
      'outputPath': outputPath,
    });

    if (resultPath != null) {
      return File(resultPath);
    }
    return null;
  }

  static Future<String?> _createCollageIsolate(Map<String, dynamic> params) async {
    final List<String> imagePaths = params['imagePaths'];
    final String outputPath = params['outputPath'];

    final int numImages = imagePaths.length;
    const int canvasWidth = 900;
    int canvasHeight = 900;

    // Determine layout
    List<Rect> cellRects = [];
    if (numImages == 2) {
      canvasHeight = 600;
      cellRects = [
        Rect.fromLTWH(0, 0, canvasWidth / 2, 600),
        Rect.fromLTWH(canvasWidth / 2, 0, canvasWidth / 2, 600),
      ];
    } else if (numImages == 3) {
      canvasHeight = 900;
      cellRects = [
        Rect.fromLTWH(0, 0, canvasWidth / 2, 450),
        Rect.fromLTWH(canvasWidth / 2, 0, canvasWidth / 2, 450),
        Rect.fromLTWH(0, 450, canvasWidth.toDouble(), 450),
      ];
    } else if (numImages == 4) {
      canvasHeight = 900;
      cellRects = [
        Rect.fromLTWH(0, 0, canvasWidth / 2, 450),
        Rect.fromLTWH(canvasWidth / 2, 0, canvasWidth / 2, 450),
        Rect.fromLTWH(0, 450, canvasWidth / 2, 450),
        Rect.fromLTWH(canvasWidth / 2, 450, canvasWidth / 2, 450),
      ];
    } else if (numImages == 5) {
      canvasHeight = 1200;
      cellRects = [
        Rect.fromLTWH(0, 0, canvasWidth / 2, 400),
        Rect.fromLTWH(canvasWidth / 2, 0, canvasWidth / 2, 400),
        Rect.fromLTWH(0, 400, canvasWidth / 2, 400),
        Rect.fromLTWH(canvasWidth / 2, 400, canvasWidth / 2, 400),
        Rect.fromLTWH(0, 800, canvasWidth.toDouble(), 400),
      ];
    } else {
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
      final File imageFile = File(imagePaths[i]);
      if (!imageFile.existsSync()) continue;

      final Uint8List bytes = imageFile.readAsBytesSync();
      img.Image? subImg = img.decodeImage(bytes);
      if (subImg == null) continue;

      final rect = cellRects[i];
      subImg = _cropToFitIsolate(subImg, rect.width.round(), rect.height.round());

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
    final File outputFile = File(outputPath);
    outputFile.writeAsBytesSync(outputBytes);

    return outputFile.path;
  }

  static img.Image _cropToFitIsolate(img.Image image, int targetWidth, int targetHeight) {
    final double imageAspect = image.width / image.height;
    final double targetAspect = targetWidth / targetHeight;

    int cropWidth, cropHeight, cropX, cropY;

    if (imageAspect > targetAspect) {
      cropHeight = image.height;
      cropWidth = (image.height * targetAspect).round();
      cropX = (image.width - cropWidth) ~/ 2;
      cropY = 0;
    } else {
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

    final tempDir = await getTemporaryDirectory();
    final String outputPath = '${tempDir.path}/filtered_${DateTime.now().millisecondsSinceEpoch}.jpg';

    final String? resultPath = await compute(_applyFilterIsolate, {
      'inputPath': imageFile.path,
      'outputPath': outputPath,
      'filterType': filterType,
    });

    if (resultPath != null) {
      return File(resultPath);
    }
    return imageFile;
  }

  static Future<String?> _applyFilterIsolate(Map<String, dynamic> params) async {
    try {
      final String inputPath = params['inputPath'];
      final String outputPath = params['outputPath'];
      final String filterType = params['filterType'];

      final File imageFile = File(inputPath);
      final Uint8List bytes = await imageFile.readAsBytes();
      final img.Image? original = img.decodeImage(bytes);
      if (original == null) return null;

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
      final File outputFile = File(outputPath);
      await outputFile.writeAsBytes(outputBytes);

      return outputFile.path;
    } catch (e) {
      debugPrint('Error in _applyFilterIsolate: $e');
      return null;
    }
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
    
    final ui.Color color = textColor ?? const ui.Color.fromRGBO(255, 255, 255, 1.0);

    // Render high-quality text using ui.Canvas (must be on main thread as it uses GoogleFonts/TextPainter)
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
    final Uint8List overlayBytes = byteData.buffer.asUint8List();

    final tempDir = await getTemporaryDirectory();
    final String outputPath = '${tempDir.path}/text_overlay_${DateTime.now().millisecondsSinceEpoch}.jpg';

    final String? resultPath = await compute(_compositeOverlayIsolate, {
      'baseBytes': bytes,
      'overlayBytes': overlayBytes,
      'outputPath': outputPath,
      'x': x,
      'y': y,
    });

    if (resultPath != null) {
      return File(resultPath);
    }
    return null;
  }

  static Future<String?> _compositeOverlayIsolate(Map<String, dynamic> params) async {
    try {
      final Uint8List baseBytes = params['baseBytes'];
      final Uint8List overlayBytes = params['overlayBytes'];
      final String outputPath = params['outputPath'];
      final int x = params['x'];
      final int y = params['y'];

      final img.Image? base = img.decodeImage(baseBytes);
      if (base == null) return null;

      final img.Image? overlay = img.decodePng(overlayBytes);
      if (overlay == null) return null;

      img.compositeImage(base, overlay, dstX: x, dstY: y);

      final Uint8List outputBytes = img.encodeJpg(base, quality: 95);
      final File outputFile = File(outputPath);
      await outputFile.writeAsBytes(outputBytes);

      return outputFile.path;
    } catch (e) {
      debugPrint('Error in _compositeOverlayIsolate: $e');
      return null;
    }
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

    final Uint8List baseBytes = await imageFile.readAsBytes();
    final Uint8List stickerBytes = await stickerFile.readAsBytes();

    final tempDir = await getTemporaryDirectory();
    final String outputPath = '${tempDir.path}/sticker_${DateTime.now().millisecondsSinceEpoch}.jpg';

    final String? resultPath = await compute(_addStickerIsolate, {
      'baseBytes': baseBytes,
      'stickerBytes': stickerBytes,
      'outputPath': outputPath,
      'x': x,
      'y': y,
      'scale': scale,
    });

    if (resultPath != null) {
      return File(resultPath);
    }
    return null;
  }

  static Future<String?> _addStickerIsolate(Map<String, dynamic> params) async {
    try {
      final Uint8List baseBytes = params['baseBytes'];
      final Uint8List stickerBytes = params['stickerBytes'];
      final String outputPath = params['outputPath'];
      final int x = params['x'];
      final int y = params['y'];
      final double scale = params['scale'];

      final img.Image? base = img.decodeImage(baseBytes);
      if (base == null) return null;

      img.Image? sticker = img.decodeImage(stickerBytes);
      if (sticker == null) return null;

      if (scale != 1.0) {
        sticker = img.copyResize(sticker, width: (sticker.width * scale).round(), height: (sticker.height * scale).round());
      }
      
      img.compositeImage(base, sticker, dstX: x, dstY: y);

      final Uint8List outputBytes = img.encodeJpg(base, quality: 95);
      final File outputFile = File(outputPath);
      await outputFile.writeAsBytes(outputBytes);

      return outputFile.path;
    } catch (e) {
      debugPrint('Error in _addStickerIsolate: $e');
      return null;
    }
  }

  @override
  Future<File?> addDrawingOverlay(File imageFile, List<ui.Path> paths, Color color, double brushSize) async {
    if (!await imageFile.exists()) {
      debugPrint('Drawing overlay input file not found: ${imageFile.path}');
      return null;
    }

    final Uint8List bytes = await imageFile.readAsBytes();
    
    // We need to know base image dimensions for Canvas
    final img.Image? baseInfo = await compute(img.decodeImage, bytes);
    if (baseInfo == null) return null;

    // Render high-quality drawing using ui.Canvas (Must be on main thread)
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    final paint = ui.Paint()
      ..color = color
      ..strokeWidth = brushSize
      ..style = ui.PaintingStyle.stroke
      ..strokeCap = ui.StrokeCap.round
      ..strokeJoin = ui.StrokeJoin.round
      ..isAntiAlias = true;

    for (final path in paths) {
      canvas.drawPath(path, paint);
    }

    final picture = recorder.endRecording();
    final uiImage = await picture.toImage(baseInfo.width, baseInfo.height);
    final byteData = await uiImage.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) return null;
    final Uint8List overlayBytes = byteData.buffer.asUint8List();

    final tempDir = await getTemporaryDirectory();
    final String outputPath = '${tempDir.path}/drawing_${DateTime.now().millisecondsSinceEpoch}.jpg';

    final String? resultPath = await compute(_compositeOverlayIsolate, {
      'baseBytes': bytes,
      'overlayBytes': overlayBytes,
      'outputPath': outputPath,
      'x': 0,
      'y': 0,
    });

    if (resultPath != null) {
      return File(resultPath);
    }
    return null;
  }

  @override
  Future<File?> addEmojiOverlay(File imageFile, String emoji, {int x = 100, int y = 100, double fontSize = 64}) async {
    if (!await imageFile.exists()) {
      debugPrint('Emoji overlay input file not found: ${imageFile.path}');
      return null;
    }

    final Uint8List bytes = await imageFile.readAsBytes();

    // Render high-quality emoji using ui.Canvas (Main thread)
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);

    final textPainter = TextPainter(
      text: TextSpan(
        text: emoji,
        style: TextStyle(fontSize: fontSize),
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
    final Uint8List overlayBytes = byteData.buffer.asUint8List();

    final tempDir = await getTemporaryDirectory();
    final String outputPath = '${tempDir.path}/emoji_overlay_${DateTime.now().millisecondsSinceEpoch}.jpg';

    final String? resultPath = await compute(_compositeOverlayIsolate, {
      'baseBytes': bytes,
      'overlayBytes': overlayBytes,
      'outputPath': outputPath,
      'x': x,
      'y': y,
    });

    if (resultPath != null) {
      return File(resultPath);
    }
    return null;
  }

  @override
  Future<File?> applyBatchOverlays(File imageFile, List<OverlayModel> overlays) async {
    if (!await imageFile.exists()) return null;

    final Uint8List baseBytes = await imageFile.readAsBytes();
    
    // We need dimensions for drawing overlays
    final img.Image? baseInfo = await compute(img.decodeImage, baseBytes);
    if (baseInfo == null) return null;

    final List<Map<String, dynamic>> overlayData = [];

    for (final overlay in overlays) {
      if (overlay is TextOverlayModel) {
        final bytes = await _renderTextToBytes(overlay);
        if (bytes != null) {
          overlayData.add({
            'bytes': bytes,
            'x': overlay.x.round(),
            'y': overlay.y.round(),
          });
        }
      } else if (overlay is EmojiOverlayModel) {
        final bytes = await _renderEmojiToBytes(overlay);
        if (bytes != null) {
          overlayData.add({
            'bytes': bytes,
            'x': overlay.x.round(),
            'y': overlay.y.round(),
          });
        }
      } else if (overlay is DrawingOverlayModel) {
        final bytes = await _renderDrawingToBytes(overlay, baseInfo.width, baseInfo.height);
        if (bytes != null) {
          overlayData.add({
            'bytes': bytes,
            'x': 0,
            'y': 0,
          });
        }
      }
    }

    final tempDir = await getTemporaryDirectory();
    final String outputPath = '${tempDir.path}/batch_overlay_${DateTime.now().millisecondsSinceEpoch}.jpg';

    final String? resultPath = await compute(_applyBatchOverlaysIsolate, {
      'baseBytes': baseBytes,
      'overlays': overlayData,
      'outputPath': outputPath,
    });

    if (resultPath != null) {
      return File(resultPath);
    }
    return null;
  }

  Future<Uint8List?> _renderTextToBytes(TextOverlayModel overlay) async {
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);

    final textPainter = TextPainter(
      text: TextSpan(
        text: overlay.text,
        style: GoogleFonts.roboto(
          fontSize: overlay.fontSize,
          color: overlay.color,
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
    return byteData?.buffer.asUint8List();
  }

  Future<Uint8List?> _renderEmojiToBytes(EmojiOverlayModel overlay) async {
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);

    final textPainter = TextPainter(
      text: TextSpan(
        text: overlay.emoji,
        style: TextStyle(fontSize: overlay.fontSize),
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
    return byteData?.buffer.asUint8List();
  }

  Future<Uint8List?> _renderDrawingToBytes(DrawingOverlayModel overlay, int width, int height) async {
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    final paint = ui.Paint()
      ..color = overlay.color
      ..strokeWidth = overlay.brushSize
      ..style = ui.PaintingStyle.stroke
      ..strokeCap = ui.StrokeCap.round
      ..strokeJoin = ui.StrokeJoin.round
      ..isAntiAlias = true;

    for (final path in overlay.paths) {
      canvas.drawPath(path, paint);
    }

    final picture = recorder.endRecording();
    final uiImage = await picture.toImage(width, height);
    final byteData = await uiImage.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  }

  static Future<String?> _applyBatchOverlaysIsolate(Map<String, dynamic> params) async {
    try {
      final Uint8List baseBytes = params['baseBytes'];
      final List<Map<String, dynamic>> overlays = params['overlays'];
      final String outputPath = params['outputPath'];

      final img.Image? base = img.decodeImage(baseBytes);
      if (base == null) return null;

      for (final overlayData in overlays) {
        final Uint8List overlayBytes = overlayData['bytes'];
        final int x = overlayData['x'];
        final int y = overlayData['y'];

        final img.Image? overlay = img.decodePng(overlayBytes);
        if (overlay != null) {
          img.compositeImage(base, overlay, dstX: x, dstY: y);
        }
      }

      final Uint8List outputBytes = img.encodeJpg(base, quality: 95);
      final File outputFile = File(outputPath);
      await outputFile.writeAsBytes(outputBytes);

      return outputFile.path;
    } catch (e) {
      debugPrint('Error in _applyBatchOverlaysIsolate: $e');
      return null;
    }
  }
}
