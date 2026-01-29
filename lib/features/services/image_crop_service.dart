import 'dart:io';

import 'package:image_cropper/image_cropper.dart';

class ImageCropService {
  static bool _isCropping = false;

  static Future<File?> crop(File input) async {
    if (_isCropping) {
      return null;
    }
    _isCropping = true;
    try {
      final result = await ImageCropper().cropImage(
        sourcePath: input.path,
        compressFormat: ImageCompressFormat.jpg,
        compressQuality: 92,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: '请让便便占画面 ≥50%',
            lockAspectRatio: false,
            hideBottomControls: false,
            initAspectRatio: CropAspectRatioPreset.original,
          ),
          IOSUiSettings(
            title: '请让便便占画面 ≥50%',
            aspectRatioLockEnabled: false,
          ),
        ],
      );
      if (result == null) {
        return null;
      }
      return File(result.path);
    } catch (_) {
      return null;
    } finally {
      _isCropping = false;
    }
  }
}
