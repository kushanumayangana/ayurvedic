import 'package:http/http.dart' as http;
import 'dart:io';
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
      final request = http.MultipartRequest('POST', Uri.parse(uploadUrl));

      request.fields['upload_preset'] = cloudinaryUploadPreset;
      request.files.add(
        http.MultipartFile(
          'file',
          imageFile.readAsBytes().asStream(),
          imageFile.lengthSync(),
          filename: imageFile.path.split('/').last,
        ),
      );

      final response = await request.send();

      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        final jsonResponse = responseBody;
        
        // Parse JSON to get secure_url
        if (jsonResponse.contains('"secure_url":"')) {
          final startIndex = jsonResponse.indexOf('"secure_url":"') + 14;
          final endIndex = jsonResponse.indexOf('"', startIndex);
          return jsonResponse.substring(startIndex, endIndex);
        }
      }
      return null;
    } catch (e) {
      print('Cloudinary upload error: $e');
      return null;
    }
  }

  /// Upload image from web (XFile)
  static Future<String?> uploadImageFromWeb(XFile imageFile) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse(uploadUrl));

      request.fields['upload_preset'] = cloudinaryUploadPreset;
      request.files.add(
        http.MultipartFile(
          'file',
          imageFile.readAsBytes().asStream(),
          await imageFile.length(),
          filename: imageFile.name,
        ),
      );

      final response = await request.send();

      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        
        // Parse JSON to get secure_url
        if (responseBody.contains('"secure_url":"')) {
          final startIndex = responseBody.indexOf('"secure_url":"') + 14;
          final endIndex = responseBody.indexOf('"', startIndex);
          return responseBody.substring(startIndex, endIndex);
        }
      }
      return null;
    } catch (e) {
      print('Cloudinary upload error: $e');
      return null;
    }
  }
}
