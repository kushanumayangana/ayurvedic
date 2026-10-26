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
import '../home/home.dart';
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
  final profileFormKey = GlobalKey<FormState>();
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

    try {
      final doc = await FirebaseFirestore.instance
          .collection('patients')
          .doc(user.uid)
          .get();

      if (doc.exists && mounted) {
        final data = doc.data() ?? <String, dynamic>{};
        final age = data['age'];
        setState(() {
          nameController.text = (data['name'] ?? '').toString();
          ageController.text = age?.toString() ?? '';
          profileImageUrl = (data['image'] ?? '').toString();
        });
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not load your profile: $error')),
        );
      }
    }
  }

  String? _validateName(String? value) {
    final name = value?.trim() ?? '';
    if (name.isEmpty) return 'Enter your full name';
    if (name.length < 2) return 'Name must be at least 2 characters';
    if (name.length > 80) return 'Name must be 80 characters or fewer';
    return null;
  }

  String? _validateAge(String? value) {
    final age = int.tryParse(value?.trim() ?? '');
    if (age == null) return 'Enter your age';
    if (age < 1 || age > 120) return 'Enter an age from 1 to 120';
    return null;
  }

  void _openHome(int section) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => HomePage(role: 'patient', initialSection: section),
      ),
    );
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
    try {
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (pickedFile != null && mounted) {
        setState(() {
          if (kIsWeb) {
            profileImageBytes = null;
          } else {
            profileImageFile = pickedFile;
          }
        });
        if (kIsWeb) {
          final bytes = await pickedFile.readAsBytes();
          if (mounted) setState(() => profileImageBytes = bytes);
        }
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not select image: $error')),
        );
      }
    }
  }

  // ================= CLOUDINARY UPLOAD =================
  Future<String?> uploadProfileImage() async {
    if ((kIsWeb && profileImageBytes == null) ||
        (!kIsWeb && profileImageFile == null)) {
      return null;
    }

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
    if (user == null || !profileFormKey.currentState!.validate()) return;

    setState(() => loading = true);

    try {
      final uploadedImageUrl = await uploadProfileImage();
      final name = nameController.text.trim();

      await FirebaseFirestore.instance
          .collection('patients')
          .doc(user.uid)
          .set({
            'name': name,
            'age': int.parse(ageController.text.trim()),
            if (uploadedImageUrl != null) "image": uploadedImageUrl,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
      await user.updateDisplayName(name);

      await loadProfile();

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Profile saved')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final profileImage = _profileImageProvider();
    final displayName = nameController.text.trim().isNotEmpty
        ? nameController.text.trim()
        : 'Welcome';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F8F6),
      appBar: AppBar(
        title: const Text(
          'My care',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: const Color(0xFFF5F8F6),
        foregroundColor: const Color(0xFF173E35),
        elevation: 0,
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
        padding: const EdgeInsets.fromLTRB(18, 4, 18, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF174C3C), Color(0xFF2F8062)],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF174C3C).withValues(alpha: 0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 9),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'YOUR WELLNESS, IN ONE PLACE',
                    style: TextStyle(
                      color: Color(0xFFD0E6D9),
                      fontSize: 11,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 11),
                  Text(
                    'Hello, $displayName',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 25,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 7),
                  const Text(
                    'Find trusted care, shop wellness essentials, and keep learning.',
                    style: TextStyle(
                      color: Color(0xFFE1EFE8),
                      height: 1.45,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      const Icon(
                        Icons.verified_user_outlined,
                        color: Color(0xFFC9E8D5),
                        size: 17,
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          user?.email ?? 'Verified patient account',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFFE1EFE8),
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),
            _sectionTitle('Explore care'),
            const SizedBox(height: 12),
            SizedBox(
              height: 152,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _quickAction(
                    title: 'Find a doctor',
                    subtitle: 'Book a consultation',
                    icon: Icons.medical_services_outlined,
                    section: 2,
                    color: const Color(0xFFE5F2EA),
                  ),
                  _quickAction(
                    title: 'Marketplace',
                    subtitle: 'Shop wellness products',
                    icon: Icons.shopping_bag_outlined,
                    section: 1,
                    color: const Color(0xFFFEF0D7),
                  ),
                  _quickAction(
                    title: 'Learning hub',
                    subtitle: 'Read expert articles',
                    icon: Icons.auto_stories_outlined,
                    section: 3,
                    color: const Color(0xFFE9E8F7),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 27),
            _sectionTitle('Your profile'),
            const SizedBox(height: 12),
            Card(
              margin: EdgeInsets.zero,
              color: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Form(
                  key: profileFormKey,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          InkWell(
                            onTap: loading ? null : pickProfileImage,
                            borderRadius: BorderRadius.circular(40),
                            child: Stack(
                              children: [
                                CircleAvatar(
                                  radius: 34,
                                  backgroundColor: const Color(0xFFE5F1EA),
                                  backgroundImage: profileImage,
                                  child: profileImage == null
                                      ? const Icon(
                                          Icons.person_outline,
                                          color:
                                              PatientDashboardPage.primaryGreen,
                                          size: 34,
                                        )
                                      : null,
                                ),
                                Positioned(
                                  right: 0,
                                  bottom: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(5),
                                    decoration: const BoxDecoration(
                                      color: PatientDashboardPage.primaryGreen,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.edit,
                                      color: Colors.white,
                                      size: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 13),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Personal details',
                                  style: TextStyle(
                                    color: Color(0xFF173E35),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Keep your information up to date.',
                                  style: TextStyle(
                                    color: Colors.blueGrey.shade600,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      TextFormField(
                        controller: nameController,
                        textCapitalization: TextCapitalization.words,
                        validator: _validateName,
                        decoration: _profileInput(
                          'Full name',
                          Icons.person_outline,
                        ),
                      ),
                      const SizedBox(height: 13),
                      TextFormField(
                        controller: ageController,
                        keyboardType: TextInputType.number,
                        validator: _validateAge,
                        decoration: _profileInput('Age', Icons.cake_outlined),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 49,
                        child: FilledButton.icon(
                          onPressed: loading ? null : saveProfile,
                          style: FilledButton.styleFrom(
                            backgroundColor: PatientDashboardPage.primaryGreen,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          icon: loading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.save_outlined),
                          label: Text(loading ? 'Saving...' : 'Save profile'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 27),
            _sectionTitle('My appointments'),
            const SizedBox(height: 12),
            StreamBuilder<QuerySnapshot>(
              stream: appointmentsStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return _infoCard(
                    'Appointments are unavailable right now.',
                    Icons.error_outline,
                  );
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(22),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final docs = snapshot.data?.docs.toList() ?? [];
                if (docs.isEmpty) {
                  return _infoCard(
                    'No appointments yet. Find a doctor to book your first visit.',
                    Icons.event_available_outlined,
                  );
                }
                docs.sort((a, b) {
                  final aData = a.data() as Map<String, dynamic>;
                  final bData = b.data() as Map<String, dynamic>;
                  final aTime = aData['createdAt'] is Timestamp
                      ? aData['createdAt'] as Timestamp
                      : Timestamp(0, 0);
                  final bTime = bData['createdAt'] is Timestamp
                      ? bData['createdAt'] as Timestamp
                      : Timestamp(0, 0);
                  return bTime.compareTo(aTime);
                });

                return Column(
                  children: docs.map((document) {
                    final data = document.data() as Map<String, dynamic>? ?? {};
                    final status = (data['status'] ?? 'pending').toString();
                    final isSellerBooking =
                        data['bookingType'] == 'seller' ||
                        (data['sellerId']?.toString().isNotEmpty ?? false);
                    final recipientName = isSellerBooking
                        ? data['sellerName']?.toString() ?? 'Seller'
                        : data['doctorName']?.toString() ?? 'Doctor';
                    final statusColor = status == 'approved'
                        ? const Color(0xFF24835D)
                        : status == 'rejected'
                        ? const Color(0xFFB74F49)
                        : const Color(0xFFB47A22);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      color: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 7,
                        ),
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFFE5F1EA),
                          child: Icon(
                            isSellerBooking
                                ? Icons.storefront_outlined
                                : Icons.medical_services_outlined,
                            color: PatientDashboardPage.primaryGreen,
                          ),
                        ),
                        title: Text(
                          recipientName,
                          style: const TextStyle(
                            color: Color(0xFF173E35),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 5),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${data['date'] ?? ''} · ${data['time'] ?? ''}',
                              ),
                              if ((data['productTitle']
                                      ?.toString()
                                      .isNotEmpty ??
                                  false))
                                Text('Item: ${data['productTitle']}'),
                              const SizedBox(height: 7),
                              Text(
                                status.toUpperCase(),
                                style: TextStyle(
                                  color: statusColor,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        trailing: IconButton(
                          tooltip: isSellerBooking
                              ? 'View seller profile'
                              : 'View doctor profile',
                          onPressed: () => _openBookingProfile(data),
                          icon: const Icon(Icons.arrow_forward_ios, size: 16),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 17),
            _sectionTitle('My orders'),
            const SizedBox(height: 12),
            const SizedBox(height: 380, child: BuyerOrdersTab()),
          ],
        ),
      ),
    );
  }

  ImageProvider? _profileImageProvider() {
    if (kIsWeb && profileImageBytes != null) {
      return MemoryImage(profileImageBytes!);
    }
    if (!kIsWeb && profileImageFile != null) {
      return FileImage(File(profileImageFile!.path));
    }
    if (profileImageUrl.isNotEmpty) return NetworkImage(profileImageUrl);
    return null;
  }

  Widget _sectionTitle(String title) => Text(
    title,
    style: const TextStyle(
      color: Color(0xFF173E35),
      fontSize: 19,
      fontWeight: FontWeight.w700,
    ),
  );

  Widget _quickAction({
    required String title,
    required String subtitle,
    required IconData icon,
    required int section,
    required Color color,
  }) {
    return InkWell(
      onTap: () => _openHome(section),
      borderRadius: BorderRadius.circular(19),
      child: Container(
        width: 166,
        margin: const EdgeInsets.only(right: 11),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(19),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: PatientDashboardPage.primaryGreen),
            ),
            const Spacer(),
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFF173E35),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.blueGrey.shade600, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoCard(String message, IconData icon) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(17),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(17),
      border: Border.all(color: Colors.grey.shade200),
    ),
    child: Row(
      children: [
        Icon(icon, color: PatientDashboardPage.primaryGreen),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            message,
            style: TextStyle(color: Colors.blueGrey.shade700, height: 1.4),
          ),
        ),
      ],
    ),
  );

  InputDecoration _profileInput(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20),
      filled: true,
      fillColor: const Color(0xFFF7F9F7),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
    );
  }
}
