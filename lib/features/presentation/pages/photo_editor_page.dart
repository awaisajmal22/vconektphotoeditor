// lib/features/presentation/pages/photo_editor_page.dart
import 'dart:math' as math;

import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart' hide Config;
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:photo_editor/core/model/image_model.dart';
import 'package:photo_editor/core/model/overlay_model.dart';
import 'package:photo_editor/core/utils/utils.dart';
import 'package:photo_editor/features/domain/repository/image_repository.dart';
import 'package:photo_editor/features/domain/usecases/add_drawing_usecase.dart';
import 'package:photo_editor/features/domain/usecases/add_emoji_usecase.dart';
import 'package:photo_editor/features/domain/usecases/add_sticker_usecase.dart';
import 'package:photo_editor/features/domain/usecases/add_text_usecase.dart';
import 'package:photo_editor/features/domain/usecases/apply_batch_overlays_usecase.dart';
import 'package:photo_editor/features/domain/usecases/apply_filter_usecase.dart';
import 'package:photo_editor/features/domain/usecases/create_collage_usecase.dart';
import 'package:photo_editor/features/domain/usecases/crop_image_usecase.dart';
import 'package:photo_editor/features/domain/usecases/pick_image_usecase.dart';
import 'package:photo_editor/features/domain/usecases/pick_multi_image_usecase.dart';
import 'package:photo_editor/features/domain/usecases/save_image_usecase.dart' show SaveImageUseCase;

// Widgets
import '../widgets/action_buttons.dart';
import '../widgets/filter_preview.dart';
import '../widgets/overlay_widgets.dart';

class PhotoEditorScreen extends StatefulWidget {
  final ImageRepository repository;

  const PhotoEditorScreen({super.key, required this.repository});

  @override
  State<PhotoEditorScreen> createState() => _PhotoEditorScreenState();
}

