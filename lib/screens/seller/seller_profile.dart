import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';

import '../marketplace/chat_pages.dart';

class SellerProfilePage extends StatefulWidget {
  final String sellerId;

  const SellerProfilePage({super.key, required this.sellerId});

  static const Color primaryGold = Color(0xFFC59D3F);
  static const Color lightGold = Color(0xFFFFF8E7);
  static const Color accentGold = Color(0xFFD9A64E);

  @override
  State<SellerProfilePage> createState() => _SellerProfilePageState();
}

class _SellerProfilePageState extends State<SellerProfilePage> {
  final fullName = TextEditingController();
  final businessName = TextEditingController();
  final sellerType = TextEditingController();
  final phone = TextEditingController();
  final email = TextEditingController();
  final whatsapp = TextEditingController();
  final shopAddress = TextEditingController();
  final description = TextEditingController();

  bool loading = false;
  bool isEditing = false;

  Uint8List? profileImageBytes;
  XFile? profileImageFile;
  String profileImageUrl = '';

  final picker = ImagePicker();

  @override
  void dispose() {
    fullName.dispose();
    businessName.dispose();
    sellerType.dispose();
    phone.dispose();
    email.dispose();
    whatsapp.dispose();
    shopAddress.dispose();
    description.dispose();
    super.dispose();
  }

