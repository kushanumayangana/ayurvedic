import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class DoctorProfilePage extends StatelessWidget {
  final String doctorId;

  const DoctorProfilePage({super.key, required this.doctorId});

  static const Color primaryGreen = Color(0xFF24615E);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Doctor Profile'),
        backgroundColor: primaryGreen,
        centerTitle: true,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('doctors')
            .doc(doctorId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.data!.exists) {
            return const Center(child: Text("Doctor not found"));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final name = data['fullName'] ?? data['name'] ?? 'Doctor';
          final profileImage = data['profileImage'] ?? '';
          final specialty = data['specialization'] ?? data['specialty'] ?? '';
          final email = data['email'] ?? '';
          final phone = data['phone'] ?? '';
          final whatsapp = data['whatsapp'] ?? '';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundImage: profileImage.isNotEmpty
                      ? NetworkImage(profileImage)
                      : null,
                  child: profileImage.isEmpty
                      ? const Icon(Icons.person, size: 60)
                      : null,
                ),
                const SizedBox(height: 16),
                Text(
                  'Dr. $name',
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  specialty,
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 20),

                Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.email, color: primaryGreen),
                            const SizedBox(width: 10),
                            Expanded(
                                child: Text(
                              email,
                              style: const TextStyle(fontSize: 16),
                            )),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(Icons.phone, color: primaryGreen),
                            const SizedBox(width: 10),
                            Expanded(
                                child: Text(
                              phone,
                              style: const TextStyle(fontSize: 16),
                            )),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (whatsapp.isNotEmpty)
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryGreen,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () async {
                              final url = "https://wa.me/$whatsapp";
                              if (await canLaunchUrl(Uri.parse(url))) {
                                await launchUrl(Uri.parse(url));
                              }
                            },
                            icon: const Icon(Icons.chat),
                            label: const Text("Chat on WhatsApp"),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
