// lib/domain/usecases/add_drawing_overlay_usecase.dart
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:photo_editor/features/domain/repository/image_repository.dart';

class AddDrawingOverlayUseCase {
  final ImageRepository repository;

  AddDrawingOverlayUseCase(this.repository);

  Future<File?> execute(File imageFile, List<ui.Path> paths, Color color, double brushSize) {
    return repository.addDrawingOverlay(imageFile, paths, color, brushSize);
  }
}