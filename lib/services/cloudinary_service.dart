// lib/services/cloudinary_service.dart
import 'dart:io';
import 'package:cloudinary_public/cloudinary_public.dart';

class CloudinaryService {
  static final CloudinaryService _instance = CloudinaryService._internal();
  factory CloudinaryService() => _instance;
  CloudinaryService._internal();

  final CloudinaryPublic _cloudinary = CloudinaryPublic(
    'do5oq5ntc',  // Cloud name
    'quiz_maker', // Upload preset
    cache: false,
  );

  /// Upload an image to Cloudinary and return the secure URL
  /// Returns null if upload fails
  Future<String?> uploadImage(File imageFile) async {
    try {
      final CloudinaryResponse response = await _cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          imageFile.path,
          folder: 'quiz_questions',
          resourceType: CloudinaryResourceType.Image,
        ),
      );
      return response.secureUrl;
    } catch (e) {
      print('❌ Cloudinary upload error: $e');
      return null;
    }
  }

  /// Upload multiple images and return their URLs
  /// Returns a list where null entries indicate failed uploads
  Future<List<String?>> uploadMultipleImages(List<File> imageFiles) async {
    final List<String?> urls = [];
    for (final file in imageFiles) {
      final url = await uploadImage(file);
      urls.add(url);
    }
    return urls;
  }
}
