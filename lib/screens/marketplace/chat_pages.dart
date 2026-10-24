import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/chat_service.dart';
import '../../services/order_identity_service.dart';

String _profileImageFromMap(Map<String, dynamic>? profile) {
  if (profile == null || profile.isEmpty) return '';

  const keys = [
    'image',
    'profileImage',
    'profilePic',
    'profile_photo',
    'profile_image',
    'photoUrl',
    'photoURL',
    'profileImageUrl',
    'avatar',
    'picture',
    'imageUrl',
    'profilePhoto',
    'img',
    'ownerImage',
    'buyerImage',
    'sellerImage',
    'doctorImage',
  ];

  for (final key in keys) {
    final value = profile[key];
    final text = value?.toString().trim();
    if (text != null && text.isNotEmpty) return text;
  }

  return '';
}

Future<void> _showParticipantDetails(
  BuildContext context, {
  required String participantId,
  required Map<String, dynamic> savedProfile,
  required Color accentColor,
}) async {
  final profile = await ChatService.resolveParticipantProfile(
    participantId,
    savedProfile,
  );
  if (!context.mounted) return;

  String firstValue(List<String> keys, [String fallback = '']) {
    for (final key in keys) {
      final value = profile[key]?.toString().trim() ?? '';
      if (value.isNotEmpty) return value;
    }
    return fallback;
  }

  final name = firstValue(['name', 'fullName', 'ownerName'], 'Conversation');
  final image = _profileImageFromMap(profile);
  final details = <(IconData, String, String)>[
    (
      Icons.email_outlined,
      'Email',
      firstValue(['email', 'emailAddress', 'buyerEmail', 'requesterEmail']),
    ),
    (
      Icons.phone_outlined,
      'Phone',
      firstValue([
        'phone',
        'mobile',
        'phoneNumber',
        'buyerPhone',
        'requesterPhone',
      ]),
    ),
    (
      Icons.storefront_outlined,
      'Business',
      firstValue(['businessName', 'shopName']),
    ),
    (
      Icons.medical_services_outlined,
      'Specialization',
      firstValue(['specialization', 'speciality']),
    ),
    (
      Icons.location_on_outlined,
      'Address',
      firstValue(['shopAddress', 'profileAddress', 'address']),
    ),
    (Icons.info_outline, 'About', firstValue(['description', 'bio'])),
  ].where((detail) => detail.$3.isNotEmpty).toList();

  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: CircleAvatar(
                radius: 38,
                backgroundColor: accentColor.withValues(alpha: 0.12),
                backgroundImage: image.isNotEmpty ? NetworkImage(image) : null,
                child: image.isEmpty
                    ? Icon(Icons.person_outline, color: accentColor, size: 36)
                    : null,
              ),
            ),
            const SizedBox(height: 14),
            Center(
              child: Text(
                name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Center(
              child: Text(
                firstValue(['role', 'userRole'], 'Member'),
                style: const TextStyle(color: Colors.black54),
              ),
            ),
            if (details.isNotEmpty) ...[
              const SizedBox(height: 22),
              ...details.map(
                (detail) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(detail.$1, size: 20, color: accentColor),
                      const SizedBox(width: 12),
                      Expanded(child: Text('${detail.$2}: ${detail.$3}')),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

class ChatInboxPage extends StatelessWidget {
  final String userId;
  final Color accentColor;

  const ChatInboxPage({
    super.key,
    required this.userId,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    if (userId.isEmpty) {
      return const Center(child: Text('Sign in to view messages'));
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('conversations')
          .where('participantIds', arrayContains: userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: accentColor));
        }
        if (snapshot.hasError) {
          return Center(
            child: Text('Could not load messages: ${snapshot.error}'),
          );
        }

        final conversations = snapshot.data?.docs.toList() ?? [];
        conversations.sort((first, second) {
          final firstDate = first.data()['lastMessageAt'];
          final secondDate = second.data()['lastMessageAt'];
          final firstTime = firstDate is Timestamp
              ? firstDate.toDate()
              : DateTime.fromMillisecondsSinceEpoch(0);
          final secondTime = secondDate is Timestamp
              ? secondDate.toDate()
              : DateTime.fromMillisecondsSinceEpoch(0);
          return secondTime.compareTo(firstTime);
        });
        if (conversations.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.forum_outlined, size: 52, color: Colors.black38),
                  SizedBox(height: 12),
                  Text('No conversations yet'),
                  SizedBox(height: 4),
                  Text(
                    'Start a conversation from an order.',
                    style: TextStyle(color: Colors.black54),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: conversations.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final document = conversations[index];
            final conversation = document.data();
            final participantProfiles = Map<String, dynamic>.from(
              conversation['participantProfiles'] as Map? ?? {},
            );
            final peerId = (conversation['participantIds'] as List? ?? [])
                .map((value) => value.toString())
                .firstWhere((id) => id != userId, orElse: () => '');
            final peer = Map<String, dynamic>.from(
              participantProfiles[peerId] as Map? ?? <String, dynamic>{},
            );
            final counts = Map<String, dynamic>.from(
              conversation['unreadCounts'] as Map? ?? <String, dynamic>{},
            );
            final unread = int.tryParse(counts[userId]?.toString() ?? '') ?? 0;
            return FutureBuilder<Map<String, dynamic>>(
              future: ChatService.resolveParticipantProfile(peerId, peer),
              builder: (context, profileSnapshot) {
                final currentPeer = profileSnapshot.data ?? peer;
                final image = _profileImageFromMap(currentPeer);

                return Card(
                  color: Colors.white,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => _showParticipantDetails(
                        context,
                        participantId: peerId,
                        savedProfile: currentPeer,
                        accentColor: accentColor,
                      ),
                      child: CircleAvatar(
                        radius: 27,
                        backgroundColor: accentColor.withValues(alpha: 0.12),
                        backgroundImage: image.isNotEmpty
                            ? NetworkImage(image)
                            : null,
                        child: image.isEmpty
                            ? Icon(Icons.person_outline, color: accentColor)
                            : null,
                      ),
                    ),
                    title: Text(
                      currentPeer['name']?.toString() ?? 'Conversation',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      conversation['lastMessage']?.toString().isNotEmpty == true
                          ? conversation['lastMessage'].toString()
                          : 'Start a conversation',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: unread > 0
                        ? CircleAvatar(
                            radius: 13,
                            backgroundColor: accentColor,
                            child: Text(
                              unread > 99 ? '99+' : '$unread',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                              ),
                            ),
                          )
                        : null,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatThreadPage(
                          conversationId: document.id,
                          currentUserId: userId,
                          accentColor: accentColor,
                        ),
                      ),
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

Future<void> openOrderChat(
  BuildContext context, {
  required Map<String, dynamic> order,
  required Color accentColor,
}) async {
  final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
  try {
    final buyerProfile = await OrderIdentityService.resolveBuyerProfile(order);
    final conversationId = await ChatService.openForOrder({
      ...order,
      ...buyerProfile,
    }, userId);
    if (!context.mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatThreadPage(
          conversationId: conversationId,
          currentUserId: userId,
          accentColor: accentColor,
        ),
      ),
    );
  } catch (error) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Could not open conversation: $error')),
    );
  }
}

class ChatThreadPage extends StatefulWidget {
  final String conversationId;
  final String currentUserId;
  final Color accentColor;

  const ChatThreadPage({
    super.key,
    required this.conversationId,
    required this.currentUserId,
    required this.accentColor,
  });

  @override
  State<ChatThreadPage> createState() => _ChatThreadPageState();
}

class _ChatThreadPageState extends State<ChatThreadPage> {
  final _messageController = TextEditingController();
  final _picker = ImagePicker();
  final Map<String, Future<Map<String, dynamic>>> _participantProfileFutures =
      {};
  bool _sending = false;
  String _lastReadBatch = '';

  Future<Map<String, dynamic>> _participantProfile(
    String participantId,
    Map<String, dynamic> savedProfile,
  ) {
    return _participantProfileFutures.putIfAbsent(
      participantId,
      () => ChatService.resolveParticipantProfile(participantId, savedProfile),
    );
  }

  Widget _participantAvatar({
    required String participantId,
    required Map<String, dynamic> profile,
    required double radius,
    required Color backgroundColor,
    required Color iconColor,
    required double iconSize,
  }) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _participantProfile(participantId, profile),
      builder: (context, snapshot) {
        final image = _profileImageFromMap(snapshot.data ?? profile);
        return InkWell(
          customBorder: const CircleBorder(),
          onTap: () => _showParticipantDetails(
            context,
            participantId: participantId,
            savedProfile: snapshot.data ?? profile,
            accentColor: widget.accentColor,
          ),
          child: CircleAvatar(
            radius: radius,
            backgroundColor: backgroundColor,
            backgroundImage: image.isNotEmpty ? NetworkImage(image) : null,
            child: image.isEmpty
                ? Icon(Icons.person_outline, size: iconSize, color: iconColor)
                : null,
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendText() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await ChatService.sendMessage(
        conversationId: widget.conversationId,
        text: text,
        type: 'text',
      );
      _messageController.clear();
    } catch (error) {
      _showError('Could not send message: $error');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _sendPhoto() async {
    if (_sending) return;
    try {
      final photo = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 82,
      );
      if (photo == null || !mounted) return;
      setState(() => _sending = true);
      final imageUrl = await ChatService.uploadPhoto(
        widget.conversationId,
        photo,
      );
      await ChatService.sendMessage(
        conversationId: widget.conversationId,
        text: _messageController.text.trim(),
        imageUrl: imageUrl,
        type: 'image',
      );
      _messageController.clear();
    } catch (error) {
      _showError('Could not share photo: $error');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _deleteMessage(String messageId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete message?'),
        content: const Text('This will permanently delete your message.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ChatService.deleteMessage(
        conversationId: widget.conversationId,
        messageId: messageId,
      );
    } catch (error) {
      _showError('Could not delete message: $error');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _markRead(List<QueryDocumentSnapshot<Map<String, dynamic>>> messages) {
    final unreadIds = messages
        .where((message) {
          final data = message.data();
          final readBy = (data['readBy'] as List? ?? []).map(
            (value) => value.toString(),
          );
          return data['senderId'] != widget.currentUserId &&
              !readBy.contains(widget.currentUserId);
        })
        .map((message) => message.id)
        .toList();
    if (unreadIds.isEmpty) {
      _lastReadBatch = '';
      return;
    }
    final key = unreadIds.join(',');
    if (key == _lastReadBatch) return;
    _lastReadBatch = key;
    ChatService.markMessagesRead(
      conversationId: widget.conversationId,
      messages: messages,
      userId: widget.currentUserId,
    ).catchError((Object error) {
      _lastReadBatch = '';
      _showError('Could not update read status: $error');
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = widget.currentUserId;
    final conversationRef = FirebaseFirestore.instance
        .collection('conversations')
        .doc(widget.conversationId);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      appBar: AppBar(
        backgroundColor: widget.accentColor,
        foregroundColor: Colors.white,
        titleSpacing: 0,
        title: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: conversationRef.snapshots(),
          builder: (context, snapshot) {
            final conversation = snapshot.data?.data() ?? <String, dynamic>{};
            final participants = Map<String, dynamic>.from(
              conversation['participantProfiles'] as Map? ?? {},
            );
            final peerId = (conversation['participantIds'] as List? ?? [])
                .map((value) => value.toString())
                .firstWhere((id) => id != currentUserId, orElse: () => '');
            final peer = Map<String, dynamic>.from(
              participants[peerId] as Map? ?? <String, dynamic>{},
            );
            return FutureBuilder<Map<String, dynamic>>(
              future: _participantProfile(peerId, peer),
              builder: (context, profileSnapshot) {
                final currentPeer = profileSnapshot.data ?? peer;
                return Row(
                  children: [
                    _participantAvatar(
                      participantId: peerId,
                      profile: peer,
                      radius: 19,
                      backgroundColor: Colors.white24,
                      iconColor: Colors.white,
                      iconSize: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        currentPeer['name']?.toString() ?? 'Conversation',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 17),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: conversationRef.snapshots(),
        builder: (context, conversationSnapshot) {
          final conversationData =
              conversationSnapshot.data?.data() ?? <String, dynamic>{};
          final participantProfiles = Map<String, dynamic>.from(
            conversationData['participantProfiles'] as Map? ??
                <String, dynamic>{},
          );

          return Column(
            children: [
              Expanded(
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: conversationRef
                      .collection('messages')
                      .orderBy('createdAt', descending: true)
                      .limit(100)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Could not load messages: ${snapshot.error}',
                        ),
                      );
                    }
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                        child: CircularProgressIndicator(
                          color: widget.accentColor,
                        ),
                      );
                    }

                    final messages = snapshot.data?.docs ?? [];
                    _markRead(messages);
                    if (messages.isEmpty) {
                      return const Center(
                        child: Text('Say hello to start the conversation'),
                      );
                    }

                    return ListView.builder(
                      reverse: true,
                      padding: const EdgeInsets.fromLTRB(14, 18, 14, 12),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final message = messages[index].data();
                        final messageId = messages[index].id;
                        final isMine = message['senderId'] == currentUserId;
                        final text = message['text']?.toString() ?? '';
                        final imageUrl = message['imageUrl']?.toString() ?? '';
                        final readBy = (message['readBy'] as List? ?? []).map(
                          (value) => value.toString(),
                        );
                        final isRead = isMine && readBy.length > 1;
                        final senderId = message['senderId']?.toString() ?? '';
                        final senderProfile = Map<String, dynamic>.from(
                          participantProfiles[senderId] as Map? ??
                              <String, dynamic>{},
                        );
                        return Align(
                          alignment: isMine
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            textDirection: isMine
                                ? TextDirection.rtl
                                : TextDirection.ltr,
                            children: [
                              if (!isMine) ...[
                                Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: _participantAvatar(
                                    participantId: senderId,
                                    profile: senderProfile,
                                    radius: 14,
                                    backgroundColor: widget.accentColor
                                        .withValues(alpha: 0.12),
                                    iconColor: Colors.black54,
                                    iconSize: 16,
                                  ),
                                ),
                              ],
                              Flexible(
                                child: Container(
                                  constraints: BoxConstraints(
                                    maxWidth:
                                        MediaQuery.sizeOf(context).width * 0.78,
                                  ),
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 5,
                                  ),
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: isMine
                                        ? widget.accentColor
                                        : Colors.white,
                                    borderRadius: BorderRadius.only(
                                      topLeft: const Radius.circular(16),
                                      topRight: const Radius.circular(16),
                                      bottomLeft: Radius.circular(
                                        isMine ? 16 : 4,
                                      ),
                                      bottomRight: Radius.circular(
                                        isMine ? 4 : 16,
                                      ),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.04,
                                        ),
                                        blurRadius: 5,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      if (imageUrl.isNotEmpty)
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          child: Image.network(
                                            imageUrl,
                                            width: 220,
                                            height: 180,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, _, _) =>
                                                const SizedBox(
                                                  width: 220,
                                                  height: 100,
                                                  child: Icon(
                                                    Icons.broken_image_outlined,
                                                  ),
                                                ),
                                          ),
                                        ),
                                      if (text.isNotEmpty) ...[
                                        if (imageUrl.isNotEmpty)
                                          const SizedBox(height: 6),
                                        SizedBox(
                                          width: double.infinity,
                                          child: Text(
                                            text,
                                            style: TextStyle(
                                              color: isMine
                                                  ? Colors.white
                                                  : Colors.black87,
                                            ),
                                          ),
                                        ),
                                      ],
                                      const SizedBox(height: 4),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            _formatTime(message['createdAt']),
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: isMine
                                                  ? Colors.white70
                                                  : Colors.black45,
                                            ),
                                          ),
                                          if (isMine) ...[
                                            const SizedBox(width: 5),
                                            Icon(
                                              isRead
                                                  ? Icons.done_all
                                                  : Icons.done,
                                              size: 14,
                                              color: isRead
                                                  ? Colors.lightBlueAccent
                                                  : Colors.white70,
                                            ),
                                            IconButton(
                                              tooltip: 'Delete message',
                                              visualDensity:
                                                  VisualDensity.compact,
                                              constraints:
                                                  const BoxConstraints.tightFor(
                                                    width: 30,
                                                    height: 30,
                                                  ),
                                              padding: EdgeInsets.zero,
                                              onPressed: () =>
                                                  _deleteMessage(messageId),
                                              icon: const Icon(
                                                Icons.delete_outline,
                                                size: 15,
                                                color: Colors.white70,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              if (isMine) ...[
                                Padding(
                                  padding: const EdgeInsets.only(left: 8),
                                  child: _participantAvatar(
                                    participantId: senderId,
                                    profile: senderProfile,
                                    radius: 14,
                                    backgroundColor: widget.accentColor
                                        .withValues(alpha: 0.12),
                                    iconColor: Colors.black54,
                                    iconSize: 16,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              SafeArea(
                top: false,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                  color: Colors.white,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      IconButton(
                        tooltip: 'Share a photo',
                        onPressed: _sending ? null : _sendPhoto,
                        icon: Icon(
                          Icons.image_outlined,
                          color: widget.accentColor,
                        ),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          minLines: 1,
                          maxLines: 5,
                          maxLength: 4000,
                          decoration: InputDecoration(
                            hintText: 'Message...',
                            counterText: '',
                            filled: true,
                            fillColor: const Color(0xFFF3F5F4),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 11,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          onSubmitted: (_) => _sendText(),
                        ),
                      ),
                      const SizedBox(width: 6),
                      IconButton.filled(
                        tooltip: 'Send message',
                        onPressed: _sending ? null : _sendText,
                        style: IconButton.styleFrom(
                          backgroundColor: widget.accentColor,
                        ),
                        icon: _sending
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(
                                Icons.send_rounded,
                                color: Colors.white,
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _formatTime(dynamic value) {
    if (value is! Timestamp) return 'Sending...';
    final date = value.toDate();
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute ${date.hour >= 12 ? 'PM' : 'AM'}';
  }
}
