import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'doctor_approval_detail.dart';

class DoctorApprovalList extends StatelessWidget {
  const DoctorApprovalList({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pending Doctor Approvals"),
        backgroundColor: Colors.green[800],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('doctors')
            .where('status', isEqualTo: 'pending')
            .snapshots(),
        builder: (context, snapshot) {
          // Error handling
          if (snapshot.hasError) {
            return Center(
              child: Text("Error loading doctors: ${snapshot.error}"),
            );
          }

          // Loading state
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          // Debug log
          print("Fetched ${docs.length} doctor(s) for approval");

          if (docs.isEmpty) {
            return const Center(child: Text("No pending doctors"));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              // Safe casting for web compatibility
              final docDataRaw = docs[index].data();
              final docData =
                  docDataRaw is Map<String, dynamic> ? docDataRaw : {};

              print(
                  "Doctor: ${docData['fullName'] ?? 'No Name'}, Status: ${docData['status']}"); // Debug

              return Card(
                margin:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: const Icon(Icons.person, color: Colors.green),
                  title: Text(docData['fullName'] ?? "No Name"),
                  subtitle: Text(docData['specialization'] ?? ""),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            DoctorApprovalDetail(docId: docs[index].id),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}