import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../admin/doctor_approval_list.dart';
import '../admin/seller_approval_list.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  final Color primaryGreen = const Color(0xFF2E7D32); // AppBar & Doctor
  final Color primaryOrange = const Color(0xFFF57C00); // Seller

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Dashboard"),
        backgroundColor: primaryGreen,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Doctor Approval Card
            Card(
              elevation: 5,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: primaryGreen.withOpacity(0.2),
                  child: const Icon(Icons.person_add, color: Colors.green),
                ),
                title: const Text(
                  "Doctor Approvals",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text("View & approve pending doctors"),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const DoctorApprovalList(),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 20),

            // Seller Approval Card with pending count badge
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('sellers')
                  .where('status', isEqualTo: 'pending')
                  .snapshots(),
              builder: (context, snapshot) {
                int pending = 0;
                if (snapshot.hasData) pending = snapshot.data!.docs.length;

                return Card(
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: primaryOrange.withOpacity(0.2),
                      child: const Icon(Icons.store, color: Colors.orange),
                    ),
                    title: const Text(
                      "Seller Approvals",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: const Text("View & approve seller applications"),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (pending > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '$pending',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_ios, size: 16),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SellerApprovalList(),
                        ),
                      );
                    },
                  ),
                );
              },
            ),

            const SizedBox(height: 20),

            // Optional: Quick Stats / Summary (example)
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Quick Summary",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 10),
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('doctors')
                          .snapshots(),
                      builder: (context, docSnapshot) {
                        int totalDoctors = 0;
                        if (docSnapshot.hasData) totalDoctors = docSnapshot.data!.docs.length;
                        return Text("Total Doctors Registered: $totalDoctors");
                      },
                    ),
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('sellers')
                          .snapshots(),
                      builder: (context, sellSnapshot) {
                        int totalSellers = 0;
                        if (sellSnapshot.hasData) totalSellers = sellSnapshot.data!.docs.length;
                        return Text("Total Sellers Registered: $totalSellers");
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
