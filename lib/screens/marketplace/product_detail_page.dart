import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../doctor/doctor_profile.dart';
import '../seller/seller_profile.dart';
import 'place_order_page.dart';

class ProductDetailPage extends StatefulWidget {
  final Map<String, dynamic> product;
  final String productId;

  const ProductDetailPage({
    super.key,
    required this.product,
    this.productId = '',
  });

  static String resolveVendorName({
    required Map<String, dynamic> profile,
    required Map<String, dynamic> product,
    required bool isSeller,
    String fallbackName = '',
  }) {
    final defaultName = fallbackName.isNotEmpty
        ? fallbackName
        : isSeller
        ? 'Marketplace seller'
        : 'Ayurvedic doctor';

    final values = [
      profile['fullName'],
      profile['ownerName'],
      profile['businessName'],
      product['ownerName'],
      defaultName,
    ];

    return values
        .map((value) => value?.toString().trim() ?? '')
        .firstWhere((value) => value.isNotEmpty, orElse: () => defaultName);
  }

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  final PageController _pageController = PageController();
  final TextEditingController _reviewController = TextEditingController();
  late final Stream<DocumentSnapshot<Map<String, dynamic>>> _orderCountStream;
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _reviewsStream;
  int _currentImageIndex = 0;
  int _selectedRating = 5;
  bool _submittingReview = false;
  final Map<String, Future<Map<String, String>>> _reviewerProfileFutures = {};

  Future<Map<String, String>> _loadCurrentReviewerProfile(User user) async {
    var name = user.displayName?.trim().isNotEmpty == true
        ? user.displayName!.trim()
        : user.email?.split('@').first ?? 'Member';
    var image = '';
    var role = 'user';

    for (final collection in ['sellers', 'doctors', 'patients']) {
      try {
        final snapshot = await FirebaseFirestore.instance
            .collection(collection)
            .doc(user.uid)
            .get();
        if (!snapshot.exists) continue;

        final profile = snapshot.data() ?? <String, dynamic>{};
        name =
            [
                  profile['fullName'],
                  profile['ownerName'],
                  profile['businessName'],
                  profile['name'],
                  name,
                ]
                .map((value) => value?.toString().trim() ?? '')
                .firstWhere(
                  (value) => value.isNotEmpty,
                  orElse: () => 'Member',
                );
        image =
            [
                  profile['profileImage'],
                  profile['image'],
                  profile['imageUrl'],
                  profile['profilePic'],
                  profile['photoUrl'],
                ]
                .map((value) => value?.toString().trim() ?? '')
                .firstWhere((value) => value.isNotEmpty, orElse: () => '');
        role = collection == 'patients'
            ? 'patient'
            : collection.substring(0, collection.length - 1);
        break;
      } catch (_) {
        continue;
      }
    }

    return {'name': name, 'image': image, 'role': role};
  }

  Future<Map<String, String>> _reviewerProfile(
    String reviewerId,
    Map<String, dynamic> review,
  ) {
    return _reviewerProfileFutures.putIfAbsent(reviewerId, () async {
      var name = review['reviewerName']?.toString().trim() ?? '';
      var image = review['reviewerImage']?.toString().trim() ?? '';
      var role = review['reviewerRole']?.toString().trim() ?? '';
      if (name.isNotEmpty && image.isNotEmpty) {
        return {'name': name, 'image': image, 'role': role};
      }

      final collections = switch (role) {
        'seller' => ['sellers', 'doctors', 'patients'],
        'doctor' => ['doctors', 'sellers', 'patients'],
        'patient' => ['patients', 'sellers', 'doctors'],
        _ => ['sellers', 'doctors', 'patients'],
      };

      for (final collection in collections) {
        try {
          final snapshot = await FirebaseFirestore.instance
              .collection(collection)
              .doc(reviewerId)
              .get();
          if (!snapshot.exists) continue;
          final profile = snapshot.data() ?? <String, dynamic>{};
          name =
              [
                    profile['fullName'],
                    profile['ownerName'],
                    profile['businessName'],
                    profile['name'],
                    name,
                  ]
                  .map((value) => value?.toString().trim() ?? '')
                  .firstWhere(
                    (value) => value.isNotEmpty,
                    orElse: () =>
                        'Member ${reviewerId.length > 6 ? reviewerId.substring(reviewerId.length - 6) : reviewerId}',
                  );
          image =
              [
                    profile['profileImage'],
                    profile['image'],
                    profile['imageUrl'],
                    profile['profilePic'],
                    profile['photoUrl'],
                    image,
                  ]
                  .map((value) => value?.toString().trim() ?? '')
                  .firstWhere((value) => value.isNotEmpty, orElse: () => '');
          role = collection == 'patients'
              ? 'patient'
              : collection.substring(0, collection.length - 1);
          if (name.isNotEmpty || image.isNotEmpty) break;
        } catch (_) {
          continue;
        }
      }

      if (name.isEmpty) {
        name =
            'Member ${reviewerId.length > 6 ? reviewerId.substring(reviewerId.length - 6) : reviewerId}';
      }
      return {'name': name, 'image': image, 'role': role};
    });
  }

