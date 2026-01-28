import 'dart:io';

import 'package:image_cropper/image_cropper.dart';

class ImageCropService {
  static Future<File?> crop(File input) async {
    final result = await ImageCropper().cropImage(
      sourcePath: input.path,
      compressFormat: ImageCompressFormat.jpg,
      compressQuality: 92,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: '裁剪',
          lockAspectRatio: false,
          hideBottomControls: false,
          initAspectRatio: CropAspectRatioPreset.original,
        ),
        IOSUiSettings(
          title: '裁剪',
          aspectRatioLockEnabled: false,
        ),
      ],
    );
    if (result == null) {
      return null;
    }
    return File(result.path);
  }
}
