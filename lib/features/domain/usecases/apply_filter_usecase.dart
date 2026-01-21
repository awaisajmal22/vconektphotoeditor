// lib/domain/usecases/apply_filter_usecase.dart
import 'dart:io';
import 'package:photo_editor/features/domain/repository/image_repository.dart';

class ApplyFilterUseCase {
  final ImageRepository repository;

  ApplyFilterUseCase(this.repository);

  Future<File> execute(File imageFile, String filterType) {
    return repository.applyFilter(imageFile, filterType);
  }
}