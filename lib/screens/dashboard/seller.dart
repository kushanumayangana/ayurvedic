// lib/screens/dashboard/seller_dashboard.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

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
        child: Column(
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
                        // Navigate to profile edit page
                      },
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
}
