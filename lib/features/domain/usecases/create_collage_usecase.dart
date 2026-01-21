// lib/domain/usecases/create_collage_usecase.dart
import 'dart:io';
import 'package:photo_editor/features/domain/repository/image_repository.dart';


class CreateCollageUseCase {
  final ImageRepository repository;

  CreateCollageUseCase(this.repository);

  Future<File?> execute(List<File> images) {
    return repository.createCollage(images);
  }
}