  Future<void> pickProfileImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (pickedFile != null) {
      if (kIsWeb) {
        final bytes = await pickedFile.readAsBytes();
        setState(() => profileImageBytes = bytes);
      } else {
        setState(() => profileImageFile = pickedFile);
      }
    }
  }

  Future<String?> uploadProfileImage() async {
    if ((kIsWeb && profileImageBytes == null) || (!kIsWeb && profileImageFile == null)) return null;

    final uri = Uri.parse('https://api.cloudinary.com/v1_1/dcbyjbtbc/image/upload');
    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = 'seller_upload'
      ..fields['folder'] = 'seller_profiles';

    if (kIsWeb && profileImageBytes != null) {
      request.files.add(http.MultipartFile.fromBytes(
        'file',
        profileImageBytes!,
        filename: 'seller_profile_${DateTime.now().millisecondsSinceEpoch}.jpg',
        contentType: MediaType('image', 'jpeg'),
      ));
    } else if (!kIsWeb && profileImageFile != null) {
      request.files.add(await http.MultipartFile.fromPath('file', profileImageFile!.path));
    }

    final response = await request.send();
    final respStr = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      final data = jsonDecode(respStr);
      return data['secure_url'];
    }

    debugPrint('Cloudinary error: $respStr');
    throw Exception('Upload failed: Cloudinary returned ${response.statusCode}');
  }

  Future<void> saveProfile() async {
    setState(() => loading = true);

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final uploadedImageUrl = await uploadProfileImage();

      await FirebaseFirestore.instance.collection('sellers').doc(uid).set({
        'fullName': fullName.text.trim(),
        'businessName': businessName.text.trim(),
        'sellerType': sellerType.text.trim(),
        'phone': phone.text.trim(),
        'email': email.text.trim(),
        'whatsapp': whatsapp.text.trim(),
        'shopAddress': shopAddress.text.trim(),
        'description': description.text.trim(),
        'status': 'pending',
        'updatedAt': FieldValue.serverTimestamp(),
        if (uploadedImageUrl != null) 'profileImage': uploadedImageUrl,
      }, SetOptions(merge: true));

      setState(() => isEditing = false);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Seller profile saved successfully'),
          backgroundColor: SellerProfilePage.primaryGold,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      setState(() => loading = false);
    }
  }

  Widget buildIconWidget(IconData icon, {Color? color}) {
    return Icon(icon, size: 20, color: color ?? SellerProfilePage.primaryGold);
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
              color: SellerProfilePage.lightGold,
              borderRadius: BorderRadius.circular(10),
            ),
            child: buildIconWidget(icon),
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
                    fontWeight: value.isNotEmpty ? FontWeight.w500 : FontWeight.normal,
                    color: value.isNotEmpty ? Colors.black87 : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildEditableField(String label, TextEditingController controller, IconData icon, {TextInputType? type, int maxLines = 1}) {
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
            prefixIcon: buildIconWidget(icon),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ),
    );
  }

  Future<void> loadProfile() async {
    final uid = widget.sellerId;
    final doc = await FirebaseFirestore.instance.collection('sellers').doc(uid).get();

    if (!doc.exists) return;

    final data = doc.data() ?? {};
    setState(() {
      fullName.text = data['fullName'] ?? '';
      businessName.text = data['businessName'] ?? '';
      sellerType.text = data['sellerType'] ?? '';
      phone.text = data['phone'] ?? '';
      email.text = data['email'] ?? '';
      whatsapp.text = data['whatsapp'] ?? '';
      shopAddress.text = data['shopAddress'] ?? '';
      description.text = data['description'] ?? '';
      profileImageUrl = data['profileImage'] ?? '';
    });
  }

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  @override
  Widget build(BuildContext context) {
    final isOwner = FirebaseAuth.instance.currentUser?.uid == widget.sellerId;

    return Stack(
      children: [
        Scaffold(
          backgroundColor: SellerProfilePage.lightGold,
          appBar: AppBar(
            title: Text(isOwner ? 'My Profile' : 'Seller Profile', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 20)),
            backgroundColor: SellerProfilePage.primaryGold,
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
                            onPressed: saveProfile,
                          ),
                        ],
                      ),
                  ]
                : null,
          ),
          body: StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('sellers').doc(widget.sellerId).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || !snapshot.data!.exists) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text('Seller not found', style: TextStyle(fontSize: 18, color: Colors.grey.shade600)),
                    ],
                  ),
                );
              }

              final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
              profileImageUrl = data['profileImage'] ?? '';

              if (isEditing && fullName.text.isEmpty) {
                fullName.text = data['fullName'] ?? '';
                businessName.text = data['businessName'] ?? '';
                sellerType.text = data['sellerType'] ?? '';
                phone.text = data['phone'] ?? '';
                email.text = data['email'] ?? '';
                whatsapp.text = data['whatsapp'] ?? '';
                shopAddress.text = data['shopAddress'] ?? '';
                description.text = data['description'] ?? '';
              }

              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [SellerProfilePage.primaryGold, SellerProfilePage.accentGold],
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
                                  backgroundImage: profileImageBytes != null
                                      ? MemoryImage(profileImageBytes!)
                                      : (profileImageUrl.isNotEmpty ? NetworkImage(profileImageUrl) : null),
                                  child: (profileImageBytes == null && profileImageUrl.isEmpty)
                                      ? Icon(Icons.person, size: 55, color: Colors.grey.shade400)
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
                                        child: Icon(Icons.camera_alt, size: 20, color: SellerProfilePage.primaryGold),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              isEditing ? fullName.text : (data['fullName'] ?? 'Seller Name'),
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isEditing ? businessName.text : (data['businessName'] ?? 'Business Name'),
                              style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (!isOwner &&
                        FirebaseAuth.instance.currentUser != null) ...[
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => openDirectChat(
                            context,
                            otherUserId: widget.sellerId,
                            otherProfile: {
                              ...data,
                              'name':
                                  data['fullName'] ??
                                  data['businessName'] ??
                                  'Seller',
                              'role': 'seller',
                            },
                            accentColor: SellerProfilePage.primaryGold,
                          ),
                          icon: const Icon(Icons.chat_bubble_outline),
                          label: const Text('Message seller'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: SellerProfilePage.primaryGold,
                            side: const BorderSide(
                              color: SellerProfilePage.primaryGold,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 13),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    isEditing
                        ? Column(
                            children: [
                              buildEditableField('Full Name', fullName, Icons.person),
                              buildEditableField('Business Name', businessName, Icons.storefront),
                              buildEditableField('Seller Type', sellerType, Icons.category),
                              buildEditableField('Phone', phone, Icons.phone, type: TextInputType.phone),
                              buildEditableField('Email', email, Icons.email, type: TextInputType.emailAddress),
                              buildEditableField('WhatsApp', whatsapp, Icons.chat, type: TextInputType.phone),
                              buildEditableField('Shop Address', shopAddress, Icons.location_on),
                              buildEditableField('Description', description, Icons.description, maxLines: 3),
                            ],
                          )
                        : Column(
                            children: [
                              buildInfoRow('Business Name', data['businessName'] ?? '', Icons.storefront),
                              buildInfoRow('Seller Type', data['sellerType'] ?? '', Icons.category),
                              buildInfoRow('Phone', data['phone'] ?? '', Icons.phone),
                              buildInfoRow('Email', data['email'] ?? '', Icons.email),
                              buildInfoRow('WhatsApp', data['whatsapp'] ?? '', Icons.chat),
                              buildInfoRow('Shop Address', data['shopAddress'] ?? '', Icons.location_on),
                              buildInfoRow('Description', data['description'] ?? '', Icons.description),
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
