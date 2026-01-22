// lib/core/utils/filter_utils.dart
import 'package:image/image.dart' as img;

class FilterUtils {
  static const List<Map<String, dynamic>> availableFilters = [
    {'key': 'none', 'name': 'Original'},
    {'key': 'grayscale', 'name': 'Grayscale'},
    {'key': 'sepia', 'name': 'Sepia'},
    {'key': 'brightness', 'name': 'Brightness'},
    {'key': 'vintage', 'name': 'Vintage'},
    {'key': 'retro', 'name': 'Retro'},
    {'key': 'high_contrast_bw', 'name': 'High Contrast B/W'},
    {'key': 'teal_and_orange', 'name': 'Teal & Orange'},
    {'key': 'soft_focus', 'name': 'Soft Focus'},
    {'key': 'glow', 'name': 'Glow'},
    {'key': 'vibrant', 'name': 'Vibrant'},
    {'key': 'fresh', 'name': 'Fresh'},
    {'key': 'warmth', 'name': 'Warmth'},
    {'key': 'faded_film', 'name': 'Faded Film'},
    {'key': 'lomo', 'name': 'Lomo'},
    {'key': 'sketch', 'name': 'Sketch'},
    {'key': 'night_vision', 'name': 'Night Vision'},
    {'key': 'haze', 'name': 'Haze'},
  ];

  static img.Image grayscale(img.Image image) {
    return img.grayscale(image);
  }

  static img.Image sepia(img.Image image) {
    final result = img.Image(width: image.width, height: image.height);
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixelSafe(x, y);
        final r = pixel.r.toInt();
        final g = pixel.g.toInt();
        final b = pixel.b.toInt();
        final newR = (0.393 * r + 0.769 * g + 0.189 * b).round().clamp(0, 255);
        final newG = (0.349 * r + 0.686 * g + 0.168 * b).round().clamp(0, 255);
        final newB = (0.272 * r + 0.534 * g + 0.131 * b).round().clamp(0, 255);
        final a = pixel.a.toInt();
        result.setPixelRgba(x, y, newR, newG, newB, a);
      }
    }
    return result;
  }

  static img.Image brightness(img.Image image, double factor) {
    return img.adjustColor(image, brightness: (factor - 1) * 100);
  }

  static img.Image vintage(img.Image image) {
    var vintage = sepia(image);
    vintage = img.adjustColor(vintage, contrast: -10, brightness: -10);
    return img.adjustColor(vintage, saturation: -20);
  }

  static img.Image retro(img.Image image) {
    var retro = img.adjustColor(image, contrast: 20, brightness: 10);
    retro = img.adjustColor(retro, saturation: -30);
    return retro;
  }

  static img.Image highContrastBw(img.Image image) {
    var bw = grayscale(image);
    return img.adjustColor(bw, contrast: 50);
  }

  static img.Image tealAndOrange(img.Image image) {
    // Manual channel adjustment using pixel properties
    final result = img.Image(width: image.width, height: image.height);
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixelSafe(x, y);
        final r = pixel.r.toInt();
        final g = pixel.g.toInt();
        final b = pixel.b.toInt();
        final newR = (r * 1.2).round().clamp(0, 255);
        final newG = (g * 0.8).round().clamp(0, 255);
        final newB = (b * 1.1).round().clamp(0, 255);
        final a = pixel.a.toInt();
        result.setPixelRgba(x, y, newR, newG, newB, a);
      }
    }
    return result;
  }

  static img.Image softFocus(img.Image image) {
    // Fixed: Use single 'radius' parameter
    var blurred = img.gaussianBlur(image, radius: 2);
    return img.compositeImage(image, blurred, blend: img.BlendMode.screen);
  }

  static img.Image glow(img.Image image) {
    // Fixed: Use single 'radius' parameter
    var blurred = img.gaussianBlur(image, radius: 5);
    return img.compositeImage(image, blurred, blend: img.BlendMode.screen);
  }

  static img.Image vibrant(img.Image image) {
    return img.adjustColor(image, saturation: 30, contrast: 10);
  }

  static img.Image fresh(img.Image image) {
    return img.adjustColor(image, brightness: 10, contrast: 5, saturation: 10);
  }

  static img.Image warmth(img.Image image) {
    // Manual implementation of warmth using pixel properties
    final result = img.Image(width: image.width, height: image.height);
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixelSafe(x, y);
        final r = pixel.r.toInt();
        final g = pixel.g.toInt();
        final b = pixel.b.toInt();
        final newR = (r * 1.0).round().clamp(0, 255);
        final newG = (g * 0.9).round().clamp(0, 255);
        final newB = (b * 1.1).round().clamp(0, 255);
        final a = pixel.a.toInt();
        result.setPixelRgba(x, y, newR, newG, newB, a);
      }
    }
    return result;
  }

  static img.Image fadedFilm(img.Image image) {
    var faded = img.adjustColor(image, brightness: -10, contrast: -20);
    faded = img.adjustColor(faded, saturation: -40);
    return faded;
  }

  static img.Image lomo(img.Image image) {
    var lomo = img.adjustColor(image, brightness: 10, contrast: 30, saturation: 20);
    return img.vignette(lomo, amount: 0.5);
  }

  static img.Image sketch(img.Image image) {
    var gray = img.grayscale(image);
    var inverted = img.invert(gray);
    var blurred = img.gaussianBlur(inverted, radius: 10);
    var sketch = img.Image(width: gray.width, height: gray.height);
    for (int y = 0; y < gray.height; y++) {
      for (int x = 0; x < gray.width; x++) {
        final p1 = gray.getPixel(x, y);
        final p2 = blurred.getPixel(x, y);
        final v1 = p1.r.toInt();
        final v2 = p2.r.toInt();
        // Color dodge blend
        final val = (v2 == 255) ? 255 : (v1 << 8) ~/ (255 - v2);
        final finalVal = val.clamp(0, 255);
        sketch.setPixelRgba(x, y, finalVal, finalVal, finalVal, p1.a.toInt());
      }
    }
    return sketch;
  }

  static img.Image nightVision(img.Image image) {
    final result = img.Image(width: image.width, height: image.height);
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        final g = pixel.g.toInt();
        // Boost green, reduce R and B
        result.setPixelRgba(x, y, (pixel.r * 0.1).round(), (g * 1.5).round().clamp(0, 255), (pixel.b * 0.1).round(), pixel.a.toInt());
      }
    }
    return img.adjustColor(result, contrast: 20);
  }

  static img.Image haze(img.Image image) {
    var hazy = img.adjustColor(image, contrast: -20, brightness: 10);
    return img.gaussianBlur(hazy, radius: 1);
  }

  static img.Image applyFilterThumbnail(img.Image image, String key) {
    switch (key) {
      case 'grayscale': return grayscale(image);
      case 'sepia': return sepia(image);
      case 'brightness': return brightness(image, 1.2);
      case 'vintage': return vintage(image);
      case 'retro': return retro(image);
      case 'high_contrast_bw': return highContrastBw(image);
      case 'teal_and_orange': return tealAndOrange(image);
      case 'soft_focus': return softFocus(image);
      case 'glow': return glow(image);
      case 'vibrant': return vibrant(image);
      case 'fresh': return fresh(image);
      case 'warmth': return warmth(image);
      case 'faded_film': return fadedFilm(image);
      case 'lomo': return lomo(image);
      case 'sketch': return sketch(image);
      case 'night_vision': return nightVision(image);
      case 'haze': return haze(image);
      default: return image;
    }
  }
}