import 'dart:io';
import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../features/services/image_crop_service.dart';

enum ImageSourceFailureReason { permissionDenied, unavailable }

class ImageSourceFailure implements Exception {
  final ImageSourceFailureReason reason;

  const ImageSourceFailure(this.reason);
}

class ImageSelection {
  final Uint8List bytes;
  final ImageSourceType source;

  const ImageSelection({
    required this.bytes,
    required this.source,
  });
}

enum ImageSourceType { camera, gallery }

class ImageSourceService {
  ImageSourceService._();

  static final ImageSourceService instance = ImageSourceService._();
  final ImagePicker _picker = ImagePicker();

  Future<Uint8List?> pickFromCamera() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      throw const ImageSourceFailure(ImageSourceFailureReason.permissionDenied);
    }
    final picked = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 2000,
      maxHeight: 2000,
      imageQuality: 85,
    );
    if (picked == null) {
      return null;
    }
    final original = File(picked.path);
    final cropped = await ImageCropService.crop(original);
    final file = cropped ?? original;
    return file.readAsBytes();
  }

  Future<Uint8List?> pickFromGallery() async {
    final status = await _requestGalleryPermission();
    if (!status.isGranted) {
      throw const ImageSourceFailure(ImageSourceFailureReason.permissionDenied);
    }
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 2000,
      maxHeight: 2000,
      imageQuality: 85,
    );
    if (picked == null) {
      return null;
    }
    final original = File(picked.path);
    final cropped = await ImageCropService.crop(original);
    final file = cropped ?? original;
    return file.readAsBytes();
  }

  Future<PermissionStatus> _requestGalleryPermission() async {
    final photos = await Permission.photos.request();
    if (photos.isGranted) {
      return photos;
    }
    return Permission.storage.request();
  }
}
