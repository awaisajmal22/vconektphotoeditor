// lib/domain/usecases/pick_multiple_images_usecase.dart

import 'package:photo_editor/core/model/image_model.dart';
import 'package:photo_editor/features/domain/repository/image_repository.dart';

class PickMultipleImagesUseCase {
  final ImageRepository repository;

  PickMultipleImagesUseCase(this.repository);

  Future<List<ImageModel>?> execute({int maxImages = 6, int minImages = 2}) {
    return repository.pickMultipleImages(maxImages: maxImages, minImages: minImages);
  }
}