  @override
  void initState() {
    super.initState();
    _orderCountStream = FirebaseFirestore.instance
        .collection('products')
        .doc(widget.productId)
        .snapshots();
    _reviewsStream = FirebaseFirestore.instance
        .collection('products')
        .doc(widget.productId)
        .collection('reviews')
        .snapshots();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _openOrderPage() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to place an order')),
      );
      return;
    }

    final sellerId = widget.product['sellerId']?.toString() ?? '';
    final doctorId = widget.product['doctorId']?.toString() ?? '';
    if (sellerId == user.uid || (sellerId.isEmpty && doctorId == user.uid)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You cannot order your own listing')),
      );
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PlaceOrderPage(
          productId: widget.productId,
          product: widget.product,
        ),
      ),
    );
  }

  List<String> get _images {
    final raw = widget.product['imageUrls'];
    if (raw is List) {
      return raw
          .map((item) => item.toString())
          .where((item) => item.isNotEmpty)
          .toList();
    }

    final single = widget.product['imageUrl']?.toString() ?? '';
    return single.isEmpty ? [] : [single];
  }

  Future<void> _openVendorProfile(String ownerId, bool isSeller) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => isSeller
            ? SellerProfilePage(sellerId: ownerId)
            : DoctorProfilePage(doctorId: ownerId),
      ),
    );
  }

  Widget _vendorProfile(String ownerId, bool isSeller) {
    final collection = isSeller ? 'sellers' : 'doctors';
    final accent = isSeller ? const Color(0xFFC59D3F) : const Color(0xFF24615E);

    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: FirebaseFirestore.instance
          .collection(collection)
          .doc(ownerId)
          .get(),
      builder: (context, snapshot) {
        final profile = snapshot.data?.data() ?? <String, dynamic>{};
        final name = ProductDetailPage.resolveVendorName(
          profile: profile,
          product: widget.product,
          isSeller: isSeller,
        );
        final image =
            [
                  profile['profileImage'],
                  profile['image'],
                  widget.product['ownerImage'],
                ]
                .map((value) => value?.toString().trim() ?? '')
                .firstWhere((value) => value.isNotEmpty, orElse: () => '');

        return Card(
          margin: EdgeInsets.zero,
          color: Colors.white,
          child: ListTile(
            onTap: () => _openVendorProfile(ownerId, isSeller),
            leading: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => _openVendorProfile(ownerId, isSeller),
              child: CircleAvatar(
                radius: 27,
                backgroundColor: accent.withOpacity(0.12),
                backgroundImage: image.isNotEmpty ? NetworkImage(image) : null,
                child: image.isEmpty
                    ? Icon(
                        isSeller
                            ? Icons.storefront_outlined
                            : Icons.medical_services_outlined,
                        color: accent,
                      )
                    : null,
              ),
            ),
            title: Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(isSeller ? 'Seller profile' : 'Doctor profile'),
            trailing: Icon(Icons.chevron_right, color: accent),
          ),
        );
      },
    );
  }

  Widget _orderCountRow() {
    if (widget.productId.isEmpty) {
      return _detailRow(
        'Orders',
        (widget.product['orderCount'] ?? 0).toString(),
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _orderCountStream,
      builder: (context, snapshot) {
        final data = snapshot.data?.data();
        final count = data?['orderCount'] ?? widget.product['orderCount'] ?? 0;
        return _detailRow('Orders placed', count.toString());
      },
    );
  }

  Future<void> _submitReview() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in to leave a rating or comment')),
      );
      return;
    }
    if (widget.productId.isEmpty) return;

    setState(() => _submittingReview = true);
    final reviewRef = FirebaseFirestore.instance
        .collection('products')
        .doc(widget.productId)
        .collection('reviews')
        .doc(user.uid);

    try {
      final existingReview = await reviewRef.get();
      final reviewerProfile = await _loadCurrentReviewerProfile(user);
      final review = <String, dynamic>{
        'rating': _selectedRating,
        'comment': _reviewController.text.trim(),
        'reviewerName': reviewerProfile['name'],
        'reviewerImage': reviewerProfile['image'],
        'reviewerRole': reviewerProfile['role'],
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (existingReview.exists) {
        await reviewRef.update(review);
      } else {
        await reviewRef.set({
          ...review,
          'reviewerId': user.uid,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      _reviewController.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Your review was saved')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not save review: $error')));
    } finally {
      if (mounted) setState(() => _submittingReview = false);
    }
  }

  Widget _reviewsSection() {
    if (widget.productId.isEmpty) return const SizedBox.shrink();
    final signedIn = FirebaseAuth.instance.currentUser != null;

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _reviewsStream,
      builder: (context, snapshot) {
        final documents = snapshot.data?.docs ?? [];
        final average = documents.isEmpty
            ? 0.0
            : documents.fold<double>(
                    0,
                    (sum, document) =>
                        sum +
                        ((document.data()['rating'] as num?)?.toDouble() ?? 0),
                  ) /
                  documents.length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ratings & comments',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1B4332),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.star, color: Color(0xFFD9A64E)),
                const SizedBox(width: 6),
                Text(
                  documents.isEmpty
                      ? 'No ratings yet'
                      : '${average.toStringAsFixed(1)} · ${documents.length} reviews',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (signedIn) ...[
              Row(
                children: List.generate(5, (index) {
                  final rating = index + 1;
                  return IconButton(
                    onPressed: () => setState(() => _selectedRating = rating),
                    tooltip: '$rating star${rating == 1 ? '' : 's'}',
                    visualDensity: VisualDensity.compact,
                    icon: Icon(
                      rating <= _selectedRating
                          ? Icons.star
                          : Icons.star_border,
                      color: const Color(0xFFD9A64E),
                    ),
                  );
                }),
              ),
              TextField(
                controller: _reviewController,
                minLines: 2,
                maxLines: 4,
                maxLength: 1000,
                decoration: const InputDecoration(
                  hintText: 'Share your experience with this item',
                  border: OutlineInputBorder(),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: _submittingReview ? null : _submitReview,
                  icon: _submittingReview
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send_outlined),
                  label: const Text('Submit review'),
                ),
              ),
              const SizedBox(height: 10),
            ] else
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Text('Sign in to rate and comment on this item.'),
              ),
            if (snapshot.hasError)
              const Text(
                'Reviews could not be loaded right now.',
                style: TextStyle(color: Colors.redAccent),
              )
            else if (documents.isEmpty)
              const Text(
                'Be the first to review this item.',
                style: TextStyle(color: Colors.black54),
              )
            else
              ...documents.map((document) {
                final review = document.data();
                final reviewerId =
                    review['reviewerId']?.toString() ?? document.id;
                final rating = (review['rating'] as num?)?.toInt() ?? 0;
                final comment = review['comment']?.toString() ?? '';
                return FutureBuilder<Map<String, String>>(
                  future: _reviewerProfile(reviewerId, review),
                  builder: (context, profileSnapshot) {
                    final profile =
                        profileSnapshot.data ??
                        review.map(
                          (key, value) =>
                              MapEntry(key, value?.toString() ?? ''),
                        );
                    final reviewerName =
                        profile['name']?.toString() ??
                        'Member ${reviewerId.length > 6 ? reviewerId.substring(reviewerId.length - 6) : reviewerId}';
                    final reviewerImage = profile['image']?.toString() ?? '';

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: const Color(
                          0xFF24615E,
                        ).withValues(alpha: 0.1),
                        backgroundImage: reviewerImage.isNotEmpty
                            ? NetworkImage(reviewerImage)
                            : null,
                        child: reviewerImage.isEmpty
                            ? const Icon(
                                Icons.person_outline,
                                color: Color(0xFF24615E),
                              )
                            : null,
                      ),
                      title: Text(reviewerName),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: List.generate(
                              5,
                              (index) => Icon(
                                index < rating ? Icons.star : Icons.star_border,
                                size: 16,
                                color: const Color(0xFFD9A64E),
                              ),
                            ),
                          ),
                          if (comment.isNotEmpty) Text(comment),
                        ],
                      ),
                    );
                  },
                );
              }),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final images = _images;
    final title = widget.product['title']?.toString() ?? 'Product';
    final category = widget.product['category']?.toString() ?? 'General';
    final description =
        widget.product['description']?.toString() ??
        'No description available.';
    final price = widget.product['price'];
    final stock = widget.product['stock'] ?? 0;
    final hasOrderTarget =
        (widget.product['sellerId']?.toString().isNotEmpty ?? false) ||
        (widget.product['doctorId']?.toString().isNotEmpty ?? false);
    final sellerId = widget.product['sellerId']?.toString() ?? '';
    final isSeller =
        sellerId.isNotEmpty || widget.product['ownerType'] == 'seller';
    final ownerId = isSeller
        ? sellerId
        : widget.product['doctorId']?.toString() ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Details'),
        backgroundColor: const Color(0xFF24615E),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (images.isNotEmpty)
                Container(
                  height: 300,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    color: Colors.grey[100],
                  ),
                  child: Stack(
                    children: [
                      PageView.builder(
                        controller: _pageController,
                        onPageChanged: (index) =>
                            setState(() => _currentImageIndex = index),
                        itemCount: images.length,
                        itemBuilder: (context, index) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: Image.network(
                              images[index],
                              fit: BoxFit.cover,
                              width: double.infinity,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Center(
                                    child: Icon(
                                      Icons.image_not_supported,
                                      size: 60,
                                      color: Colors.grey,
                                    ),
                                  ),
                            ),
                          );
                        },
                      ),
                      if (images.length > 1)
                        Positioned(
                          bottom: 12,
                          left: 0,
                          right: 0,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(images.length, (index) {
                              final active = index == _currentImageIndex;
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                width: active ? 18 : 8,
                                height: 8,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: active
                                      ? Colors.white
                                      : Colors.white.withOpacity(0.6),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              );
                            }),
                          ),
                        ),
                    ],
                  ),
                )
              else
                Container(
                  height: 220,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(
                    Icons.image_not_supported,
                    size: 60,
                    color: Colors.grey,
                  ),
                ),

              const SizedBox(height: 20),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B4332),
                ),
              ),
              const SizedBox(height: 8),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF24615E).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  category,
                  style: const TextStyle(
                    color: Color(0xFF24615E),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              const SizedBox(height: 18),
              Text(
                'LKR ${price.toString()}',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF24615E),
                ),
              ),
              const SizedBox(height: 20),

              if (ownerId.isNotEmpty) ...[
                _vendorProfile(ownerId, isSeller),
                const SizedBox(height: 20),
              ],

              _detailRow('Stock', stock.toString()),
              const SizedBox(height: 12),
              _detailRow(
                'Availability',
                stock > 0 ? 'In stock' : 'Out of stock',
              ),
              const SizedBox(height: 12),
              _orderCountRow(),

              const SizedBox(height: 24),
              const Text(
                'Description',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B4332),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.6,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 24),
              const Text(
                'All uploaded images',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B4332),
                ),
              ),
              const SizedBox(height: 12),
              if (images.isNotEmpty)
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: images.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1,
                  ),
                  itemBuilder: (context, index) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        images[index],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: Colors.grey[200],
                          child: const Icon(
                            Icons.broken_image,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    );
                  },
                )
              else
                const Text('No uploaded images available.'),
              const SizedBox(height: 28),
              _reviewsSection(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: hasOrderTarget && stock > 0
          ? SafeArea(
              minimum: const EdgeInsets.fromLTRB(16, 10, 16, 14),
              child: SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _openOrderPage,
                  icon: const Icon(Icons.shopping_bag_outlined),
                  label: const Text('Order now'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        widget.product['sellerId']?.toString().isNotEmpty ==
                            true
                        ? const Color(0xFFC59D3F)
                        : const Color(0xFF24615E),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _detailRow(String label, String value) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF1B4332),
          ),
        ),
        Expanded(
          child: Text(value, style: const TextStyle(color: Colors.black87)),
        ),
      ],
    );
  }
}
