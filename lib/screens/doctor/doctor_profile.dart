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
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../doctor/appointment/book_appointment.dart';

class DoctorProfilePage extends StatefulWidget {
  final String doctorId;

  const DoctorProfilePage({super.key, required this.doctorId});

  static const Color primaryGreen = Color(0xFF24615E);
  static const Color lightGreen = Color(0xFFE8F3F2);
  static const Color accentGreen = Color(0xFF2E7D72);

  @override
  State<DoctorProfilePage> createState() => _DoctorProfilePageState();
}

class _DoctorProfilePageState extends State<DoctorProfilePage> {
  // Controllers
  final fullName = TextEditingController();
  final specialization = TextEditingController();
  final qualification = TextEditingController();
  final experience = TextEditingController();
  final registration = TextEditingController();
  final phone = TextEditingController();
  final email = TextEditingController();
  final whatsapp = TextEditingController();
  final clinicAddress = TextEditingController();
  final consultationFee = TextEditingController();
  final availableDays = TextEditingController();
  final availableTime = TextEditingController();
  final languages = TextEditingController();

  bool makesMedicine = false;
  bool loading = false;
  bool isEditing = false;

  Uint8List? profileImageBytes; // Web
  XFile? profileImageFile; // Mobile
  String profileImageUrl = '';

  final picker = ImagePicker();

  @override
  void dispose() {
    fullName.dispose();
    specialization.dispose();
    qualification.dispose();
    experience.dispose();
    registration.dispose();
    phone.dispose();
    email.dispose();
    whatsapp.dispose();
    clinicAddress.dispose();
    consultationFee.dispose();
    availableDays.dispose();
    availableTime.dispose();
    languages.dispose();
    super.dispose();
  }

  // ---------- Pick Profile Image ----------
  Future<void> pickProfileImage() async {
    final pickedFile =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (pickedFile != null) {
      if (kIsWeb) {
        final bytes = await pickedFile.readAsBytes();
        setState(() => profileImageBytes = bytes);
      } else {
        setState(() => profileImageFile = pickedFile);
      }
    }
  }

