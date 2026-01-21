// lib/domain/usecases/add_sticker_usecase.dart
import 'dart:io';

import 'package:photo_editor/features/domain/repository/image_repository.dart';

class AddStickerUseCase {
  final ImageRepository repository;

  AddStickerUseCase(this.repository);

  Future<File?> execute(File imageFile, String stickerPath, {int x = 100, int y = 100, double scale = 1.0}) {
    return repository.addSticker(imageFile, stickerPath, x: x, y: y, scale: scale);
  }
}