import 'dart:io';
import 'package:photo_editor/core/model/overlay_model.dart';
import 'package:photo_editor/features/domain/repository/image_repository.dart';

class ApplyBatchOverlaysUseCase {
  final ImageRepository repository;

  ApplyBatchOverlaysUseCase(this.repository);

  Future<File?> execute(File imageFile, List<OverlayModel> overlays) async {
    return repository.applyBatchOverlays(imageFile, overlays);
  }
}
