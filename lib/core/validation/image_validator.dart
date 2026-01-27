import 'dart:typed_data';

enum ImageValidationReason {
  notTarget,
  tooDark,
  tooBlurry,
  tooSmall,
  unknown,
}

class ImageValidationResult {
  final bool ok;
  final ImageValidationReason reason;
  final String message;
  final bool weakPass;
  final String? warning;

  const ImageValidationResult({
    required this.ok,
    required this.reason,
    required this.message,
    this.weakPass = false,
    this.warning,
  });

  factory ImageValidationResult.success({String? warning}) {
    return ImageValidationResult(
      ok: true,
      reason: ImageValidationReason.unknown,
      message: '',
      weakPass: warning != null,
      warning: warning,
    );
  }

  factory ImageValidationResult.failure({
    required ImageValidationReason reason,
    required String message,
  }) {
    return ImageValidationResult(
      ok: false,
      reason: reason,
      message: message,
    );
  }
}

abstract class ImageValidator {
  Future<ImageValidationResult> validate(Uint8List bytes);
}
