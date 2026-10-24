import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OrderIdentityService {
  static List<String> priorityOrderForRole(String? explicitRole) {
    final role = (explicitRole ?? '').toLowerCase();
    switch (role) {
      case 'seller':
        return ['sellers'];
      case 'doctor':
        return ['doctors'];
      case 'patient':
        return ['patients'];
      default:
        return ['patients', 'sellers', 'doctors'];
    }
  }

  static Map<String, dynamic> resolvePreferredProfile(
    Map<String, dynamic> order,
    Map<String, Map<String, dynamic>> profileMap,
  ) {
    final fallback = Map<String, dynamic>.from(order);
    final explicitRole = (order['buyerRole'] ?? order['requesterRole'] ?? '')
        .toString()
        .toLowerCase();
    final candidateIds =
        [order['buyerId'], order['requesterId'], order['patientId']]
            .map((value) => value?.toString().trim() ?? '')
            .where((value) => value.isNotEmpty)
            .toSet()
            .toList();

    if (candidateIds.isEmpty) return fallback;

    for (final collection in priorityOrderForRole(explicitRole)) {
      for (final buyerId in candidateIds) {
        final profile = profileMap[collection]?[buyerId] ?? <String, dynamic>{};
        if (profile.isEmpty) continue;

        final resolvedRole = collection == 'sellers'
            ? 'seller'
            : collection == 'doctors'
            ? 'doctor'
            : 'patient';
        final resolvedName =
            [
                  profile['fullName'],
                  profile['ownerName'],
                  profile['businessName'],
                  profile['name'],
                ]
                .map((value) => value?.toString().trim() ?? '')
                .firstWhere(
                  (value) => value.isNotEmpty,
                  orElse: () => fallback['buyerName']?.toString() ?? 'Customer',
                );
        final resolvedImage =
            [
                  profile['profileImage'],
                  profile['profileImageUrl'],
                  profile['image'],
                  profile['imageUrl'],
                  profile['profilePic'],
                  fallback['buyerImage'],
                ]
                .map((value) => value?.toString().trim() ?? '')
                .firstWhere((value) => value.isNotEmpty, orElse: () => '');

        fallback['buyerId'] = buyerId;
        fallback['buyerName'] = resolvedName;
        fallback['buyerImage'] = resolvedImage;
        fallback['buyerEmail'] =
            (profile['email'] ??
                    profile['mail'] ??
                    fallback['buyerEmail'] ??
                    '')
                .toString();
        fallback['buyerPhone'] =
            (profile['phone'] ??
                    profile['mobile'] ??
                    fallback['buyerPhone'] ??
                    '')
                .toString();
        fallback['buyerRole'] = resolvedRole;
        fallback['buyerProfile'] = profile;
        return fallback;
      }
    }

    return fallback;
  }

  static Future<Map<String, dynamic>> resolveBuyerProfile(
    Map<String, dynamic> order,
  ) async {
    final fallback = Map<String, dynamic>.from(order);
    final explicitRole = (order['buyerRole'] ?? order['requesterRole'] ?? '')
        .toString()
        .toLowerCase();
    final candidateIds =
        [order['buyerId'], order['requesterId'], order['patientId']]
            .map((value) => value?.toString().trim() ?? '')
            .where((value) => value.isNotEmpty)
            .toSet()
            .toList();

    if (candidateIds.isEmpty) return fallback;

    final profileMap = <String, Map<String, dynamic>>{};
    for (final collection in priorityOrderForRole(explicitRole)) {
      for (final buyerId in candidateIds) {
        try {
          final profileDoc = await FirebaseFirestore.instance
              .collection(collection)
              .doc(buyerId)
              .get();
          if (!profileDoc.exists) continue;
          final data = profileDoc.data() ?? <String, dynamic>{};
          profileMap.putIfAbsent(collection, () => <String, dynamic>{});
          profileMap[collection]![buyerId] = data;
        } catch (_) {
          continue;
        }
      }
    }

    return resolvePreferredProfile(order, profileMap);
  }

  static Future<void> grantOrderOwnerProfileAccess(
    String orderId,
    Map<String, dynamic> order,
  ) async {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final buyerId = order['buyerId']?.toString() ?? '';
    final ownerId = order['ownerId']?.toString() ?? '';
    if (userId.isEmpty ||
        userId != ownerId ||
        buyerId.isEmpty ||
        orderId.isEmpty) {
      throw StateError('Only this order owner can view its customer profile');
    }

    final accessRef = FirebaseFirestore.instance
        .collection('customerProfileAccess')
        .doc(buyerId)
        .collection('vendors')
        .doc(ownerId);
    final orderRef = FirebaseFirestore.instance
        .collection('orders')
        .doc(orderId);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final accessSnapshot = await transaction.get(accessRef);
      if (accessSnapshot.exists) return;

      transaction.set(accessRef, {
        'orderId': orderId,
        'createdAt': FieldValue.serverTimestamp(),
      });
    });

    final orderSnapshot = await orderRef.get();
    final savedOrder = orderSnapshot.data() ?? <String, dynamic>{};
    if (!orderSnapshot.exists ||
        savedOrder['buyerId'] != buyerId ||
        savedOrder['ownerId'] != ownerId) {
      throw StateError('The order no longer grants access to this profile');
    }
  }

  static bool needsRepair(
    Map<String, dynamic> order,
    Map<String, dynamic> resolved,
  ) {
    final currentName = (order['buyerName'] ?? '').toString().trim();
    final nextName = (resolved['buyerName'] ?? '').toString().trim();
    final currentRole = (order['buyerRole'] ?? '').toString().trim();
    final nextRole = (resolved['buyerRole'] ?? '').toString().trim();
    final currentImage = (order['buyerImage'] ?? '').toString().trim();
    final nextImage = (resolved['buyerImage'] ?? '').toString().trim();

    return currentName != nextName ||
        currentRole != nextRole ||
        currentImage != nextImage;
  }

  static Future<void> repairOrderIfNeeded(
    String orderId,
    Map<String, dynamic> order,
  ) async {
    final resolved = await resolveBuyerProfile(order);
    if (!needsRepair(order, resolved)) return;

    final updates = <String, dynamic>{
      'buyerId': resolved['buyerId'] ?? order['buyerId'] ?? '',
      'buyerName': resolved['buyerName'] ?? order['buyerName'] ?? 'Customer',
      'buyerRole': resolved['buyerRole'] ?? order['buyerRole'] ?? 'customer',
      'buyerImage': resolved['buyerImage'] ?? order['buyerImage'] ?? '',
      'buyerEmail': resolved['buyerEmail'] ?? order['buyerEmail'] ?? '',
      'buyerPhone': resolved['buyerPhone'] ?? order['buyerPhone'] ?? '',
      'updatedAt': FieldValue.serverTimestamp(),
    };

    await FirebaseFirestore.instance
        .collection('orders')
        .doc(orderId)
        .update(updates);
  }
}
