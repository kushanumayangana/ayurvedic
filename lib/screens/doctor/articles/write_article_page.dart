import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';

import 'package:flutter/foundation.dart';
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
  final Color accentTeal = const Color(0xFF3B8F8B);
  final Color surfaceWhite = const Color(0xFFF8FAFB);

  File? _selectedImageFile;
  Uint8List? _selectedImageBytes;
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
    const cloudName = 'dcbyjbtbc';
    const uploadPreset = 'articles';

    final url = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');
    final request = http.MultipartRequest('POST', url);

    if (kIsWeb && _selectedImageBytes != null) {
      request.files.add(http.MultipartFile.fromBytes('file', _selectedImageBytes!, filename: 'upload.png'));
    } else if (_selectedImageFile != null) {
      request.files.add(await http.MultipartFile.fromPath('file', _selectedImageFile!.path));
    }

    request.fields['upload_preset'] = uploadPreset;

    try {
      final response = await request.send();
      if (response.statusCode == 200) {
        final resStr = await response.stream.bytesToString();
        return json.decode(resStr)['secure_url'];
      }
    } catch (e) {
      debugPrint("Upload Error: $e");
    }
    return null;
  }

  Future<void> _publishArticle() async {
    if (titleCtrl.text.isEmpty || contentCtrl.text.isEmpty) {
      _showSnackBar("Please fill in the title and content", Colors.orange);
      return;
    }

    setState(() => _isUploading = true);

    try {
      String? imageUrl = "";
      if (_selectedImageFile != null || _selectedImageBytes != null) {
        imageUrl = await _uploadToCloudinary();
      }

      // THE FIX: Explicit structure matching your security rules
      await FirebaseFirestore.instance.collection('articles').add({
        "doctorId": widget.doctorId,
        "author": widget.doctorName,
        "title": titleCtrl.text.trim(),
        "content": contentCtrl.text.trim(),
        "fileUrl": imageUrl ?? "",
        "createdAt": FieldValue.serverTimestamp(), // Better for sorting than Timestamp.now()
      });

      _showSnackBar("Article published successfully! 🎉", Colors.green);

      // DELAYED POP: Prevents the "disappearing" glitch by allowing local sync to finish
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) Navigator.pop(context);
      });
    } catch (e) {
      _showSnackBar("Publishing failed: $e", Colors.redAccent);
      setState(() => _isUploading = false);
    }
  }

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color, behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: surfaceWhite,
      appBar: AppBar(
        title: const Text("Create Masterpiece", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: primaryGreen,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionLabel("Visual Cover"),
            _buildImagePicker(),
            const SizedBox(height: 24),
            _sectionLabel("Headline"),
            _buildTextField(titleCtrl, "Enter a catchy title...", Icons.title, 1),
            const SizedBox(height: 24),
            _sectionLabel("The Content"),
            _buildTextField(contentCtrl, "Share your medical expertise...", Icons.article_outlined, 8),
            const SizedBox(height: 32),
            _buildPublishButton(),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Text(text, style: TextStyle(color: primaryGreen, fontWeight: FontWeight.bold, fontSize: 14)),
      );

  Widget _buildTextField(TextEditingController ctrl, String hint, IconData icon, int lines) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: TextField(
        controller: ctrl,
        maxLines: lines,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, color: accentTeal),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(20),
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 180,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: primaryGreen.withOpacity(0.1), width: 2),
          image: (_selectedImageFile != null || _selectedImageBytes != null)
              ? DecorationImage(
                  image: kIsWeb ? MemoryImage(_selectedImageBytes!) : FileImage(_selectedImageFile!) as ImageProvider,
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: (_selectedImageFile == null && _selectedImageBytes == null)
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_photo_alternate_rounded, size: 40, color: accentTeal),
                  const SizedBox(height: 8),
                  Text("Add a Cover Image", style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                ],
              )
            : Align(
                alignment: Alignment.bottomRight,
                child: Container(
                  margin: const EdgeInsets.all(12),
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  child: Icon(Icons.edit, color: primaryGreen, size: 20),
                ),
              ),
      ),
    );
  }

  Widget _buildPublishButton() {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: _isUploading ? null : _publishArticle,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 4,
          shadowColor: primaryGreen.withOpacity(0.4),
        ),
        child: _isUploading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text("Publish Now", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
      ),
    );
  }
}