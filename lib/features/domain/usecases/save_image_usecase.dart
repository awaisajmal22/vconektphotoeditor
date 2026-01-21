// lib/domain/usecases/save_image_usecase.dart
import 'dart:io';
import 'package:photo_editor/features/domain/repository/image_repository.dart';


class SaveImageUseCase {
  final ImageRepository repository;

  SaveImageUseCase(this.repository);

  Future<bool> execute(File imageFile) {
    return repository.saveImage(imageFile);
  }
}