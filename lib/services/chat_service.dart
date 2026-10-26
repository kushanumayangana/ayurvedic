import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

import 'cloudinary_service.dart';

class ChatService {
  static const int maxImageBytes = 8 * 1024 * 1024;

  static Future<Map<String, dynamic>> resolveParticipantProfile(
    String participantId,
    Map<String, dynamic> savedProfile,
  ) async {
    if (participantId.isEmpty) return savedProfile;

    final role = (savedProfile['role'] ?? '').toString().toLowerCase();
    final collections = role == 'seller'
        ? ['sellers', 'doctors', 'patients']
        : role == 'doctor'
        ? ['doctors', 'sellers', 'patients']
        : ['patients', 'sellers', 'doctors'];

    for (final collection in collections) {
      try {
        final snapshot = await FirebaseFirestore.instance
            .collection(collection)
            .doc(participantId)
            .get();
        if (!snapshot.exists) continue;
        final profile = snapshot.data() ?? <String, dynamic>{};
        final fresh = _profileRecord(
          direct: const {},
          fallbackName: savedProfile['name']?.toString() ?? 'Conversation',
          fallbackRole: role,
          profile: profile,
          extraKeys: const [],
        );
        return {
          ...savedProfile,
          ...profile,
          if ((fresh['name'] ?? '').toString().isNotEmpty)
            'name': fresh['name'],
          if ((fresh['image'] ?? '').toString().isNotEmpty)
            'image': fresh['image'],
          if ((fresh['role'] ?? '').toString().isNotEmpty)
            'role': fresh['role'],
        };
      } catch (_) {
        continue;
      }
    }

    return savedProfile;
  }

  static String conversationIdFor(String firstUserId, String secondUserId) {
    final ids = [firstUserId, secondUserId]..sort();
    return '${ids[0].length}:${ids[0]}${ids[1].length}:${ids[1]}';
  }

