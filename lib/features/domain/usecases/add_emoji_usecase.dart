import 'dart:io';
import 'package:photo_editor/features/domain/repository/image_repository.dart';

class AddEmojiOverlayUseCase {
  final ImageRepository repository;

  AddEmojiOverlayUseCase(this.repository);

  Future<File?> execute(File imageFile, String emoji, {int x = 100, int y = 100, double fontSize = 64}) {
    return repository.addEmojiOverlay(imageFile, emoji, x: x, y: y, fontSize: fontSize);
  }
}
