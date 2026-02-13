import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class SellerApprovalDetail extends StatelessWidget {
  final String sellerId;
  const SellerApprovalDetail({super.key, required this.sellerId});

  final Color primaryGold = const Color(0xFFC9A441);

  // Function to launch URL
  void _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Seller Details"),
        backgroundColor: primaryGold,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('sellers').doc(sellerId).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          if (!snapshot.data!.exists) return const Center(child: Text("Seller not found"));

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final status = data['status'] ?? 'pending';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle("Business Information"),
                _buildDetailRow("Business Name", data['businessName']),
                _buildDetailRow("Shop Address", data['shopAddress']),
                _buildDetailRow("Seller Type", data['sellerType']),
                const SizedBox(height: 16),

                _buildSectionTitle("Owner Information"),
                _buildDetailRow("Owner Name", data['ownerName']),
                _buildDetailRow("Email", data['email']),
                _buildDetailRow("NIC Number", data['nicNumber'] ?? "-"),
                const SizedBox(height: 16),

                _buildSectionTitle("Licenses & Certificates"),
                _buildDocumentCard("BR Certificate", data['brCertificateUrl']),
                _buildDocumentCard("Drug License", data['drugLicenseUrl']),
                _buildDetailRow("Drug License Number", data['drugLicenseNumber']),
                _buildDetailRow("Drug License Expiry", data['drugLicenseExpiry']),
                const SizedBox(height: 16),

                _buildSectionTitle("Status"),
                _buildStatusTag(status),
                const SizedBox(height: 20),

                Center(
                  child: Wrap(
                    spacing: 16,
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                        icon: const Icon(Icons.check),
                        label: const Text("Approve"),
                        onPressed: status != 'approved'
                            ? () async {
                                await FirebaseFirestore.instance
                                    .collection('sellers')
                                    .doc(sellerId)
                                    .update({
                                  'status': 'approved',
                                  'approvedAt': FieldValue.serverTimestamp(),
                                });
                                await FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(sellerId)
                                    .update({'isApproved': true});
                              }
                            : null,
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        icon: const Icon(Icons.cancel),
                        label: const Text("Reject"),
                        onPressed: status != 'rejected'
                            ? () async {
                                await FirebaseFirestore.instance
                                    .collection('sellers')
                                    .doc(sellerId)
                                    .update({
                                  'status': 'rejected',
                                  'rejectedAt': FieldValue.serverTimestamp(),
                                });
                                await FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(sellerId)
                                    .update({'isRejected': true});
                              }
                            : null,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Section title
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
            fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
      ),
    );
  }

  // Detail row
  Widget _buildDetailRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$label: ",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: Text(value != null && value != '' ? value.toString() : "-"),
          ),
        ],
      ),
    );
  }

  // Document card
  Widget _buildDocumentCard(String title, String? url) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(Icons.file_present, color: primaryGold),
        title: Text(title),
        subtitle: Text(url != null ? "Uploaded" : "Not uploaded"),
        trailing: url != null
            ? IconButton(
                icon: const Icon(Icons.open_in_new, color: Colors.blue),
                onPressed: () => _launchURL(url),
              )
            : null,
      ),
    );
  }

  // Status tag
  Widget _buildStatusTag(String status) {
    Color color;
    String text;
    if (status == 'approved') {
      color = Colors.green;
      text = "Approved";
    } else if (status == 'rejected') {
      color = Colors.red;
      text = "Rejected";
    } else {
      color = Colors.orange;
      text = "Pending";
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }
}
