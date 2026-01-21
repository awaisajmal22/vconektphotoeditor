// lib/domain/usecases/pick_image_usecase.dart
import 'package:image_picker/image_picker.dart';
import 'package:photo_editor/core/model/image_model.dart';
import 'package:photo_editor/features/domain/repository/image_repository.dart';



class PickImageUseCase {
  final ImageRepository repository;

  PickImageUseCase(this.repository);

  Future<ImageModel?> execute({ImageSource source = ImageSource.gallery}) {
    return repository.pickImage(source: source);
  }
}