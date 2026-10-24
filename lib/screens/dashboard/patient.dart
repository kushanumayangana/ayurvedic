import 'dart:typed_data';
import 'dart:io';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../doctor/doctor_profile.dart';
import '../marketplace/buyer_orders_tab.dart';
import '../marketplace/chat_pages.dart';
import '../seller/seller_profile.dart';

class PatientDashboardPage extends StatefulWidget {
  const PatientDashboardPage({super.key});

  static const Color primaryGreen = Color(0xFF24615E);
  static const Color lightGreen = Color(0xFFE8F3F2);

  @override
  State<PatientDashboardPage> createState() => _PatientDashboardPageState();
}

class _PatientDashboardPageState extends State<PatientDashboardPage> {
  final nameController = TextEditingController();
  final ageController = TextEditingController();

  Uint8List? profileImageBytes;
  XFile? profileImageFile;
  String profileImageUrl = '';

  bool loading = false;

  final picker = ImagePicker();

  Stream<QuerySnapshot>? appointmentsStream;

  @override
  void initState() {
    super.initState();
    loadProfile(); // load existing data

    // Safe stream initialization
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      appointmentsStream = FirebaseFirestore.instance
          .collection('appointments')
          .where('patientId', isEqualTo: user.uid)
          .snapshots();
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    ageController.dispose();
    super.dispose();
  }

  // ================= LOAD EXISTING PROFILE =================
  Future<void> loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('patients')
        .doc(user.uid)
        .get();

