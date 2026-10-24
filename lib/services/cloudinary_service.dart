import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class CloudinaryService {
  // Cloudinary Configuration
  static const String cloudinaryCloudName = "dcbyjbtbc";
  static const String cloudinaryUploadPreset = "ayurvedic_articles";
  static const String uploadUrl = "https://api.cloudinary.com/v1_1/$cloudinaryCloudName/image/upload";

  // Check if credentials are configured
  static bool isConfigured() {
    return cloudinaryCloudName != "YOUR_CLOUD_NAME" &&
        cloudinaryUploadPreset != "YOUR_UPLOAD_PRESET";
  }

  /// Upload image from file (mobile)
  static Future<String?> uploadImageFromFile(File imageFile) async {
    try {
      final url = await _uploadImage(
        fileName: imageFile.path.split('/').last,
        fileBytes: await imageFile.readAsBytes(),
      );
      return url;
    } catch (e) {
      print('Cloudinary upload error: $e');
      return null;
    }
  }

  /// Upload image from web (XFile)
  static Future<String?> uploadImageFromWeb(XFile imageFile) async {
    try {
      final url = await _uploadImage(
        fileName: imageFile.name,
        fileBytes: await imageFile.readAsBytes(),
      );
      return url;
    } catch (e) {
      print('Cloudinary upload error: $e');
      return null;
    }
  }

  static Future<String?> _uploadImage({
    required String fileName,
    required List<int> fileBytes,
  }) async {
    final request = http.MultipartRequest('POST', Uri.parse(uploadUrl));
    request.fields['upload_preset'] = cloudinaryUploadPreset;
    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        fileBytes,
        filename: fileName,
      ),
    );

    final response = await request.send();
    if (response.statusCode != 200) {
      return null;
    }

    final responseBody = await response.stream.bytesToString();
    final decoded = jsonDecode(responseBody);
    if (decoded is! Map<String, dynamic>) {
      return null;
    }

    return decoded['secure_url']?.toString();
  }
}
