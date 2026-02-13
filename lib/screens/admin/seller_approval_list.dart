import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'seller_approval_detail.dart';

class SellerApprovalList extends StatelessWidget {
  const SellerApprovalList({super.key});

  final Color primaryGold = const Color(0xFFC9A441);

  Future<void> updateStatus(String sellerId, String status) async {
    await FirebaseFirestore.instance.collection('sellers').doc(sellerId).update({
      'status': status,
      if (status == 'approved') 'approvedAt': FieldValue.serverTimestamp(),
      if (status == 'rejected') 'rejectedAt': FieldValue.serverTimestamp(),
    });

    await FirebaseFirestore.instance.collection('users').doc(sellerId).update({
      'isApproved': status == 'approved',
      'isRejected': status == 'rejected',
    });
  }

  Widget _statusBadge(String status) {
    Color color;
    String text;
    switch (status) {
      case 'approved':
        color = Colors.green;
        text = "Approved";
        break;
      case 'rejected':
        color = Colors.red;
        text = "Rejected";
        break;
      default:
        color = Colors.orange;
        text = "Pending";
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Seller Approvals"),
        backgroundColor: primaryGold,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('sellers')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No sellers found"));
          }

          final sellers = snapshot.data!.docs;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sellers.length,
            itemBuilder: (context, index) {
              final data = sellers[index].data() as Map<String, dynamic>;
              final sellerId = sellers[index].id;
              final status = data['status'] ?? 'pending';

              return Card(
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                margin: const EdgeInsets.only(bottom: 16),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: CircleAvatar(
                    radius: 25,
                    backgroundColor: primaryGold.withOpacity(0.2),
                    child: Icon(Icons.storefront_outlined, color: primaryGold, size: 28),
                  ),
                  title: Text(
                    data['businessName'] ?? 'Unknown Business',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text("Owner: ${data['ownerName'] ?? ''}"),
                      Text("Email: ${data['email'] ?? ''}"),
                      const SizedBox(height: 6),
                      _statusBadge(status),
                    ],
                  ),
                  trailing: Wrap(
                    spacing: 8,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.check_circle, color: Colors.green, size: 28),
                        onPressed: status != 'approved'
                            ? () => updateStatus(sellerId, 'approved')
                            : null,
                      ),
                      IconButton(
                        icon: const Icon(Icons.cancel, color: Colors.red, size: 28),
                        onPressed: status != 'rejected'
                            ? () => updateStatus(sellerId, 'rejected')
                            : null,
                      ),
                    ],
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SellerApprovalDetail(sellerId: sellerId),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
