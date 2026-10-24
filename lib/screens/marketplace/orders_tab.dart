import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'chat_pages.dart';
import '../../services/order_identity_service.dart';

class _SectionHeading extends StatelessWidget {
  final String title;

  const _SectionHeading(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 6),
      child: Text(
        title,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class OrdersTab extends StatelessWidget {
  final String ownerId;
  final Color accentColor;

  const OrdersTab({
    super.key,
    required this.ownerId,
    required this.accentColor,
  });

  Color _statusColor(String status) {
    switch (status) {
      case 'processing':
        return Colors.blue;
      case 'shipped':
        return Colors.deepPurple;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.redAccent;
      default:
        return Colors.orange;
    }
  }

  Future<void> _updateStatus(
    BuildContext context,
    String orderId,
    Map<String, dynamic> order,
    String status,
  ) async {
    final orders = FirebaseFirestore.instance.collection('orders');
    try {
      if (status == 'processing') {
        final productId = order['productId']?.toString() ?? '';
        if (productId.isEmpty)
          throw StateError('This order has no linked product');
        final orderRef = orders.doc(orderId);
        final productRef = FirebaseFirestore.instance
            .collection('products')
            .doc(productId);

        await FirebaseFirestore.instance.runTransaction((transaction) async {
          final latestOrder = await transaction.get(orderRef);
          final latestProduct = await transaction.get(productRef);
          if (!latestOrder.exists || !latestProduct.exists) {
            throw StateError('The order or product is no longer available');
          }
          final orderData = latestOrder.data() ?? <String, dynamic>{};
          if (orderData['ownerId'] != FirebaseAuth.instance.currentUser?.uid ||
              orderData['status'] != 'pending') {
            throw StateError('This order has already been updated');
          }

          final productData = latestProduct.data() ?? <String, dynamic>{};
          final stock =
              int.tryParse(productData['stock']?.toString() ?? '') ?? 0;
          final quantity =
              int.tryParse(orderData['quantity']?.toString() ?? '') ?? 1;
          if (stock < quantity)
            throw StateError('Not enough stock to accept this order');

          transaction.update(productRef, {'stock': stock - quantity});
          transaction.update(orderRef, {
            'status': 'processing',
            'updatedAt': FieldValue.serverTimestamp(),
          });
        });
      } else {
        await orders.doc(orderId).update({
          'status': status,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order marked ${_statusLabel(status).toLowerCase()}'),
        ),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not update order: $error')));
    }
  }

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
        return 'Pending';
    }
  }

  Future<Map<String, dynamic>> _resolveBuyerProfile(
    Map<String, dynamic> order,
  ) async {
    return OrderIdentityService.resolveBuyerProfile(order);
  }

  Future<void> _showBuyerDetails(
    BuildContext context,
    Map<String, dynamic> order,
  ) async {
    try {
      await OrderIdentityService.grantOrderOwnerProfileAccess(
        order['sourceOrderId']?.toString() ?? '',
        order,
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not load the full customer profile: $error'),
        ),
      );
    }

    final details = await _resolveBuyerProfile(order);
    if (!context.mounted) return;
    final buyerProfile = details['buyerProfile'] is Map
        ? Map<String, dynamic>.from(details['buyerProfile'] as Map)
        : <String, dynamic>{};
    final profileFields = buyerProfile.entries.where((entry) {
      final key = entry.key.toLowerCase();
      final value = entry.value;
      return !{
            'name',
            'fullname',
            'username',
            'profileimage',
            'image',
            'imageurl',
            'role',
            'email',
            'phone',
            'mobile',
            'updatedat',
            'createdat',
            'uid',
          }.contains(key) &&
          value != null &&
          value is! Map &&
          value is! List &&
          value.toString().trim().isNotEmpty;
    }).toList();
    final buyerImage = details['buyerImage']?.toString() ?? '';
    final buyerName = details['buyerName']?.toString() ?? 'Customer';

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(sheetContext).height * 0.82,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 4, 24, 20),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: accentColor.withValues(alpha: 0.12),
                  backgroundImage: buyerImage.isNotEmpty
                      ? NetworkImage(buyerImage)
                      : null,
                  child: buyerImage.isEmpty
                      ? Icon(Icons.person_outline, color: accentColor, size: 34)
                      : null,
                ),
                const SizedBox(height: 10),
                Text(
                  buyerName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  details['buyerRole']?.toString() ?? 'Customer',
                  style: const TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      openOrderChat(
                        context,
                        order: order,
                        accentColor: accentColor,
                      );
                    },
                    icon: const Icon(Icons.chat_bubble_outline),
                    label: const Text('Message customer'),
                  ),
                ),
                const SizedBox(height: 6),
                Expanded(
                  child: ListView(
                    children: [
                      const _SectionHeading('Contact & delivery'),
                      _detailRow(
                        Icons.phone_outlined,
                        _valueOrFallback(
                          details['buyerPhone'],
                          'Phone not provided',
                        ),
                      ),
                      _detailRow(
                        Icons.email_outlined,
                        _valueOrFallback(
                          details['buyerEmail'],
                          'Email not provided',
                        ),
                      ),
                      _detailRow(
                        Icons.location_on_outlined,
                        _valueOrFallback(
                          details['deliveryAddress'],
                          'Address not provided',
                        ),
                      ),
                      const SizedBox(height: 12),
                      const _SectionHeading('Customer profile'),
                      _profileDetailRow('Name', buyerName),
                      _profileDetailRow(
                        'Username',
                        _valueOrFallback(buyerProfile['username'], ''),
                      ),
                      _profileDetailRow(
                        'Age',
                        _valueOrFallback(buyerProfile['age'], ''),
                      ),
                      for (final entry in profileFields)
                        _profileDetailRow(
                          _humanize(entry.key),
                          entry.value.toString(),
                        ),
                      if (buyerProfile.isEmpty &&
                          _valueOrFallback(buyerProfile['age'], '').isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            'Only the information provided with this order is available.',
                            style: TextStyle(color: Colors.black54),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _valueOrFallback(dynamic value, String fallback) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  String _humanize(String value) {
    final spaced = value.replaceAllMapped(
      RegExp(r'([a-z])([A-Z])'),
      (match) => '${match[1]} ${match[2]}',
    );
    return spaced.isEmpty
        ? spaced
        : '${spaced[0].toUpperCase()}${spaced.substring(1)}';
  }

  Widget _profileDetailRow(String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 112,
            child: Text(label, style: const TextStyle(color: Colors.black54)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: accentColor),
        const SizedBox(width: 12),
        Expanded(child: Text(value)),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('ownerId', isEqualTo: ownerId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: accentColor));
        }
        if (snapshot.hasError) {
          return Center(
            child: Text('Could not load orders: ${snapshot.error}'),
          );
        }

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

            final document = orders[index];
            final order = Map<String, dynamic>.from(document.data())
              ..['sourceOrderId'] = document.id;
            final status = order['status']?.toString() ?? 'pending';
            final statusColor = _statusColor(status);
            final image = order['productImage']?.toString() ?? '';
            final canAdvance =
                status == 'pending' ||
                status == 'processing' ||
                status == 'shipped';

            Future.microtask(
              () =>
                  OrderIdentityService.repairOrderIfNeeded(document.id, order),
            );

            return FutureBuilder<Map<String, dynamic>>(
              future: _resolveBuyerProfile(order),
              builder: (context, buyerSnapshot) {
                final details = buyerSnapshot.data ?? order;
                final buyerInfo =
                    details['buyerName']?.toString() ?? 'Customer';
                final buyerImage = details['buyerImage']?.toString() ?? '';
                final buyerRole =
                    details['buyerRole']?.toString() ?? 'Customer';

                return Card(
                  margin: const EdgeInsets.only(bottom: 14),
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            InkWell(
                              customBorder: const CircleBorder(),
                              onTap: () => _showBuyerDetails(context, order),
                              child: CircleAvatar(
                                radius: 28,
                                backgroundColor: accentColor.withValues(
                                  alpha: 0.12,
                                ),
                                backgroundImage: buyerImage.isNotEmpty
                                    ? NetworkImage(buyerImage)
                                    : null,
                                child: buyerImage.isEmpty
                                    ? Icon(
                                        Icons.person_outline,
                                        color: accentColor,
                                        size: 28,
                                      )
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    buyerInfo,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    buyerRole,
                                    style: const TextStyle(
                                      color: Colors.black54,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    details['deliveryAddress']?.toString() ??
                                        'Address not provided',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.black87,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              tooltip: 'View buyer and delivery details',
                              onPressed: () =>
                                  _showBuyerDetails(context, order),
                              icon: Icon(
                                Icons.receipt_long_outlined,
                                color: accentColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Divider(height: 1, color: Colors.grey.shade200),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: image.isEmpty
                                  ? Container(
                                      width: 62,
                                      height: 62,
                                      color: Colors.grey.shade100,
                                      child: const Icon(
                                        Icons.medication_outlined,
                                      ),
                                    )
                                  : Image.network(
                                      image,
                                      width: 62,
                                      height: 62,
                                      fit: BoxFit.cover,
                                    ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    order['productTitle']?.toString() ??
                                        'Product',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${order['quantity'] ?? 1} × LKR ${order['unitPrice'] ?? 0}',
                                    style: const TextStyle(
                                      color: Colors.black54,
                                    ),
                                  ),
                                  Text(
                                    'Total LKR ${order['total'] ?? 0}',
                                    style: TextStyle(
                                      color: accentColor,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                _statusLabel(status),
                                style: TextStyle(
                                  color: statusColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const Spacer(),
                            if (status == 'pending') ...[
                              TextButton(
                                onPressed: () => _updateStatus(
                                  context,
                                  document.id,
                                  order,
                                  'cancelled',
                                ),
                                child: const Text(
                                  'Decline',
                                  style: TextStyle(color: Colors.redAccent),
                                ),
                              ),
                              const SizedBox(width: 6),
                              ElevatedButton(
                                onPressed: () => _updateStatus(
                                  context,
                                  document.id,
                                  order,
                                  'processing',
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: accentColor,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Accept'),
                              ),
                            ] else if (canAdvance) ...[
                              ElevatedButton.icon(
                                onPressed: () => _updateStatus(
                                  context,
                                  document.id,
                                  order,
                                  status == 'processing'
                                      ? 'shipped'
                                      : 'delivered',
                                ),
                                icon: Icon(
                                  status == 'processing'
                                      ? Icons.local_shipping_outlined
                                      : Icons.check_circle_outline,
                                ),
                                label: Text(
                                  status == 'processing'
                                      ? 'Mark shipped'
                                      : 'Mark delivered',
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: accentColor,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
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
      },
    );
  }
}
