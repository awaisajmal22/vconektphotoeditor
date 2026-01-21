// lib/domain/usecases/crop_image_usecase.dart
import 'dart:io';
import 'package:photo_editor/features/domain/repository/image_repository.dart';


class CropImageUseCase {
  final ImageRepository repository;

  CropImageUseCase(this.repository);

  Future<File?> execute(File imageFile) {
    return repository.cropImage(imageFile);
  }
}