class _PhotoEditorScreenState extends State<PhotoEditorScreen>
    with TickerProviderStateMixin {
  ImageModel? _currentImage;
  ImageModel? _originalImage;
  List<File> _collageImages = [];
  String _selectedFilter = 'none';
  bool _isLoadingPreview = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  late final PickImageUseCase _pickImageUseCase;
  late final PickMultipleImagesUseCase _pickMultipleImagesUseCase;
  late final CreateCollageUseCase _createCollageUseCase;
  late final ApplyFilterUseCase _applyFilterUseCase;
  late final SaveImageUseCase _saveImageUseCase;
  late final CropImageUseCase _cropImageUseCase;
  late final AddTextOverlayUseCase _addTextOverlayUseCase;
  late final AddStickerUseCase _addStickerUseCase;
  late final AddEmojiOverlayUseCase _addEmojiOverlayUseCase;
  late final AddDrawingOverlayUseCase _addDrawingOverlayUseCase;
  late final ApplyBatchOverlaysUseCase _applyBatchOverlaysUseCase;

  final GlobalKey _stackKey = GlobalKey();

  bool _showTextInput = false;
  String _inputText = '';
  Color _textColor = Colors.white;
  final List<String> _addedTexts = [];
  final List<Offset> _textPositions = [];
  final List<Color> _textColors = [];

  bool _showEmojiPicker = false;
  final List<String> _addedStickers = [];
  final List<Offset> _stickerPositions = [];

  bool _isDrawingMode = false;
  Color _drawingColor = Colors.black;
  double _brushSize = 5.0;
  final List<ui.Path> _drawingPaths = [];
  ui.Path _currentPath = ui.Path();

  @override
  void initState() {
    super.initState();
    _pickImageUseCase = PickImageUseCase(widget.repository);
    _pickMultipleImagesUseCase = PickMultipleImagesUseCase(widget.repository);
    _createCollageUseCase = CreateCollageUseCase(widget.repository);
    _applyFilterUseCase = ApplyFilterUseCase(widget.repository);
    _saveImageUseCase = SaveImageUseCase(widget.repository);
    _cropImageUseCase = CropImageUseCase(widget.repository);
    _addTextOverlayUseCase = AddTextOverlayUseCase(widget.repository);
    _addStickerUseCase = AddStickerUseCase(widget.repository);
    _addEmojiOverlayUseCase = AddEmojiOverlayUseCase(widget.repository);
    _addDrawingOverlayUseCase = AddDrawingOverlayUseCase(widget.repository);
    _applyBatchOverlaysUseCase = ApplyBatchOverlaysUseCase(widget.repository);

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_animationController);
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [colorScheme.primary, colorScheme.secondary],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  _buildAppBar(colorScheme),
                  Expanded(
                    child: _currentImage == null
                        ? _buildNoImageView(colorScheme)
                        : _buildImageView(),
                  ),
                  if (_currentImage != null) ...[
                    _buildFilterCarousel(),
                    if (_isDrawingMode) _buildDrawingControls(),
                    if (_showTextInput) _buildTextInputField(),
                    _buildSaveButton(colorScheme),
                  ],
                ],
              ),
              if (_showEmojiPicker) _buildEmojiPicker(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(ColorScheme colorScheme) {
    return Container(
      width: MediaQuery.of(context).size.width,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.transparent, Colors.black.withOpacity(0.1)],
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.edit, color: Colors.white, size: 28),
          const SizedBox(width: 8),
          Text(
            'CapCut Lite',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white),
          ),
          if (_currentImage == null) const Spacer(),
          Expanded(
            child: AnimatedBuilder(
              animation: _fadeAnimation,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeAnimation.value,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        if (_currentImage?.isFiltered == true)
                          ActionButton(
                            Icons.undo,
                            'Undo',
                            _undoFilter,
                            Colors.white,
                          ),
                        if (_currentImage != null)
                          ActionButton(
                            Icons.crop,
                            'Crop',
                            _cropImage,
                            Colors.white,
                          ),
                        if (_currentImage == null || !_currentImage!.isCollage)
                          ActionButton(
                            Icons.collections,
                            'Collage',
                            _createCollage,
                            Colors.white,
                          ),
                        if (_currentImage?.isCollage == true &&
                            _collageImages.length < 6)
                          ActionButtonWithBadge(
                            Icons.add_photo_alternate,
                            'Add More',
                            () => _addToCollage(),
                            Colors.white,
                            _collageImages.length,
                            6,
                          ),
                        if (_currentImage != null)
                          ActionButton(
                            Icons.text_fields,
                            'Text',
                            _toggleTextInput,
                            Colors.white,
                          ),
                        if (_currentImage != null)
                          ActionButton(
                            Icons.emoji_emotions,
                            'Stickers',
                            () => setState(() => _showEmojiPicker = !_showEmojiPicker),
                            Colors.white,
                          ),
                        if (_currentImage != null)
                          ActionButton(
                            Icons.brush,
                            'Draw',
                            () => setState(() => _isDrawingMode = !_isDrawingMode),
                            Colors.white,
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoImageView(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.add_photo_alternate,
            size: 80,
            color: Colors.white70,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _pickImage,
            icon: const Icon(Icons.folder_open),
            label: const Text('Pick Image'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageView() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(color: Colors.black26, blurRadius: 10),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              key: _stackKey,
              children: [
                Hero(
                  tag: 'main_image',
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 500),
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: value,
                        child: Image.file(_currentImage!.file, fit: BoxFit.contain),
                      );
                    },
                  ),
                ),
                if (_isDrawingMode)
                  DrawingOverlay(
                    onPanStart: _onPanStart,
                    onPanUpdate: _onPanUpdate,
                    onPanEnd: _onPanEnd,
                    paths: _drawingPaths,
                    currentPath: _currentPath,
                    color: _drawingColor,
                    brushSize: _brushSize,
                  ),
                OverlayManager(
                  inputText: _inputText,
                  textColor: _textColor,
                  addedTexts: _addedTexts,
                  textPositions: _textPositions,
                  textColors: _textColors,
                  onTextDrag: (index, delta) {
                    setState(() {
                      _textPositions[index] += delta;
                      final RenderBox? box = _stackKey.currentContext?.findRenderObject() as RenderBox?;
                      if (box != null) {
                        _textPositions[index] = Offset(
                          _textPositions[index].dx.clamp(0, box.size.width - 60),
                          _textPositions[index].dy.clamp(0, box.size.height - 40),
                        );
                      }
                    });
                  },
                  addedStickers: _addedStickers,
                  stickerPositions: _stickerPositions,
                  onStickerDrag: (index, delta) {
                    setState(() {
                      _stickerPositions[index] += delta;
                      final RenderBox? box = _stackKey.currentContext?.findRenderObject() as RenderBox?;
                      if (box != null) {
                        _stickerPositions[index] = Offset(
                          _stickerPositions[index].dx.clamp(0, box.size.width - 40),
                          _stickerPositions[index].dy.clamp(0, box.size.height - 40),
                        );
                      }
                    });
                  },
                ),
              ],
            ),
          ),
        );
      }
    );
  }

  Widget _buildFilterCarousel() {
    return AnimatedOpacity(
      opacity: _isLoadingPreview ? 0.5 : 1.0,
      duration: const Duration(milliseconds: 200),
      child: Container(
        height: 100,
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: _isLoadingPreview
            ? const Center(
                child: CircularProgressIndicator(color: Colors.white),
              )
            : ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: FilterUtils.availableFilters.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final filter = FilterUtils.availableFilters[index];
                  return FilterPreview(
                    filter: filter,
                    isSelected: _selectedFilter == filter['key'],
                    onTap: () => _applyFilter(filter['key']),
                    thumbnailFuture: _generateThumbnail(filter['key']),
                  );
                },
              ),
      ),
    );
  }

  Future<Uint8List> _generateThumbnail(String filterKey) async {
    if (_originalImage == null) return Uint8List(0);
    final bytes = await _originalImage!.file.readAsBytes();
    
    return compute(_generateThumbnailIsolate, {
      'bytes': bytes,
      'filterKey': filterKey,
    });
  }

  static Uint8List _generateThumbnailIsolate(Map<String, dynamic> params) {
    final Uint8List bytes = params['bytes'];
    final String filterKey = params['filterKey'];
    
    final original = img.decodeImage(bytes)!;
    final thumbnail = FilterUtils.applyFilterThumbnail(original, filterKey);
    return Uint8List.fromList(img.encodeJpg(thumbnail, quality: 50)); // Lower quality for thumbnails
  }

  Widget _buildDrawingControls() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          GestureDetector(
            onTap: () => _showColorPicker(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _drawingColor,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.palette, color: Colors.white, size: 20),
            ),
          ),
          IconButton(
            onPressed: _bakeDrawing,
            icon: const Icon(Icons.check_circle, color: Colors.green, size: 32),
            tooltip: 'Apply Drawing',
          ),
          IconButton(
            onPressed: () => setState(() => _drawingPaths.clear()),
            icon: const Icon(Icons.delete_sweep, color: Colors.white70, size: 28),
            tooltip: 'Clear Drawing',
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Brush Size', style: TextStyle(color: Colors.white)),
                Slider(
                  value: _brushSize,
                  min: 1.0,
                  max: 20.0,
                  onChanged: (value) => setState(() => _brushSize = value),
                  activeColor: _drawingColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextInputField() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      color: Colors.black.withOpacity(0.8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (value) => setState(() => _inputText = value),
                  decoration: InputDecoration(
                    hintText: 'Enter text',
                    hintStyle: const TextStyle(color: Colors.white70),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.1),
                    border: const OutlineInputBorder(borderSide: BorderSide.none),
                    suffixIcon: _inputText.isNotEmpty 
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: _addText,
                              icon: const Icon(Icons.check, color: Colors.green),
                            ),
                            IconButton(
                              onPressed: _clearText,
                              icon: const Icon(Icons.clear, color: Colors.white70),
                            ),
                          ],
                        )
                      : null,
                  ),
                  style: const TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _textColorButton(Colors.white),
                _textColorButton(Colors.black),
                _textColorButton(Colors.red),
                _textColorButton(Colors.blue),
                _textColorButton(Colors.green),
                _textColorButton(Colors.yellow),
                _textColorButton(Colors.orange),
                _textColorButton(Colors.purple),
                _textColorButton(Colors.pink),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _textColorButton(Color color) {
    return GestureDetector(
      onTap: () => setState(() => _textColor = color),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: _textColor == color ? Colors.white : Colors.transparent,
            width: 2,
          ),
        ),
      ),
    );
  }

  void _toggleTextInput() {
    setState(() {
      _showTextInput = !_showTextInput;
    });
  }

  void _clearText() {
    setState(() {
      _inputText = '';
    });
  }

  void _addText() {
    if (_inputText.trim().isEmpty) return;
    setState(() {
      _addedTexts.add(_inputText);
      _textPositions.add(const Offset(50, 50));
      _textColors.add(_textColor);
      _inputText = '';
      _showTextInput = false;
    });
  }

  Future<Map<String, double>> _getScaleFactors() async {
    if (_currentImage == null) return {'scale': 1.0, 'offsetX': 0.0, 'offsetY': 0.0};

    final RenderBox? box = _stackKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return {'scale': 1.0, 'offsetX': 0.0, 'offsetY': 0.0};

    final Uint8List bytes = await _currentImage!.file.readAsBytes();
    final ui.ImmutableBuffer buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
    final ui.ImageDescriptor descriptor = await ui.ImageDescriptor.encoded(buffer);
    
    final double imageW = descriptor.width.toDouble();
    final double imageH = descriptor.height.toDouble();
    descriptor.dispose();
    buffer.dispose();

    final double screenW = box.size.width;
    final double screenH = box.size.height;

    final double scaleX = screenW / imageW;
    final double scaleY = screenH / imageH;
    final double scale = math.min(scaleX, scaleY);

    final double displayedW = imageW * scale;
    final double displayedH = imageH * scale;

    final double offsetX = (screenW - displayedW) / 2;
    final double offsetY = (screenH - displayedH) / 2;

    return {
      'scale': scale,
      'offsetX': offsetX,
      'offsetY': offsetY,
      'imageW': imageW,
      'imageH': imageH,
    };
  }

  Widget _buildSaveButton(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: ElevatedButton.icon(
        onPressed: _saveImage,
        icon: const Icon(Icons.save),
        label: const Text('Save to Gallery'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: colorScheme.primary,
          minimumSize: const Size(double.infinity, 50),
        ),
      ),
    );
  }

  Widget _buildEmojiPicker() {
    return SizedBox(
      height: 300,
      child: EmojiPicker(
        onEmojiSelected: (category, emoji) {
          _addSticker(emoji.emoji);
        },
        config: Config(
          height: 300,
          checkPlatformCompatibility: true,
          locale: const Locale('en'),
          emojiTextStyle: const TextStyle(fontSize: 28, color: Colors.white),
          customBackspaceIcon: const Icon(Icons.backspace, color: Colors.white),
          customSearchIcon: const Icon(Icons.search, color: Colors.white),
        ),
      ),
    );
  }

  void _showColorPicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Color'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _colorButton(Colors.black),
                  _colorButton(Colors.red),
                  _colorButton(Colors.blue),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _colorButton(Colors.green),
                  _colorButton(Colors.yellow),
                  _colorButton(Colors.purple),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _colorButton(Color color) {
    return GestureDetector(
      onTap: () {
        setState(() => _drawingColor = color);
        Navigator.pop(context);
      },
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }

  void _onPanStart(DragStartDetails details) {
    setState(() {
      _currentPath.moveTo(details.localPosition.dx, details.localPosition.dy);
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _currentPath.lineTo(details.localPosition.dx, details.localPosition.dy);
    });
  }

  void _onPanEnd(DragEndDetails details) {
    _drawingPaths.add(_currentPath);
    _currentPath = ui.Path();
  }

  Future<void> _bakeDrawing() async {
    if (_originalImage == null || _drawingPaths.isEmpty) return;

    setState(() => _isLoadingPreview = true);
    final factors = await _getScaleFactors();
    final double scale = factors['scale']!;
    final double offsetX = factors['offsetX']!;
    final double offsetY = factors['offsetY']!;

    final List<ui.Path> scaledPaths = _drawingPaths.map((path) {
      final Matrix4 matrix = Matrix4.identity()
        ..translate(-offsetX, -offsetY)
        ..scale(1 / scale);
      return path.transform(matrix.storage);
    }).toList();

    final newFile = await _addDrawingOverlayUseCase.execute(
      _originalImage!.file,
      scaledPaths,
      _drawingColor,
      _brushSize / scale,
    );
    if (newFile != null) {
      setState(() {
        _originalImage = ImageModel(
          file: newFile,
          isCollage: _originalImage!.isCollage,
        );
        _currentImage = _originalImage;
        _drawingPaths.clear();
      });
    }
    setState(() => _isLoadingPreview = false);
  }

  void _addSticker(String emojiUnicode) {
    setState(() {
      _addedStickers.add(emojiUnicode);
      _stickerPositions.add(const Offset(100, 100));
      _showEmojiPicker = false;
    });
  }

  Future<void> _applyFilter(String filter) async {
    if (_originalImage != null) {
      setState(() => _isLoadingPreview = true);
      final editedFile = await _applyFilterUseCase.execute(
        _originalImage!.file,
        filter,
      );
      setState(() {
        _currentImage = ImageModel(
          file: editedFile,
          filterName: filter != 'none' ? filter : null,
          isFiltered: filter != 'none',
          isCollage: _originalImage!.isCollage,
        );
        _selectedFilter = filter;
        _isLoadingPreview = false;
      });
    }
  }

  void _undoFilter() {
    if (_originalImage != null) {
      setState(() {
        _currentImage = ImageModel(
          file: _originalImage!.file,
          filterName: null,
          isFiltered: false,
          isCollage: _originalImage!.isCollage,
        );
        _selectedFilter = 'none';
      });
    }
  }

  Future<void> _cropImage() async {
    if (_currentImage != null) {
      final cropped = await _cropImageUseCase.execute(_currentImage!.file);
      if (cropped != null) {
        final newModel = ImageModel(
          file: cropped,
          isFiltered: false,
          isCollage: _currentImage!.isCollage,
        );
        setState(() {
          _originalImage = newModel;
          _currentImage = newModel;
          _selectedFilter = 'none';
          _isLoadingPreview = true;
        });
        Future.delayed(
          const Duration(milliseconds: 500),
          () => setState(() => _isLoadingPreview = false),
        );
      }
    }
  }

  Future<void> _pickImage() async {
    final image = await _pickImageUseCase.execute();
    if (image != null) {
      final baseModel = ImageModel(
        file: image.file,
        isFiltered: false,
        isCollage: false,
      );
      setState(() {
        _originalImage = baseModel;
        _currentImage = baseModel;
        _selectedFilter = 'none';
        _collageImages.clear();
        _inputText = '';
        _showTextInput = false;
        _addedStickers.clear();
        _stickerPositions.clear();
        _drawingPaths.clear();
      });
      _animationController.reset();
      _animationController.forward();
    }
  }

  Future<void> _createCollage() async {
    final images = await _pickMultipleImagesUseCase.execute();
    if (images != null && images.isNotEmpty) {
      setState(() {
        _collageImages = images.map((m) => m.file).toList();
        _isLoadingPreview = true;
      });
      final collageFile = await _createCollageUseCase.execute(_collageImages);
      if (collageFile != null) {
        final newModel = ImageModel(
          file: collageFile,
          isFiltered: false,
          isCollage: true,
        );
        setState(() {
          _originalImage = newModel;
          _currentImage = newModel;
          _selectedFilter = 'none';
          _isLoadingPreview = false;
          _inputText = '';
          _showTextInput = false;
          _addedStickers.clear();
          _stickerPositions.clear();
          _drawingPaths.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Collage created with ${_collageImages.length} images!',
            ),
            backgroundColor: Colors.deepPurple,
          ),
        );
      }
    } else if (images != null && images.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select at least 2 images for a collage.'),
          backgroundColor: Colors.orange,
          action: SnackBarAction(
            label: 'Pick Single',
            textColor: Colors.white,
            onPressed: _pickImage,
          ),
        ),
      );
    }
  }

  Future<void> _addToCollage() async {
    final maxAdd = 6 - _collageImages.length;
    if (maxAdd <= 0) return;

    final addImages = await _pickMultipleImagesUseCase.execute(maxImages: maxAdd, minImages: 1);
    if (addImages != null && addImages.isNotEmpty) {
      setState(() {
        _collageImages.addAll(addImages.map((m) => m.file));
        _isLoadingPreview = true;
      });
      final updatedFile = await _createCollageUseCase.execute(_collageImages);
      if (updatedFile != null) {
        final newModel = ImageModel(
          file: updatedFile,
          isFiltered: false,
          isCollage: true,
        );
        setState(() {
          _originalImage = newModel;
          _currentImage = newModel;
          _selectedFilter = 'none';
          _isLoadingPreview = false;
          _inputText = '';
          _showTextInput = false;
          _addedStickers.clear();
          _stickerPositions.clear();
          _drawingPaths.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added ${addImages.length} more images!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _saveImage() async {
    if (_currentImage == null) return;

    setState(() => _isLoadingPreview = true);
    
    final factors = await _getScaleFactors();
    final double scale = factors['scale']!;
    final double offsetX = factors['offsetX']!;
    final double offsetY = factors['offsetY']!;

    final List<OverlayModel> overlays = [];

    // Add texts
    for (int i = 0; i < _addedTexts.length; i++) {
      overlays.add(TextOverlayModel(
        x: (_textPositions[i].dx - offsetX) / scale,
        y: (_textPositions[i].dy - offsetY) / scale,
        text: _addedTexts[i],
        color: _textColors[i],
        fontSize: 32 / scale,
      ));
    }

    // Add emojis/stickers
    for (int i = 0; i < _addedStickers.length; i++) {
      overlays.add(EmojiOverlayModel(
        x: (_stickerPositions[i].dx - offsetX) / scale,
        y: (_stickerPositions[i].dy - offsetY) / scale,
        emoji: _addedStickers[i],
        fontSize: 64 / scale,
      ));
    }

    // Add drawing if any
    if (_drawingPaths.isNotEmpty) {
      final scaledPaths = _drawingPaths.map((path) {
        final Matrix4 matrix = Matrix4.identity()
          ..translate(-offsetX, -offsetY)
          ..scale(1 / scale);
        return path.transform(matrix.storage);
      }).toList();

      overlays.add(DrawingOverlayModel(
        paths: scaledPaths,
        color: _drawingColor,
        brushSize: _brushSize / scale,
      ));
    }

    File finalFile = _currentImage!.file;
    if (overlays.isNotEmpty) {
      final processedFile = await _applyBatchOverlaysUseCase.execute(
        _currentImage!.file,
        overlays,
      );
      if (processedFile != null) {
        finalFile = processedFile;
      }
    }

    final success = await _saveImageUseCase.execute(finalFile);
    setState(() => _isLoadingPreview = false);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Saved to Gallery!' : 'Save failed'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }

    if (success) {
      setState(() {
        _inputText = '';
        _showTextInput = false;
        _addedTexts.clear();
        _textPositions.clear();
        _textColors.clear();
        _addedStickers.clear();
        _stickerPositions.clear();
        _drawingPaths.clear();
      });
    }
  }
}
