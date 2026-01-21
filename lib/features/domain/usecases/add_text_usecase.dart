// lib/domain/usecases/add_text_overlay_usecase.dart
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:photo_editor/features/domain/repository/image_repository.dart';

class AddTextOverlayUseCase {
  final ImageRepository repository;

  AddTextOverlayUseCase(this.repository);

  Future<File?> execute(File imageFile, String text, {int x = 50, int y = 50, double fontSize = 32, ui.Color? textColor}) {
    return repository.addTextOverlay(imageFile, text, x: x, y: y, fontSize: fontSize, textColor: textColor);
  }
}