  static Future<String> openForOrder(
    Map<String, dynamic> order,
    String currentUserId,
  ) async {
    final buyerId = order['buyerId']?.toString() ?? '';
    final ownerId = order['ownerId']?.toString() ?? '';
    final sourceOrderId = order['sourceOrderId']?.toString() ?? '';
    if (buyerId.isEmpty || ownerId.isEmpty || buyerId == ownerId) {
      throw StateError('This order does not have two valid participants');
    }
    if (sourceOrderId.isEmpty) {
      throw StateError('The order reference is unavailable');
    }
    if (currentUserId != buyerId && currentUserId != ownerId) {
      throw StateError('You are not a participant in this order');
    }

    final buyerProfile = order['buyerProfile'] is Map
        ? Map<String, dynamic>.from(order['buyerProfile'] as Map)
        : <String, dynamic>{};
    final ownerProfile = order['ownerProfile'] is Map
        ? Map<String, dynamic>.from(order['ownerProfile'] as Map)
        : <String, dynamic>{};
    final buyerRecord = _profileRecord(
      direct: {
        'name': order['buyerName'],
        'image': order['buyerImage'],
        'role': order['buyerRole'],
      },
      fallbackName: 'Customer',
      fallbackRole: 'patient',
      profile: buyerProfile,
      extraKeys: const [
        'buyerPhotoUrl',
        'buyerAvatar',
        'buyerProfileImage',
        'buyerPicture',
        'buyerImageUrl',
      ],
    );
    final ownerRecord = _profileRecord(
      direct: {
        'name': order['ownerName'],
        'image': order['ownerImage'],
        'role': order['ownerType'],
      },
      fallbackName: 'Seller',
      fallbackRole: 'doctor',
      profile: ownerProfile,
      extraKeys: const [
        'ownerPhotoUrl',
        'ownerAvatar',
        'ownerProfileImage',
        'ownerPicture',
        'ownerImageUrl',
      ],
    );
    final profiles = <String, dynamic>{
      buyerId: buyerRecord,
      ownerId: ownerRecord,
    };

    final conversationId = conversationIdFor(buyerId, ownerId);
    final conversationRef = FirebaseFirestore.instance
        .collection('conversations')
        .doc(conversationId);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(conversationRef);
      if (snapshot.exists) {
        final existing = snapshot.data() ?? <String, dynamic>{};
        final currentProfiles = Map<String, dynamic>.from(
          existing['participantProfiles'] as Map? ?? <String, dynamic>{},
        );
        var needsUpdate = false;
        for (final entry in profiles.entries) {
          final profileKey = entry.key.toString();
          final currentProfile = Map<String, dynamic>.from(
            currentProfiles[profileKey] as Map? ?? <String, dynamic>{},
          );
          final nextProfile = Map<String, dynamic>.from(entry.value as Map);
          final currentName = (currentProfile['name'] ?? '').toString().trim();
          final nextName = (nextProfile['name'] ?? '').toString().trim();
          final currentImage = (currentProfile['image'] ?? '')
              .toString()
              .trim();
          final nextImage = (nextProfile['image'] ?? '').toString().trim();
          final currentRole = (currentProfile['role'] ?? '').toString().trim();
          final nextRole = (nextProfile['role'] ?? '').toString().trim();
          if (currentName != nextName && nextName.isNotEmpty ||
              currentImage != nextImage && nextImage.isNotEmpty ||
              currentRole != nextRole && nextRole.isNotEmpty) {
            currentProfiles[profileKey] = {
              ...currentProfile,
              if (nextName.isNotEmpty) 'name': nextName,
              if (nextImage.isNotEmpty) 'image': nextImage,
              if (nextRole.isNotEmpty) 'role': nextRole,
            };
            needsUpdate = true;
          }
        }
        if (needsUpdate) {
          transaction.update(conversationRef, {
            'participantProfiles': currentProfiles,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
        return;
      }

      transaction.set(conversationRef, {
        'participantIds': [buyerId, ownerId]..sort(),
        'participantProfiles': profiles,
        'sourceOrderId': sourceOrderId,
        'lastMessage': '',
        'lastMessageId': '',
        'lastMessageAt': FieldValue.serverTimestamp(),
        'lastSenderId': '',
        'unreadCounts': {buyerId: 0, ownerId: 0},
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });

    return conversationId;
  }

  static Future<String> openDirectConversation({
    required String otherUserId,
    required Map<String, dynamic> otherProfile,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('Sign in to send a message');
    if (otherUserId.isEmpty || otherUserId == user.uid) {
      throw StateError('This profile cannot be messaged');
    }

    final resolvedOtherProfile = await resolveParticipantProfile(
      otherUserId,
      otherProfile,
    );
    final resolvedCurrentProfile = await resolveParticipantProfile(user.uid, {
      'name': user.displayName ?? '',
      'image': user.photoURL ?? '',
    });
    final participantProfiles = <String, dynamic>{
      user.uid: _profileRecord(
        direct: {
          'name': user.displayName,
          'image': user.photoURL,
          'role': resolvedCurrentProfile['role'],
        },
        fallbackName: 'Member',
        fallbackRole: 'patient',
        profile: resolvedCurrentProfile,
        extraKeys: const [],
      ),
      otherUserId: _profileRecord(
        direct: {
          'name': otherProfile['name'],
          'image': otherProfile['image'],
          'role': otherProfile['role'],
        },
        fallbackName: 'Member',
        fallbackRole: 'member',
        profile: resolvedOtherProfile,
        extraKeys: const [],
      ),
    };

    final conversationId = conversationIdFor(user.uid, otherUserId);
    final conversationRef = FirebaseFirestore.instance
        .collection('conversations')
        .doc(conversationId);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(conversationRef);
      if (snapshot.exists) return;

      transaction.set(conversationRef, {
        'participantIds': [user.uid, otherUserId]..sort(),
        'participantProfiles': participantProfiles,
        'lastMessage': '',
        'lastMessageId': '',
        'lastMessageAt': FieldValue.serverTimestamp(),
        'lastSenderId': '',
        'unreadCounts': {user.uid: 0, otherUserId: 0},
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });

    return conversationId;
  }

  static Future<void> sendMessage({
    required String conversationId,
    required String text,
    String imageUrl = '',
    required String type,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('Sign in to send a message');
    final content = text.trim();
    if (content.isEmpty && imageUrl.isEmpty) {
      throw StateError('Write a message or choose a photo');
    }
    if (content.length > 4000) {
      throw StateError('Messages cannot exceed 4,000 characters');
    }

    final conversationRef = FirebaseFirestore.instance
        .collection('conversations')
        .doc(conversationId);
    final messageRef = conversationRef.collection('messages').doc();

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(conversationRef);
      if (!snapshot.exists) {
        throw StateError('This conversation is unavailable');
      }
      final conversation = snapshot.data() ?? <String, dynamic>{};
      final participants = (conversation['participantIds'] as List? ?? [])
          .map((value) => value.toString())
          .toList();
      if (!participants.contains(user.uid) || participants.length != 2) {
        throw StateError('You are not a participant in this conversation');
      }

      final recipientId = participants.firstWhere((id) => id != user.uid);
      final unreadCounts = Map<String, dynamic>.from(
        conversation['unreadCounts'] as Map? ?? <String, dynamic>{},
      );
      final unread =
          int.tryParse(unreadCounts[recipientId]?.toString() ?? '') ?? 0;
      unreadCounts[recipientId] = unread + 1;

      transaction.set(messageRef, {
        'senderId': user.uid,
        'text': content,
        'imageUrl': imageUrl,
        'type': type,
        'readBy': [user.uid],
        'createdAt': FieldValue.serverTimestamp(),
      });
      transaction.update(conversationRef, {
        'lastMessage': imageUrl.isNotEmpty && content.isEmpty
            ? 'Photo'
            : content,
        'lastMessageId': messageRef.id,
        'lastMessageAt': FieldValue.serverTimestamp(),
        'lastSenderId': user.uid,
        'unreadCounts': unreadCounts,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  static Future<void> deleteMessage({
    required String conversationId,
    required String messageId,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('Sign in to delete a message');

    final conversationRef = FirebaseFirestore.instance
        .collection('conversations')
        .doc(conversationId);
    final messageRef = conversationRef.collection('messages').doc(messageId);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final messageSnapshot = await transaction.get(messageRef);
      final conversationSnapshot = await transaction.get(conversationRef);
      if (!messageSnapshot.exists || !conversationSnapshot.exists) {
        throw StateError('This message is no longer available');
      }

      final message = messageSnapshot.data() ?? <String, dynamic>{};
      if (message['senderId'] != user.uid) {
        throw StateError('You can only delete your own messages');
      }

      final conversation = conversationSnapshot.data() ?? <String, dynamic>{};
      final preview =
          message['imageUrl']?.toString().isNotEmpty == true &&
              (message['text']?.toString().isEmpty ?? true)
          ? 'Photo'
          : message['text']?.toString() ?? '';
      final isLatestMessage =
          conversation['lastMessageId'] == messageId ||
          (!conversation.containsKey('lastMessageId') &&
              conversation['lastSenderId'] == user.uid &&
              conversation['lastMessage'] == preview);

      transaction.delete(messageRef);
      if (isLatestMessage) {
        transaction.update(conversationRef, {
          'lastMessage': 'Message deleted',
          'lastMessageId': '',
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  static Future<String> uploadPhoto(String conversationId, XFile photo) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('Sign in to share a photo');
    final bytes = await photo.readAsBytes();
    if (bytes.isEmpty || bytes.length > maxImageBytes) {
      throw StateError('Choose a photo smaller than 8 MB');
    }

    if (CloudinaryService.isConfigured()) {
      final uploadedUrl = await CloudinaryService.uploadImageFromWeb(photo);
      if (uploadedUrl != null && uploadedUrl.isNotEmpty) {
        return uploadedUrl;
      }
    }

    var extension = photo.name.contains('.')
        ? photo.name.split('.').last.toLowerCase()
        : 'jpg';
    if (!{'jpg', 'jpeg', 'png', 'webp', 'gif', 'heic'}.contains(extension)) {
      extension = 'jpg';
    }
    final path =
        'chat_images/$conversationId/${user.uid}/${DateTime.now().microsecondsSinceEpoch}.$extension';
    final reference = FirebaseStorage.instance.ref(path);
    final metadata = SettableMetadata(
      contentType: _imageContentType(extension),
    );
    await reference.putData(bytes, metadata);
    return reference.getDownloadURL();
  }

  static Future<void> markMessagesRead({
    required String conversationId,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> messages,
    required String userId,
  }) async {
    final unreadMessages = messages.where((message) {
      final data = message.data();
      final readBy = (data['readBy'] as List? ?? []).map(
        (value) => value.toString(),
      );
      return data['senderId'] != userId && !readBy.contains(userId);
    }).toList();
    if (unreadMessages.isEmpty) return;

    final conversationRef = FirebaseFirestore.instance
        .collection('conversations')
        .doc(conversationId);
    final batch = FirebaseFirestore.instance.batch();
    for (final message in unreadMessages) {
      batch.update(message.reference, {
        'readBy': FieldValue.arrayUnion([userId]),
      });
    }
    batch.update(conversationRef, {'unreadCounts.$userId': 0});
    await batch.commit();
  }

  static Map<String, dynamic> _profileRecord({
    required Map<String, dynamic> direct,
    required String fallbackName,
    required String fallbackRole,
    required Map<String, dynamic> profile,
    required List<String> extraKeys,
  }) {
    final nameCandidates = <dynamic>[
      direct['name'],
      profile['name'],
      profile['fullName'],
      profile['ownerName'],
      profile['businessName'],
      profile['username'],
      profile['displayName'],
      profile['firstName'],
      profile['lastName'],
      ...extraKeys.map((key) => profile[key]),
    ];
    final imageCandidates = <dynamic>[
      direct['image'],
      profile['image'],
      profile['profileImage'],
      profile['profileImageUrl'],
      profile['profilePic'],
      profile['photoUrl'],
      profile['photoURL'],
      profile['avatar'],
      profile['picture'],
      profile['imageUrl'],
      profile['img'],
      profile['profilePhoto'],
      profile['profile_picture'],
      profile['profile_image'],
      ...extraKeys.map((key) => profile[key]),
    ];
    final roleCandidates = <dynamic>[
      direct['role'],
      profile['role'],
      profile['userRole'],
      profile['accountType'],
    ];

    return {
      'name': _firstNonEmpty(nameCandidates, fallbackName),
      'image': _firstNonEmpty(imageCandidates),
      'role': _firstNonEmpty(roleCandidates, fallbackRole),
    };
  }

  static String _firstNonEmpty(
    Iterable<dynamic> values, [
    String fallback = '',
  ]) {
    for (final value in values) {
      final text = value?.toString().trim() ?? '';
      if (text.isNotEmpty) return text;
    }
    return fallback;
  }

  static String _imageContentType(String extension) {
    switch (extension) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'gif':
        return 'image/gif';
      case 'heic':
        return 'image/heic';
      default:
        return 'image/jpeg';
    }
  }
}
