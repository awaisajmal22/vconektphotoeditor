import 'dart:io';
import 'dart:io';

class ImageModel {
  final File file;
  final String? filterName;
  final bool isFiltered;
  final bool isCollage;  // NEW: For collage flag

  ImageModel({
    required this.file,
    this.filterName,
    this.isFiltered = false,
    this.isCollage = false,
  });

  // Helper for collage (wrap single in list)
  static List<ImageModel> fromSingle(ImageModel model) => [model];
}