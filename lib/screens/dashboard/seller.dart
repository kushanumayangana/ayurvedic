// lib/screens/dashboard/seller_dashboard.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'seller_edit_profile.dart';
import '../../services/cloudinary_service.dart';

class SellerDashboard extends StatefulWidget {
  const SellerDashboard({super.key});

  @override
  State<SellerDashboard> createState() => _SellerDashboardState();
}

class _SellerDashboardState extends State<SellerDashboard> {
  String fullName = "";
  String profileImage = "";
  String whatsapp = "";
  String phone = "";
  String description = "";
  bool hasProfile = false;

  // profile image pickers
  File? profileImageFile;
  XFile? profileImageWeb;

  final Color primaryColor = const Color(0xFF24615E);

  @override
  void initState() {
    super.initState();
    _loadSellerData();
  }

  Future<void> _loadSellerData() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final doc = await FirebaseFirestore.instance.collection("sellers").doc(uid).get();

    if (doc.exists) {
      final data = doc.data()!;
      setState(() {
        fullName = data['fullName'] ?? "Seller";
        profileImage = data['profileImage'] ?? "";
        whatsapp = data['whatsapp'] ?? "";
        phone = data['phone'] ?? "";
        description = data['description'] ?? "";
        hasProfile = true;
      });
    }
  }

  Future<void> _openWhatsApp() async {
    if (whatsapp.isNotEmpty) {
      final url = "https://wa.me/$whatsapp";
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: const Text("Seller Dashboard"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: hasProfile ? Column(
          children: [
            // ---------- PROFILE CARD ----------
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundImage:
                          profileImage.isNotEmpty ? NetworkImage(profileImage) : null,
                      child: profileImage.isEmpty ? const Icon(Icons.person, size: 50) : null,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      fullName,
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    if (description.isNotEmpty)
                      Text(description, textAlign: TextAlign.center,),
                    const SizedBox(height: 8),
                    if (phone.isNotEmpty)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.phone, color: Colors.grey),
                          const SizedBox(width: 8),
                          Text(phone),
                        ],
                      ),
                    const SizedBox(height: 8),
                    if (whatsapp.isNotEmpty)
                      ElevatedButton.icon(
                        onPressed: _openWhatsApp,
                        icon: const Icon(Icons.chat),
                        label: const Text("Chat on WhatsApp"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ---------- DASHBOARD OPTIONS ----------
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.storefront, color: Colors.orange),
                      title: const Text("Manage Products"),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 18),
                      onTap: () {
                        // Navigate to products page
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.shopping_cart, color: Colors.blue),
                      title: const Text("Manage Orders"),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 18),
                      onTap: () {
                        // Navigate to orders page
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.person, color: Colors.green),
                      title: const Text("Edit Profile"),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 18),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SellerEditProfileScreen(
                              sellerData: {
                                'fullName': fullName,
                                'profileImage': profileImage,
                                'whatsapp': whatsapp,
                                'phone': phone,
                                'description': description,
                              },
                            ),
                          ),
                        ).then((updated) {
                          if (updated == true) {
                            _loadSellerData();
                          }
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ) : _buildSellerCreateProfile(),
      ),
    );
  }

  Widget _buildSellerCreateProfile() {
    final nameCtrl = TextEditingController();
    final whatsappCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    return Column(
      children: [
        const Icon(Icons.person_add_alt, size: 80),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () async {
            final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
            if (picked != null) {
              if (kIsWeb) {
                profileImageWeb = picked;
              } else {
                profileImageFile = File(picked.path);
              }
              setState(() {});
            }
          },
          child: CircleAvatar(
            radius: 40,
            backgroundImage: profileImageFile != null
                ? FileImage(profileImageFile!) as ImageProvider
                : (profileImageWeb != null ? NetworkImage(profileImageWeb!.path) : null),
            child: profileImageFile == null && profileImageWeb == null ? const Icon(Icons.camera_alt) : null,
          ),
        ),
        const SizedBox(height: 12),
        TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Full Name')),
        TextField(controller: whatsappCtrl, decoration: const InputDecoration(labelText: 'WhatsApp Number')),
        TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Phone')),
        TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description'), maxLines: 3),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: () async {
            final uid = FirebaseAuth.instance.currentUser!.uid;
            String imgUrl = "";

            if (CloudinaryService.isConfigured() && (kIsWeb && profileImageWeb != null || !kIsWeb && profileImageFile != null)) {
              if (kIsWeb && profileImageWeb != null) {
                imgUrl = await CloudinaryService.uploadImageFromWeb(profileImageWeb!) ?? "";
              } else if (!kIsWeb && profileImageFile != null) {
                imgUrl = await CloudinaryService.uploadImageFromFile(profileImageFile!) ?? "";
              }
            } else if (!kIsWeb && profileImageFile != null) {
              final ref = FirebaseStorage.instance.ref().child('profiles').child('$uid.jpg');
              await ref.putFile(profileImageFile!);
              imgUrl = await ref.getDownloadURL();
            }

            await FirebaseFirestore.instance.collection('sellers').doc(uid).set({
              'fullName': nameCtrl.text.trim(),
              'whatsapp': whatsappCtrl.text.trim(),
              'phone': phoneCtrl.text.trim(),
              'description': descCtrl.text.trim(),
              'profileImage': imgUrl,
              'createdAt': Timestamp.now(),
            });

            await _loadSellerData();
          },
          child: const Text('Create Profile'),
          style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
        )
      ],
    );
  }
}
