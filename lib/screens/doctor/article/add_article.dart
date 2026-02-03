import 'dart:io';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class AddArticlePage extends StatefulWidget {
  const AddArticlePage({super.key});

  @override
  State<AddArticlePage> createState() => _AddArticlePageState();
}

class _AddArticlePageState extends State<AddArticlePage> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();

  dynamic articleImage; // Stores File (Mobile) or Uint8List (Web)
  bool loading = false;

  final ImagePicker _picker = ImagePicker();

  // Design Colors
  final Color primaryGreen = const Color(0xFF24615E);
  final Color secondaryGreen = const Color(0xFF1B4332);
  final Color headerBgColor = const Color(0xFFE8F1E9);

  Future<void> pickImage() async {
    final XFile? xFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (xFile == null) return;

    if (kIsWeb) {
      articleImage = await xFile.readAsBytes();
    } else {
      articleImage = File(xFile.path);
    }
    setState(() {});
  }

  Future<String> uploadToCloudinary(dynamic file) async {
    final uri = Uri.parse("https://api.cloudinary.com/v1_1/dcbyjbtbc/image/upload");
    final request = http.MultipartRequest("POST", uri)
      ..fields["upload_preset"] = "doctor_upload"
      ..fields["folder"] = "articles";

    if (kIsWeb) {
      request.files.add(http.MultipartFile.fromBytes(
        "file", file,
        filename: "article_${DateTime.now().millisecondsSinceEpoch}.jpg",
        contentType: MediaType("image", "jpeg"),
      ));
    } else {
      request.files.add(await http.MultipartFile.fromPath("file", (file as File).path));
    }

    final response = await request.send();
    final respStr = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      final data = jsonDecode(respStr);
      return data["secure_url"];
    } else {
      throw Exception("Cloudinary upload failed");
    }
  }

  Future<void> submitArticle() async {
    if (_titleController.text.isEmpty || _contentController.text.isEmpty || articleImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please provide a title, content, and an image.")),
      );
      return;
    }

    setState(() => loading = true);

    try {
      final imageUrl = await uploadToCloudinary(articleImage);
      final user = FirebaseAuth.instance.currentUser;

      await FirebaseFirestore.instance.collection("articles").add({
        "title": _titleController.text.trim(),
        "content": _contentController.text.trim(),
        "imageUrl": imageUrl,
        "doctorId": user?.uid,
        "doctorName": user?.displayName ?? "Ayurveda Doctor",
        "createdAt": FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Article published!")));
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FBFB),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ---------- HEADER ----------
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(left: 20, right: 24, top: 60, bottom: 40),
              decoration: BoxDecoration(
                color: headerBgColor,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back_ios_new_rounded, color: primaryGreen, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  Text("Write Article",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: secondaryGreen)),
                ],
              ),
            ),

            // ---------- FORM BODY ----------
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Image Preview/Selector Box
                  GestureDetector(
                    onTap: pickImage,
                    child: Container(
                      width: double.infinity,
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(color: Colors.black.withOpacity(0.05)),
                        image: articleImage != null
                            ? DecorationImage(
                                image: kIsWeb ? MemoryImage(articleImage) : FileImage(articleImage) as ImageProvider,
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: articleImage == null
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_photo_alternate_outlined, size: 50, color: primaryGreen.withOpacity(0.5)),
                                const SizedBox(height: 10),
                                Text("Add Cover Photo", style: TextStyle(color: primaryGreen, fontWeight: FontWeight.w600)),
                              ],
                            )
                          : Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(25),
                                color: Colors.black26,
                              ),
                              child: const Icon(Icons.edit, color: Colors.white, size: 30),
                            ),
                    ),
                  ),
                  const SizedBox(height: 25),

                  // Title Field
                  _buildTextField(
                    controller: _titleController,
                    label: "Article Title",
                    hint: "e.g. Benefits of Ashwagandha",
                  ),
                  const SizedBox(height: 20),

                  // Content Field
                  _buildTextField(
                    controller: _contentController,
                    label: "Article Content",
                    hint: "Start writing your article here...",
                    maxLines: 8,
                  ),
                  const SizedBox(height: 30),

                  // Publish Button
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryGreen,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      onPressed: loading ? null : submitArticle,
                      child: loading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("Publish Article",
                              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String label, required String hint, int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: secondaryGreen, fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide(color: Colors.black.withOpacity(0.05)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide(color: primaryGreen),
            ),
          ),
        ),
      ],
    );
  }
}