    if (doc.exists) {
      final data = doc.data()!;
      setState(() {
        nameController.text = data['name'] ?? '';
        ageController.text = data['age'] ?? '';
        profileImageUrl = data['image'] ?? '';
      });
    }
  }

  void _openBookingProfile(Map<String, dynamic> booking) {
    final isSellerBooking =
        booking['bookingType'] == 'seller' ||
        (booking['sellerId']?.toString().isNotEmpty ?? false);
    final profileId = isSellerBooking
        ? booking['sellerId']?.toString() ?? ''
        : booking['doctorId']?.toString() ?? '';
    if (profileId.isEmpty) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => isSellerBooking
            ? SellerProfilePage(sellerId: profileId)
            : DoctorProfilePage(doctorId: profileId),
      ),
    );
  }

  // ================= PICK IMAGE =================
  Future<void> pickProfileImage() async {
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (pickedFile != null) {
      if (kIsWeb) {
        final bytes = await pickedFile.readAsBytes();
        setState(() => profileImageBytes = bytes);
      } else {
        setState(() => profileImageFile = pickedFile);
      }
    }
  }

  // ================= CLOUDINARY UPLOAD =================
  Future<String?> uploadProfileImage() async {
    if ((kIsWeb && profileImageBytes == null) ||
        (!kIsWeb && profileImageFile == null))
      return null;

    final uri = Uri.parse(
      "https://api.cloudinary.com/v1_1/dcbyjbtbc/image/upload",
    );

    final request = http.MultipartRequest("POST", uri)
      ..fields["upload_preset"] = "patient_upload"
      ..fields["folder"] = "patient_profiles";

    if (kIsWeb && profileImageBytes != null) {
      request.files.add(
        http.MultipartFile.fromBytes(
          "file",
          profileImageBytes!,
          filename: "patient_${DateTime.now().millisecondsSinceEpoch}.jpg",
          contentType: MediaType("image", "jpeg"),
        ),
      );
    } else if (!kIsWeb && profileImageFile != null) {
      request.files.add(
        await http.MultipartFile.fromPath("file", profileImageFile!.path),
      );
    }

    final response = await request.send();
    final respStr = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      final data = jsonDecode(respStr);
      return data["secure_url"];
    } else {
      debugPrint("Cloudinary error: $respStr");
      throw Exception("Image upload failed");
    }
  }

  // ================= SAVE PROFILE =================
  Future<void> saveProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => loading = true);

    try {
      final uploadedImageUrl = await uploadProfileImage();

      await FirebaseFirestore.instance
          .collection('patients')
          .doc(user.uid)
          .set({
            'name': nameController.text.trim(),
            'age': ageController.text.trim(),
            if (uploadedImageUrl != null) "image": uploadedImageUrl,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

      // reload updated data
      await loadProfile();

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Profile Saved ✅")));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      setState(() => loading = false);
    }
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PatientDashboardPage.lightGreen,
      appBar: AppBar(
        title: const Text("Patient Dashboard"),
        backgroundColor: PatientDashboardPage.primaryGreen,
        actions: [
          IconButton(
            tooltip: 'Messages',
            icon: const Icon(Icons.chat_bubble_outline),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChatInboxPage(
                  userId: FirebaseAuth.instance.currentUser?.uid ?? '',
                  accentColor: PatientDashboardPage.primaryGreen,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // PROFILE IMAGE
            InkWell(
              onTap: pickProfileImage,
              child: CircleAvatar(
                radius: 55,
                backgroundColor: Colors.white,
                backgroundImage: kIsWeb
                    ? (profileImageBytes != null
                          ? MemoryImage(profileImageBytes!)
                          : profileImageUrl.isNotEmpty
                          ? NetworkImage(profileImageUrl)
                          : null)
                    : (profileImageFile != null
                              ? FileImage(File(profileImageFile!.path))
                              : profileImageUrl.isNotEmpty
                              ? NetworkImage(profileImageUrl)
                              : null)
                          as ImageProvider?,
                child:
                    profileImageBytes == null &&
                        profileImageFile == null &&
                        profileImageUrl.isEmpty
                    ? Icon(Icons.person, size: 55, color: Colors.grey.shade400)
                    : null,
              ),
            ),

            const SizedBox(height: 20),

            // NAME
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: "Name",
                prefixIcon: Icon(Icons.person),
              ),
            ),

            const SizedBox(height: 10),

            // AGE
            TextField(
              controller: ageController,
              decoration: const InputDecoration(
                labelText: "Age",
                prefixIcon: Icon(Icons.cake),
              ),
              keyboardType: TextInputType.number,
            ),

            const SizedBox(height: 20),

            // SAVE BUTTON
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: loading ? null : saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: PatientDashboardPage.primaryGreen,
                ),
                child: loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Save Profile"),
              ),
            ),

            // ================= PATIENT APPOINTMENTS =================
            const SizedBox(height: 30),
            const Text(
              "My Appointments",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            // ================= SAFE STREAM BUILDER =================
            StreamBuilder<QuerySnapshot>(
              stream: appointmentsStream,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs
                    .where((doc) => doc.exists)
                    .toList();

                if (docs.isEmpty)
                  return const Text("No appointments booked yet.");

                // Sort safely by createdAt
                docs.sort((a, b) {
                  final aTime = a['createdAt'] ?? Timestamp(0, 0);
                  final bTime = b['createdAt'] ?? Timestamp(0, 0);
                  return bTime.compareTo(aTime);
                });

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data =
                        docs[index].data() as Map<String, dynamic>? ?? {};
                    final status = data['status'] ?? 'pending';
                    final isSellerBooking =
                        data['bookingType'] == 'seller' ||
                        (data['sellerId']?.toString().isNotEmpty ?? false);
                    final recipientName = isSellerBooking
                        ? data['sellerName']?.toString() ?? 'Seller'
                        : data['doctorName']?.toString() ?? 'Doctor';
                    final statusColor = status == 'approved'
                        ? Colors.green
                        : status == 'rejected'
                        ? Colors.red
                        : Colors.orange;

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: PatientDashboardPage.primaryGreen
                              .withOpacity(0.12),
                          child: Icon(
                            isSellerBooking
                                ? Icons.storefront_outlined
                                : Icons.medical_services_outlined,
                            color: PatientDashboardPage.primaryGreen,
                          ),
                        ),
                        title: Text(
                          recipientName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if ((data['productTitle']?.toString().isNotEmpty ??
                                false))
                              Text('Item: ${data['productTitle']}'),
                            Text("Date: ${data['date'] ?? ''}"),
                            Text("Time: ${data['time'] ?? ''}"),
                            Text("Reason: ${data['reason'] ?? ''}"),
                            const SizedBox(height: 6),
                            Text(
                              status.toString().toUpperCase(),
                              style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        trailing: IconButton(
                          tooltip: isSellerBooking
                              ? 'View seller profile'
                              : 'View doctor profile',
                          onPressed: () => _openBookingProfile(data),
                          icon: const Icon(Icons.account_circle_outlined),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 30),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'My Orders',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 10),
            const SizedBox(height: 380, child: BuyerOrdersTab()),
          ],
        ),
      ),
    );
  }
}
