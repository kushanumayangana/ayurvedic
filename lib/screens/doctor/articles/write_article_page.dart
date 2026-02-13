import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';

import 'package:flutter/foundation.dart'; // for kIsWeb
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class WriteArticlePage extends StatefulWidget {
  final String doctorId;
  final String doctorName;

  const WriteArticlePage({
    super.key,
    required this.doctorId,
    required this.doctorName,
  });

  @override
  State<WriteArticlePage> createState() => _WriteArticlePageState();
}

class _WriteArticlePageState extends State<WriteArticlePage> {
  final TextEditingController titleCtrl = TextEditingController();
  final TextEditingController contentCtrl = TextEditingController();

  final Color primaryGreen = const Color(0xFF24615E);
  final Color lightGreen = const Color(0xFFE8F3F2);

  File? _selectedImageFile;       // Mobile/Desktop
  Uint8List? _selectedImageBytes; // Web

  bool _isUploading = false;

  @override
  void dispose() {
    titleCtrl.dispose();
    contentCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);

    if (pickedFile != null) {
      if (kIsWeb) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _selectedImageBytes = bytes;
          _selectedImageFile = null;
        });
      } else {
        setState(() {
          _selectedImageFile = File(pickedFile.path);
          _selectedImageBytes = null;
        });
      }
    }
  }

  Future<String?> _uploadToCloudinary() async {
    const cloudName = 'dcbyjbtbc';      // Your Cloudinary cloud name
    const uploadPreset = 'articles';     // Your unsigned upload preset

    final url = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');
    final request = http.MultipartRequest('POST', url);

    if (kIsWeb && _selectedImageBytes != null) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          _selectedImageBytes!,
          filename: 'web_upload.png',
        ),
      );
    } else if (_selectedImageFile != null) {
      request.files.add(await http.MultipartFile.fromPath('file', _selectedImageFile!.path));
    }

    request.fields['upload_preset'] = uploadPreset;

    final response = await request.send();
    if (response.statusCode == 200) {
      final resStr = await response.stream.bytesToString();
      final resJson = json.decode(resStr);
      return resJson['secure_url'];
    } else {
      final resStr = await response.stream.bytesToString();
      debugPrint("Cloudinary upload failed: ${response.statusCode} - $resStr");
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Write Article"),
        backgroundColor: primaryGreen,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: titleCtrl,
              decoration: InputDecoration(
                labelText: "Article Title",
                prefixIcon: Icon(Icons.title, color: primaryGreen),
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: contentCtrl,
              maxLines: 10,
              decoration: InputDecoration(
                labelText: "Article Content",
                prefixIcon: Padding(
                  padding: const EdgeInsets.only(bottom: 80),
                  child: Icon(Icons.description, color: primaryGreen),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: kIsWeb
                    ? (_selectedImageBytes != null
                        ? Image.memory(_selectedImageBytes!, fit: BoxFit.cover)
                        : const Center(child: Icon(Icons.image, size: 50, color: Colors.grey)))
                    : (_selectedImageFile != null
                        ? Image.file(_selectedImageFile!, fit: BoxFit.cover)
                        : const Center(child: Icon(Icons.image, size: 50, color: Colors.grey))),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isUploading
                    ? null
                    : () async {
                        if (titleCtrl.text.isEmpty || contentCtrl.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Please fill all fields")),
                          );
                          return;
                        }

                        setState(() => _isUploading = true);

                        String? imageUrl;
                        if (_selectedImageFile != null || _selectedImageBytes != null) {
                          imageUrl = await _uploadToCloudinary();
                          if (imageUrl == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Image upload failed")),
                            );
                          }
                        }

                        await FirebaseFirestore.instance.collection('articles').add({
                          "doctorId": widget.doctorId,
                          "author": widget.doctorName,
                          "title": titleCtrl.text.trim(),
                          "content": contentCtrl.text.trim(),
                          "fileUrl": imageUrl ?? "",
                          "createdAt": Timestamp.now(),
                        });

                        titleCtrl.clear();
                        contentCtrl.clear();
                        setState(() {
                          _selectedImageFile = null;
                          _selectedImageBytes = null;
                          _isUploading = false;
                        });

                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Article Published Successfully")),
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGreen,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isUploading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Publish Article",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
