import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class SellerRegisterStep2 extends StatefulWidget {
  final String userId;
  const SellerRegisterStep2({super.key, required this.userId});

  @override
  State<SellerRegisterStep2> createState() => _SellerRegisterStep2State();
}

class _SellerRegisterStep2State extends State<SellerRegisterStep2> {
  final Color primaryGold = const Color(0xFFC59D3F);
  final Color backgroundColor = const Color(0xFFF8F8F8);
  final _picker = ImagePicker();

  dynamic brCertificateFile;
  dynamic drugLicenseFile;
  bool loading = false;

  final TextEditingController drugLicenseNumberController = TextEditingController();
  final TextEditingController drugLicenseExpiryController = TextEditingController();

  // --- LOGIC FUNCTIONS ---
  Future<void> pickFile(String type) async {
    try {
      if (kIsWeb) {
        FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['jpg', 'png', 'pdf']);
        if (result != null) {
          setState(() {
            if (type == "br") brCertificateFile = result.files.single.bytes!;
            if (type == "drug") drugLicenseFile = result.files.single.bytes!;
          });
        }
      } else {
        final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
        if (image != null) {
          setState(() {
            if (type == "br") brCertificateFile = File(image.path);
            if (type == "drug") drugLicenseFile = File(image.path);
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  Future<String> uploadToCloudinary(dynamic file, String tag) async {
    final uri = Uri.parse("https://api.cloudinary.com/v1_1/dcbyjbtbc/image/upload");
    final request = http.MultipartRequest("POST", uri)
      ..fields["upload_preset"] = "seller_upload"
      ..fields["folder"] = "sellers";

    if (kIsWeb) {
      request.files.add(http.MultipartFile.fromBytes("file", file as Uint8List, filename: "file.jpg", contentType: MediaType("image", "jpeg")));
    } else {
      request.files.add(await http.MultipartFile.fromPath("file", (file as File).path));
    }
    final response = await request.send();
    final respStr = await response.stream.bytesToString();
    if (response.statusCode == 200) return jsonDecode(respStr)["secure_url"];
    throw Exception("Upload Failed");
  }

  Future<void> submitApplication() async {
    if (brCertificateFile == null || drugLicenseFile == null) return;
    setState(() => loading = true);
    try {
      final urls = await Future.wait([uploadToCloudinary(brCertificateFile, "br"), uploadToCloudinary(drugLicenseFile, "drug")]);
      await FirebaseFirestore.instance.collection("sellers").doc(widget.userId).set({
        "brCertificateUrl": urls[0],
        "drugLicenseUrl": urls[1],
        "drugLicenseNumber": drugLicenseNumberController.text.trim(),
        "drugLicenseExpiry": drugLicenseExpiryController.text.trim(),
      }, SetOptions(merge: true));
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => loading = false);
    }
  }

  // --- DESIGN WIDGETS ---
  Widget _buildUploadCard(String title, String subtitle, dynamic file, VoidCallback onTap) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title.isNotEmpty) Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: onTap,
            child: Container(
              height: 100,
              width: double.infinity,
              decoration: BoxDecoration(color: const Color(0xFFF9F9F9), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(file != null ? Icons.check_circle : Icons.file_upload_outlined, color: file != null ? Colors.green : primaryGold),
                Text(file != null ? "Selected" : "Click to upload", style: const TextStyle(fontWeight: FontWeight.bold)),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, iconTheme: const IconThemeData(color: Colors.black)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text("Step 2 of 2"),
            const SizedBox(height: 10),
            LinearProgressIndicator(value: 1.0, backgroundColor: Colors.grey.shade300, valueColor: AlwaysStoppedAnimation<Color>(primaryGold)),
            const SizedBox(height: 20),
            _buildUploadCard("Business Registration", "PDF or Image", brCertificateFile, () => pickFile("br")),
            _buildUploadCard("Drug Selling License", "PDF or Image", drugLicenseFile, () => pickFile("drug")),
            TextField(controller: drugLicenseNumberController, decoration: const InputDecoration(labelText: "License Number")),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: primaryGold),
                onPressed: loading ? null : submitApplication,
                child: loading ? const CircularProgressIndicator(color: Colors.white) : const Text("Submit Application", style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}