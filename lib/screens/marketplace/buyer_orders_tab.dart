import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../doctor/doctor_profile.dart';
import '../seller/seller_profile.dart';
import 'chat_pages.dart';

class BuyerOrdersTab extends StatelessWidget {
  const BuyerOrdersTab({super.key});

  String _statusLabel(String status) {
    switch (status) {
      case 'processing':
        return 'Preparing';
      case 'shipped':
        return 'In transit';
      case 'delivered':
        return 'Delivered';
      case 'cancelled':
        return 'Cancelled';
      default:
        return 'Order placed';
    }
  }

  void _openVendorProfile(BuildContext context, Map<String, dynamic> order) {
    final ownerId = order['ownerId']?.toString() ?? '';
    if (ownerId.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => order['ownerType'] == 'seller'
            ? SellerProfilePage(sellerId: ownerId)
            : DoctorProfilePage(doctorId: ownerId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (userId.isEmpty)
      return const Center(child: Text('Sign in to view your orders'));

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('buyerId', isEqualTo: userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError)
          return Center(
            child: Text('Could not load orders: ${snapshot.error}'),
          );

        final orders = snapshot.data?.docs.toList() ?? [];
        orders.sort((first, second) {
          final firstTime = first.data()['createdAt'];
          final secondTime = second.data()['createdAt'];
          final firstDate = firstTime is Timestamp
              ? firstTime.toDate()
              : DateTime.fromMillisecondsSinceEpoch(0);
          final secondDate = secondTime is Timestamp
              ? secondTime.toDate()
              : DateTime.fromMillisecondsSinceEpoch(0);
          return secondDate.compareTo(firstDate);
        });
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: orders.isEmpty ? 1 : orders.length,
          itemBuilder: (context, index) {
            if (orders.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('No orders yet'),
                ),
              );
            }

            final order = Map<String, dynamic>.from(orders[index].data())
              ..['sourceOrderId'] = orders[index].id;
            final status = order['status']?.toString() ?? 'pending';
            final cancelled = status == 'cancelled';
            final progress = status == 'delivered'
                ? 1.0
                : status == 'shipped'
                ? 0.72
                : status == 'processing'
                ? 0.42
                : 0.12;
            final image = order['productImage']?.toString() ?? '';
            final accent = order['ownerType'] == 'seller'
                ? const Color(0xFFC59D3F)
                : const Color(0xFF24615E);

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: image.isEmpty
                              ? Container(
                                  width: 58,
                                  height: 58,
                                  color: Colors.grey.shade100,
                                  child: const Icon(Icons.medication_outlined),
                                )
                              : Image.network(
                                  image,
                                  width: 58,
                                  height: 58,
                                  fit: BoxFit.cover,
                                ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                order['productTitle']?.toString() ?? 'Product',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'From ${order['ownerName'] ?? 'Marketplace vendor'}',
                                style: const TextStyle(
                                  color: Colors.black54,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                '${order['quantity'] ?? 1} item(s) · LKR ${order['total'] ?? 0}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'Message vendor',
                              onPressed: () => openOrderChat(
                                context,
                                order: order,
                                accentColor: accent,
                              ),
                              icon: Icon(
                                Icons.chat_bubble_outline,
                                color: accent,
                              ),
                            ),
                            IconButton(
                              tooltip: 'View vendor profile',
                              onPressed: () =>
                                  _openVendorProfile(context, order),
                              icon: Icon(
                                Icons.storefront_outlined,
                                color: accent,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: LinearProgressIndicator(
                            value: cancelled ? 0 : progress,
                            minHeight: 6,
                            backgroundColor: Colors.grey.shade200,
                            color: cancelled ? Colors.redAccent : accent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _statusLabel(status),
                          style: TextStyle(
                            color: cancelled ? Colors.redAccent : accent,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
