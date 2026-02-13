import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../services/cloudinary_service.dart';

class SellerEditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> sellerData;
  const SellerEditProfileScreen({super.key, required this.sellerData});

  @override
  State<SellerEditProfileScreen> createState() => _SellerEditProfileScreenState();
}

class _SellerEditProfileScreenState extends State<SellerEditProfileScreen> {
  late TextEditingController nameCtrl;
  late TextEditingController whatsappCtrl;
  late TextEditingController phoneCtrl;
  late TextEditingController descCtrl;

  File? profileImageFile;
  XFile? profileImageWeb;
  String? currentImageUrl;

  final Color primaryColor = const Color(0xFF24615E);
  bool isLoading = false;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    nameCtrl = TextEditingController(text: widget.sellerData['fullName'] ?? '');
    whatsappCtrl = TextEditingController(text: widget.sellerData['whatsapp'] ?? '');
    phoneCtrl = TextEditingController(text: widget.sellerData['phone'] ?? '');
    descCtrl = TextEditingController(text: widget.sellerData['description'] ?? '');
    currentImageUrl = widget.sellerData['profileImage'] ?? '';
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    whatsappCtrl.dispose();
    phoneCtrl.dispose();
    descCtrl.dispose();
    super.dispose();
  }

  // Validation methods
  String? _validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Full name is required';
    }
    if (value.length < 3) {
      return 'Name must be at least 3 characters';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone is required';
    }
    // Check if phone contains only digits and common symbols
    if (!RegExp(r'^[\d\s\-\+\(\)]+$').hasMatch(value)) {
      return 'Phone must contain only numbers and symbols like -, +, ()';
    }
    if (value.replaceAll(RegExp(r'[^\d]'), '').length < 7) {
      return 'Phone must have at least 7 digits';
    }
    return null;
  }

  String? _validateWhatsApp(String? value) {
    if (value == null || value.isEmpty) {
      return 'WhatsApp number is required';
    }
    // Check if phone contains only digits and common symbols
    if (!RegExp(r'^[\d\s\-\+\(\)]+$').hasMatch(value)) {
      return 'WhatsApp must contain only numbers and symbols like -, +, ()';
    }
    if (value.replaceAll(RegExp(r'[^\d]'), '').length < 7) {
      return 'WhatsApp must have at least 7 digits';
    }
    return null;
  }

  String? _validateDescription(String? value) {
    if (value == null || value.isEmpty) {
      return 'Description is required';
    }
    if (value.length < 10) {
      return 'Description must be at least 10 characters';
    }
    if (value.length > 500) {
      return 'Description cannot exceed 500 characters';
    }
    return null;
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      if (kIsWeb) {
        profileImageWeb = picked;
      } else {
        profileImageFile = File(picked.path);
      }
      setState(() {});
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => isLoading = true);

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      String imgUrl = currentImageUrl ?? '';

      // Upload image if a new one was selected
      if (kIsWeb && profileImageWeb != null) {
        if (CloudinaryService.isConfigured()) {
          imgUrl = await CloudinaryService.uploadImageFromWeb(profileImageWeb!) ?? '';
          if (imgUrl.isEmpty) {
            _showSnackBar('Image upload failed. Check Cloudinary config', Colors.red);
            setState(() => isLoading = false);
            return;
          }
        } else {
          _showSnackBar('⚠️ Cloudinary not configured. Configure it in cloudinary_service.dart', Colors.orange);
          setState(() => isLoading = false);
          return;
        }
      } else if (!kIsWeb && profileImageFile != null) {
        if (CloudinaryService.isConfigured()) {
          imgUrl = await CloudinaryService.uploadImageFromFile(profileImageFile!) ?? '';
          if (imgUrl.isEmpty) {
            _showSnackBar('Image upload failed. Check Cloudinary config', Colors.red);
            setState(() => isLoading = false);
            return;
          }
        } else {
          // Fallback to Firebase Storage
          final ref = FirebaseStorage.instance.ref().child('profiles').child('$uid.jpg');
          await ref.putFile(profileImageFile!);
          imgUrl = await ref.getDownloadURL();
        }
      }

      // Update Firestore
      await FirebaseFirestore.instance.collection('sellers').doc(uid).update({
        'fullName': nameCtrl.text.trim(),
        'whatsapp': whatsappCtrl.text.trim(),
        'phone': phoneCtrl.text.trim(),
        'description': descCtrl.text.trim(),
        'profileImage': imgUrl,
        'updatedAt': Timestamp.now(),
      });

      _showSnackBar('Profile updated successfully! 🎉', Colors.green);
      Navigator.pop(context, true); // Return true to trigger refresh
    } catch (e) {
      _showSnackBar('Error: ${e.toString()}', Colors.red);
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showSnackBar(String message, Color bgColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: bgColor,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: const Text('Edit Profile'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Profile image
              GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: profileImageFile != null
                      ? FileImage(profileImageFile!) as ImageProvider
                      : (profileImageWeb != null
                          ? NetworkImage(profileImageWeb!.path)
                          : (currentImageUrl != null && currentImageUrl!.isNotEmpty
                              ? NetworkImage(currentImageUrl!)
                              : null)),
                  child: (profileImageFile == null && profileImageWeb == null && (currentImageUrl == null || currentImageUrl!.isEmpty))
                      ? const Icon(Icons.camera_alt)
                      : null,
                ),
              ),
              const SizedBox(height: 8),
              Text('Tap to change profile picture',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              const SizedBox(height: 24),

              // Name field
              TextFormField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                validator: _validateName,
              ),
              const SizedBox(height: 16),

              // Phone field
              TextFormField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: const Icon(Icons.phone),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  hintText: '+1 234 567 8900',
                ),
                validator: _validatePhone,
              ),
              const SizedBox(height: 16),

              // WhatsApp field
              TextFormField(
                controller: whatsappCtrl,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'WhatsApp Number',
                  prefixIcon: const Icon(Icons.chat),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  hintText: '+1 234 567 8900',
                ),
                validator: _validateWhatsApp,
              ),
              const SizedBox(height: 16),

              // Description field
              TextFormField(
                controller: descCtrl,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Description',
                  prefixIcon: const Icon(Icons.description),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  hintText: 'Write something about yourself...',
                ),
                validator: _validateDescription,
              ),
              const SizedBox(height: 32),

              // Save button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: isLoading ? null : _saveProfile,
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text(
                          'Save Changes',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
