import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import 'doctor_model.dart';

class DoctorRegisterStep3 extends StatefulWidget {
  final String uid, fullName, nic, email, regNo, specialization, clinicAddress;

  const DoctorRegisterStep3({
    super.key,
    required this.uid,
    required this.fullName,
    required this.nic,
    required this.email,
    required this.regNo,
    required this.specialization,
    required this.clinicAddress,
  });

  @override
  State<DoctorRegisterStep3> createState() => _DoctorRegisterStep3State();
}

class _DoctorRegisterStep3State extends State<DoctorRegisterStep3> {
  dynamic license, nicFront, nicBack;
  bool makesMedicine = false;
  bool loading = false;

  final ImagePicker _picker = ImagePicker();

  final Color headerBgColor = const Color(0xFFE9EFEE);
  final Color darkGreen = const Color(0xFF1E5653);
  final Color primaryGreen = const Color(0xFF24615E);

  // ---------- Pick Image ----------
  Future<void> pickImage(String type) async {
    try {
      final XFile? xFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (xFile == null) return;

      if (kIsWeb) {
        final Uint8List bytes = await xFile.readAsBytes();
        setState(() {
          if (type == "license") license = bytes;
          if (type == "nicFront") nicFront = bytes;
          if (type == "nicBack") nicBack = bytes;
        });
      } else {
        setState(() {
          if (type == "license") license = File(xFile.path);
          if (type == "nicFront") nicFront = File(xFile.path);
          if (type == "nicBack") nicBack = File(xFile.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error picking image: $e")),
      );
    }
  }

  // ---------- Cloudinary Upload ----------
  Future<String> uploadToCloudinary(dynamic file, String tag) async {
    final uri = Uri.parse("https://api.cloudinary.com/v1_1/dcbyjbtbc/image/upload");
    final request = http.MultipartRequest("POST", uri)
      ..fields["upload_preset"] = "doctor_upload"
      ..fields["folder"] = "doctors"; // Important to match your preset folder

    if (kIsWeb) {
      request.files.add(
        http.MultipartFile.fromBytes(
          "file",
          file,
          filename: "doctor_${tag}_${DateTime.now().millisecondsSinceEpoch}.jpg",
          contentType: MediaType("image", "jpeg"),
        ),
      );
    } else {
      request.files.add(
        await http.MultipartFile.fromPath("file", (file as File).path),
      );
    }

    final response = await request.send();
    final respStr = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      final data = jsonDecode(respStr);
      return data["secure_url"];
    } else {
      debugPrint("Cloudinary error: $respStr");
      throw Exception("Upload failed: Cloudinary returned ${response.statusCode}");
    }
  }

  // ---------- Submit ----------
  Future<void> submit() async {
    if (license == null || nicFront == null || nicBack == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please upload all required documents")),
      );
      return;
    }

    setState(() => loading = true);

    try {
      final urls = await Future.wait([
        uploadToCloudinary(license, "license"),
        uploadToCloudinary(nicFront, "nicFront"),
        uploadToCloudinary(nicBack, "nicBack"),
      ]);

      final doctor = DoctorModel(
        uid: widget.uid,
        fullName: widget.fullName,
        nic: widget.nic,
        email: widget.email,
        regNo: widget.regNo,
        specialization: widget.specialization,
        clinicAddress: widget.clinicAddress,
        licenseUrl: urls[0],
        nicFrontUrl: urls[1],
        nicBackUrl: urls[2],
        emailVerified: FirebaseAuth.instance.currentUser?.emailVerified ?? false,
        makesMedicine: makesMedicine,
        status: "pending",
      );

      await FirebaseFirestore.instance.collection("doctors").doc(widget.uid).set(doctor.toMap());

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Submitted for admin approval")),
      );

      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(left: 24, right: 24, top: 60, bottom: 40),
              decoration: BoxDecoration(
                color: headerBgColor,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back, color: darkGreen),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "Verification",
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: darkGreen),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 48),
                    child: Text(
                      "Step 3 of 3 • Upload Documents",
                      style: TextStyle(color: darkGreen.withOpacity(0.7), fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10)),
                  ],
                ),
                child: Column(
                  children: [
                    _uploadCard("Medical License", license, () => pickImage("license")),
                    _uploadCard("NIC Front Side", nicFront, () => pickImage("nicFront")),
                    _uploadCard("NIC Back Side", nicBack, () => pickImage("nicBack")),
                    const Divider(),
                    SwitchListTile(
                      activeColor: primaryGreen,
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        "I produce my own Ayurvedic medicines",
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                      value: makesMedicine,
                      onChanged: (v) => setState(() => makesMedicine = v),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryGreen,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: loading ? null : submit,
                        child: loading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text(
                                "Submit for Approval",
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _uploadCard(String title, dynamic file, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.blueGrey, fontSize: 13),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              decoration: BoxDecoration(
                color: file != null ? primaryGreen.withOpacity(0.05) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: file != null ? primaryGreen : Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  Icon(file != null ? Icons.check_circle : Icons.cloud_upload_outlined,
                      color: file != null ? primaryGreen : Colors.grey.shade400),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      file != null ? "Document Selected" : "Tap to upload $title",
                      style: TextStyle(color: file != null ? primaryGreen : Colors.grey.shade600, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