  // ---------- Upload to Cloudinary ----------
  Future<String?> uploadProfileImage() async {
    if ((kIsWeb && profileImageBytes == null) ||
        (!kIsWeb && profileImageFile == null)) return null;

    final uri =
        Uri.parse("https://api.cloudinary.com/v1_1/dcbyjbtbc/image/upload");
    final request = http.MultipartRequest("POST", uri)
      ..fields["upload_preset"] = "doctor_upload"
      ..fields["folder"] = "doctor_profiles";

    if (kIsWeb && profileImageBytes != null) {
      request.files.add(http.MultipartFile.fromBytes(
        "file",
        profileImageBytes!,
        filename:
            "doctor_profile_${DateTime.now().millisecondsSinceEpoch}.jpg",
        contentType: MediaType("image", "jpeg"),
      ));
    } else if (!kIsWeb && profileImageFile != null) {
      request.files.add(
          await http.MultipartFile.fromPath("file", profileImageFile!.path));
    }

    final response = await request.send();
    final respStr = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      final data = jsonDecode(respStr);
      return data["secure_url"];
    } else {
      debugPrint("Cloudinary error: $respStr");
      throw Exception(
          "Upload failed: Cloudinary returned ${response.statusCode}");
    }
  }

  // ---------- Update Profile ----------
  Future<void> updateProfile() async {
    setState(() => loading = true);
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final uploadedImageUrl = await uploadProfileImage();

      await FirebaseFirestore.instance.collection('doctors').doc(uid).set({
        "fullName": fullName.text.trim(),
        "specialization": specialization.text.trim(),
        "qualification": qualification.text.trim(),
        "experienceYears": experience.text.trim(),
        "registrationNumber": registration.text.trim(),
        "phone": phone.text.trim(),
        "email": email.text.trim(),
        "whatsapp": whatsapp.text.trim(),
        "clinicAddress": clinicAddress.text.trim(),
        "consultationFee": consultationFee.text.trim(),
        "availableDays": availableDays.text.trim(),
        "availableTime": availableTime.text.trim(),
        "languages": languages.text.trim(),
        "makesMedicine": makesMedicine,
        "updatedAt": FieldValue.serverTimestamp(),
        if (uploadedImageUrl != null) "profileImage": uploadedImageUrl,
      }, SetOptions(merge: true));

      setState(() => isEditing = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Profile updated successfully"),
          backgroundColor: DoctorProfilePage.primaryGreen,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      setState(() => loading = false);
    }
  }

  Widget buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: DoctorProfilePage.lightGreen,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: DoctorProfilePage.primaryGreen),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 2),
                Text(
                  value.isNotEmpty ? value : 'Not specified',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight:
                          value.isNotEmpty ? FontWeight.w500 : FontWeight.normal,
                      color: value.isNotEmpty ? Colors.black87 : Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildEditableField(String label, TextEditingController controller,
      IconData icon,
      {TextInputType? type, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: TextFormField(
          controller: controller,
          keyboardType: type,
          maxLines: maxLines,
          decoration: InputDecoration(
            labelText: label,
            labelStyle: const TextStyle(color: Colors.grey),
            prefixIcon: Icon(icon, color: DoctorProfilePage.primaryGreen),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isOwner = FirebaseAuth.instance.currentUser?.uid == widget.doctorId;

    return Stack(
      children: [
        Scaffold(
          backgroundColor: DoctorProfilePage.lightGreen,
          appBar: AppBar(
            title: Text(isOwner ? "My Profile" : "Doctor Profile",
                style:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 20)),
            backgroundColor: DoctorProfilePage.primaryGreen,
            foregroundColor: Colors.white,
            elevation: 0,
            actions: isOwner
                ? [
                    if (!isEditing)
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () => setState(() => isEditing = true),
                      )
                    else
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => setState(() => isEditing = false),
                          ),
                          IconButton(
                            icon: const Icon(Icons.save),
                            onPressed: updateProfile,
                          ),
                        ],
                      ),
                  ]
                : null,
          ),
          body: StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('doctors')
                .doc(widget.doctorId)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || !snapshot.data!.exists) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline,
                          size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text('Doctor not found',
                          style: TextStyle(
                              fontSize: 18, color: Colors.grey.shade600)),
                    ],
                  ),
                );
              }

              final data =
                  snapshot.data!.data() as Map<String, dynamic>? ?? {};

              // FIX: Always pull the profile image so it displays in View Mode
              profileImageUrl = data['profileImage'] ?? '';

              if (isEditing && fullName.text.isEmpty) {
                fullName.text = data['fullName'] ?? '';
                specialization.text = data['specialization'] ?? '';
                qualification.text = data['qualification'] ?? '';
                experience.text = data['experienceYears'] ?? '';
                registration.text = data['registrationNumber'] ?? '';
                phone.text = data['phone'] ?? '';
                email.text = data['email'] ?? '';
                whatsapp.text = data['whatsapp'] ?? '';
                clinicAddress.text = data['clinicAddress'] ?? '';
                consultationFee.text = data['consultationFee'] ?? '';
                availableDays.text = data['availableDays'] ?? '';
                availableTime.text = data['availableTime'] ?? '';
                languages.text = data['languages'] ?? '';
                makesMedicine = data['makesMedicine'] ?? false;
                // profileImageUrl is already updated above
              }

              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Profile Header
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            DoctorProfilePage.primaryGreen,
                            DoctorProfilePage.accentGreen,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            Stack(
                              children: [
                                CircleAvatar(
                                  radius: 55,
                                  backgroundColor: Colors.white,
                                  backgroundImage: kIsWeb
                                      ? (profileImageBytes != null
                                          ? MemoryImage(profileImageBytes!)
                                          : profileImageUrl.isNotEmpty
                                              ? NetworkImage(profileImageUrl)
                                                  as ImageProvider
                                              : null)
                                      : (profileImageFile != null
                                          ? FileImage(File(profileImageFile!.path))
                                          : profileImageUrl.isNotEmpty
                                              ? NetworkImage(profileImageUrl)
                                                  as ImageProvider
                                              : null),
                                  child: (profileImageBytes == null &&
                                          profileImageFile == null &&
                                          profileImageUrl.isEmpty)
                                      ? Icon(Icons.person,
                                          size: 55,
                                          color: Colors.grey.shade400)
                                      : null,
                                ),
                                if (isOwner && isEditing)
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: GestureDetector(
                                      onTap: pickProfileImage,
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.1),
                                              blurRadius: 5,
                                            ),
                                          ],
                                        ),
                                        child: Icon(Icons.camera_alt,
                                            size: 20,
                                            color: DoctorProfilePage.primaryGreen),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              isEditing
                                  ? fullName.text
                                  : (data['fullName'] ?? 'Doctor Name'),
                              style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isEditing
                                  ? specialization.text
                                  : (data['specialization'] ?? 'Specialization'),
                              style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 16),
                            if (!isOwner)
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: DoctorProfilePage.primaryGreen,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 32, vertical: 14),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30)),
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => BookAppointmentPage(
                                              doctorId: widget.doctorId,
                                              doctorName: data['fullName'] ?? '',
                                            )),
                                  );
                                },
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.calendar_today, size: 18),
                                    SizedBox(width: 8),
                                    Text("Book Appointment",
                                        style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),
                    // Details
                    isEditing
                        ? Column(
                            children: [
                              buildEditableField(
                                  "Full Name", fullName, Icons.person),
                              buildEditableField("Specialization", specialization,
                                  Icons.medical_services),
                              buildEditableField("Qualification", qualification,
                                  Icons.school),
                              buildEditableField("Experience (years)", experience,
                                  Icons.timer),
                              buildEditableField(
                                  "Registration Number", registration, Icons.confirmation_num),
                              buildEditableField("Phone", phone, Icons.phone,
                                  type: TextInputType.phone),
                              buildEditableField(
                                  "Email", email, Icons.email,
                                  type: TextInputType.emailAddress),
                              buildEditableField(
                                  "Whatsapp", whatsapp, FontAwesomeIcons.whatsapp),
                              buildEditableField("Clinic Address", clinicAddress,
                                  Icons.location_on),
                              buildEditableField("Consultation Fee", consultationFee,
                                  Icons.attach_money,
                                  type: TextInputType.number),
                              buildEditableField(
                                  "Available Days", availableDays, Icons.calendar_today),
                              buildEditableField(
                                  "Available Time", availableTime, Icons.access_time),
                              buildEditableField("Languages", languages, Icons.language),
                            ],
                          )
                        : Column(
                            children: [
                              buildInfoRow("Qualification",
                                  data['qualification'] ?? '', Icons.school),
                              buildInfoRow("Experience",
                                  data['experienceYears'] ?? '', Icons.timer),
                              buildInfoRow("Registration No.",
                                  data['registrationNumber'] ?? '', Icons.confirmation_num),
                              buildInfoRow("Phone", data['phone'] ?? '', Icons.phone),
                              buildInfoRow("Email", data['email'] ?? '', Icons.email),
                              buildInfoRow(
                                  "Whatsapp", data['whatsapp'] ?? '', FontAwesomeIcons.whatsapp),
                              buildInfoRow("Clinic Address",
                                  data['clinicAddress'] ?? '', Icons.location_on),
                              buildInfoRow("Consultation Fee",
                                  data['consultationFee'] ?? '', Icons.attach_money),
                              buildInfoRow("Available Days",
                                  data['availableDays'] ?? '', Icons.calendar_today),
                              buildInfoRow("Available Time",
                                  data['availableTime'] ?? '', Icons.access_time),
                              buildInfoRow(
                                  "Languages", data['languages'] ?? '', Icons.language),
                            ],
                          ),
                    const SizedBox(height: 16),
                  ],
                ),
              );
            },
          ),
        ),
        if (loading)
          Container(
            color: Colors.black.withOpacity(0.3),
            child: const Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }
}