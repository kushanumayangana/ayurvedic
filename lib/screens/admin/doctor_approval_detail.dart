import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DoctorApprovalDetail extends StatelessWidget {
  final String docId;
  const DoctorApprovalDetail({super.key, required this.docId});

  @override
  Widget build(BuildContext context) {
    final CollectionReference doctors =
        FirebaseFirestore.instance.collection('doctors');

    return Scaffold(
      appBar: AppBar(
        title: const Text("Doctor Approval"),
        backgroundColor: Colors.green[800],
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: doctors.doc(docId).get(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text("Error loading doctor"));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['fullName'] ?? "",
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text("Email: ${data['email'] ?? ""}"),
                Text("NIC: ${data['nic'] ?? ""}"),
                Text("Registration No: ${data['regNo'] ?? ""}"),
                Text("Specialization: ${data['specialization'] ?? ""}"),
                Text("Clinic: ${data['clinicAddress'] ?? ""}"),
                const SizedBox(height: 16),
                const Text("Uploaded Documents:",
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                if (data['licenseUrl'] != null)
                  _documentTile("Medical License", data['licenseUrl']),
                if (data['nicFrontUrl'] != null)
                  _documentTile("NIC Front", data['nicFrontUrl']),
                if (data['nicBackUrl'] != null)
                  _documentTile("NIC Back", data['nicBackUrl']),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green),
                      onPressed: () async {
                        await doctors.doc(docId).update({'status': 'approved'});
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Doctor approved")),
                        );
                        Navigator.pop(context);
                      },
                      child: const Text("Approve"),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red),
                      onPressed: () async {
                        await doctors.doc(docId).update({'status': 'rejected'});
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Doctor rejected")),
                        );
                        Navigator.pop(context);
                      },
                      child: const Text("Reject"),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _documentTile(String title, String url) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        InkWell(
          onTap: () {
            // Open in browser or full-screen image viewer
          },
          child: Image.network(
            url,
            height: 150,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) =>
                const Text("Failed to load image"),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
