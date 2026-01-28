import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'image_validator.dart';

class BasicImageValidator implements ImageValidator {
  @override
  Future<ImageValidationResult> validate(Uint8List bytes) async {
    if (bytes.isEmpty) {
      return ImageValidationResult(
        ok: true,
        reason: ImageValidationReason.unknown,
        message: '图片无法识别，请重新选择。',
        weakPass: true,
        warning: '图片无法识别，请重新选择。',
      );
    }

    final decoded = await _decode(bytes);
    if (decoded == null) {
      return ImageValidationResult(
        ok: true,
        reason: ImageValidationReason.unknown,
        message: '图片格式无法识别，请换一张图片。',
        weakPass: true,
        warning: '图片格式无法识别，请换一张图片。',
      );
    }

    final width = decoded.width;
    final height = decoded.height;
    if (min(width, height) < 400) {
      return ImageValidationResult(
        ok: true,
        reason: ImageValidationReason.tooSmall,
        message: '图片分辨率过低，请重新拍摄或选择清晰图片。',
        weakPass: true,
        warning: '图片分辨率过低，请重新拍摄或选择清晰图片。',
      );
    }

    final stats = await _analyze(decoded);
    if (stats.brightness < 0.25) {
      return ImageValidationResult(
        ok: true,
        reason: ImageValidationReason.tooDark,
        message: '图片偏暗，建议在光线充足环境下拍摄。',
        weakPass: true,
        warning: '图片偏暗，建议在光线充足环境下拍摄。',
      );
    }
    if (stats.sharpness < 0.035) {
      return ImageValidationResult(
        ok: true,
        reason: ImageValidationReason.tooBlurry,
        message: '图片偏模糊，请保持稳定并对焦清晰。',
        weakPass: true,
        warning: '图片偏模糊，请保持稳定并对焦清晰。',
      );
    }

    final aspectRatio = width / height;
    final looksLikeScreenshot = (aspectRatio > 1.9 || aspectRatio < 0.5) &&
        stats.stoolRatio < 0.05;
    if (looksLikeScreenshot) {
      return ImageValidationResult.success(
        warning: '图片内容不确定，结果仅供参考。',
      );
    }

    if (stats.stoolRatio < 0.02 && stats.blueGreenRatio > 0.45) {
      return ImageValidationResult.success(
        warning: '图片内容不确定，结果仅供参考。',
      );
    }

    if (stats.stoolRatio < 0.06) {
      return ImageValidationResult.success(
        warning: '图片内容不确定，结果仅供参考。',
      );
    }

    return ImageValidationResult.success();
  }

  Future<ui.Image?> _decode(Uint8List bytes) async {
    try {
      final codec = await ui.instantiateImageCodec(
        bytes,
        targetWidth: 128,
      );
      final frame = await codec.getNextFrame();
      return frame.image;
    } catch (_) {
      return null;
    }
  }

  Future<_ImageStats> _analyze(ui.Image image) async {
    final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (byteData == null) {
      return const _ImageStats(
        brightness: 1,
        sharpness: 0,
        stoolRatio: 0,
        blueGreenRatio: 0,
      );
    }

    final data = byteData.buffer.asUint8List();
    final length = data.length;
    double brightnessSum = 0;
    double edgeSum = 0;
    int count = 0;
    int stoolCount = 0;
    int blueGreenCount = 0;

    for (int i = 0; i < length; i += 4) {
      final r = data[i];
      final g = data[i + 1];
      final b = data[i + 2];
      final luminance = (0.2126 * r + 0.7152 * g + 0.0722 * b) / 255.0;
      brightnessSum += luminance;

      if (_isStoolTone(r, g, b)) {
        stoolCount++;
      }
      if (b > r && b > g || g > r && g > b) {
        blueGreenCount++;
      }

      if (i + 8 < length) {
        final r2 = data[i + 4];
        final g2 = data[i + 5];
        final b2 = data[i + 6];
        final lum2 = (0.2126 * r2 + 0.7152 * g2 + 0.0722 * b2) / 255.0;
        edgeSum += (luminance - lum2).abs();
      }
      count++;
    }

    if (count == 0) {
      return const _ImageStats(
        brightness: 1,
        sharpness: 0,
        stoolRatio: 0,
        blueGreenRatio: 0,
      );
    }

    return _ImageStats(
      brightness: brightnessSum / count,
      sharpness: edgeSum / count,
      stoolRatio: stoolCount / count,
      blueGreenRatio: blueGreenCount / count,
    );
  }

  bool _isStoolTone(int r, int g, int b) {
    final brownish = r > 80 && g > 40 && b < 80 && r >= g;
    final yellowish = r > 140 && g > 110 && b < 100;
    final reddish = r > 120 && g < 90 && b < 90;
    return brownish || yellowish || reddish;
  }
}

class _ImageStats {
  final double brightness;
  final double sharpness;
  final double stoolRatio;
  final double blueGreenRatio;

  const _ImageStats({
    required this.brightness,
    required this.sharpness,
    required this.stoolRatio,
    required this.blueGreenRatio,
  });
}
