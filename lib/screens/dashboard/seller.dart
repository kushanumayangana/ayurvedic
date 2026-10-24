import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../doctor/articles/write_article_page.dart';
import '../marketplace/addproductpage.dart';
import '../marketplace/buyer_orders_tab.dart';
import '../marketplace/chat_pages.dart';
import '../marketplace/orders_tab.dart';
import '../seller/seller_profile.dart';

class SellerDashboard extends StatefulWidget {
  const SellerDashboard({super.key});

  @override
  State<SellerDashboard> createState() => _SellerDashboardState();
}

class _SellerDashboardState extends State<SellerDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  String fullName = "Seller";
  String profileImage = "";
  bool hasProfile = false;

  final Color primaryGold = const Color(0xFFC59D3F);
  final Color orangeLight = const Color(0xFFFFF7ED);
  final Color accentCloud = const Color(0xFFFFF8E7);
  final Color priceColor = const Color(0xFFC59D3F);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
    _loadSellerData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadSellerData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (uid.isEmpty) return;

    final doc = await FirebaseFirestore.instance
        .collection("sellers")
        .doc(uid)
        .get();

    if (!doc.exists) {
      setState(() => hasProfile = false);
      return;
    }

    final data = doc.data()!;
    final profileName =
        [data['fullName'], data['ownerName'], data['businessName']]
            .map((value) => value?.toString().trim() ?? '')
            .firstWhere((value) => value.isNotEmpty, orElse: () => 'Seller');
    setState(() {
      fullName = profileName;
      profileImage = data['profileImage'] ?? "";
      hasProfile = true;
    });
  }

  Future<void> _adjustProductStock(String productId, int adjustment) async {
    final productRef = FirebaseFirestore.instance
        .collection('products')
        .doc(productId);

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(productRef);
        if (!snapshot.exists) throw StateError('Product no longer exists');

        final product = snapshot.data() ?? <String, dynamic>{};
        final stock = int.tryParse(product['stock']?.toString() ?? '') ?? 0;
        final updatedStock = stock + adjustment;
        if (updatedStock < 0) throw StateError('Stock cannot be negative');

        transaction.update(productRef, {'stock': updatedStock});
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not update stock: $error')));
    }
  }

  Widget _buildMyAppointmentsTab() {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (uid.isEmpty) {
      return _emptyState(
        Icons.event_busy_outlined,
        'Sign in to view appointments',
      );
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('appointments')
          .where('patientId', isEqualTo: uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Could not load your appointments: ${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final appointments = snapshot.data?.docs.toList() ?? [];
        appointments.sort((first, second) {
          final firstCreated = first.data()['createdAt'];
          final secondCreated = second.data()['createdAt'];
          final firstDate = firstCreated is Timestamp
              ? firstCreated.toDate()
              : DateTime.fromMillisecondsSinceEpoch(0);
          final secondDate = secondCreated is Timestamp
              ? secondCreated.toDate()
              : DateTime.fromMillisecondsSinceEpoch(0);
          return secondDate.compareTo(firstDate);
        });

        if (appointments.isEmpty) {
          return _emptyState(
            Icons.event_busy_outlined,
            'You have not requested any appointments yet',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: appointments.length,
          itemBuilder: (context, index) {
            final appointment = appointments[index].data();
            final status =
                appointment['status']?.toString().toLowerCase() ?? 'pending';
            final statusColor = status == 'approved'
                ? Colors.green
                : status == 'rejected'
                ? Colors.redAccent
                : Colors.orange;
            final doctorName =
                appointment['doctorName']?.toString().trim().isNotEmpty == true
                ? appointment['doctorName'].toString()
                : 'Doctor';

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: primaryGold.withValues(alpha: 0.14),
                          child: Icon(
                            Icons.medical_services_outlined,
                            color: primaryGold,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            doctorName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            status.toUpperCase(),
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 17,
                          color: primaryGold,
                        ),
                        const SizedBox(width: 9),
                        Text('Date: ${appointment['date'] ?? 'Not specified'}'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 17, color: primaryGold),
                        const SizedBox(width: 9),
                        Text('Time: ${appointment['time'] ?? 'Not specified'}'),
                      ],
                    ),
                    if (appointment['reason']?.toString().trim().isNotEmpty ==
                        true) ...[
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.notes_outlined,
                            size: 17,
                            color: primaryGold,
                          ),
                          const SizedBox(width: 9),
                          Expanded(
                            child: Text('Reason: ${appointment['reason']}'),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: primaryGold.withOpacity(0.12),
            backgroundImage: profileImage.isNotEmpty
                ? NetworkImage(profileImage)
                : null,
            child: profileImage.isEmpty
                ? const Icon(
                    Icons.storefront,
                    color: Color(0xFFC59D3F),
                    size: 30,
                  )
                : null,
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Welcome, $fullName",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const Text(
                  "Manage your profile and business",
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final refreshed = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SellerProfilePage(
                    sellerId: FirebaseAuth.instance.currentUser!.uid,
                  ),
                ),
              );
              if (refreshed == true) {
                _loadSellerData();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryGold,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text("Edit"),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(IconData icon, String text) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 60, color: Colors.grey[300]),
          const SizedBox(height: 8),
          Text(text, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> data, String docId) {
    final stock = int.tryParse(data['stock']?.toString() ?? '') ?? 0;
    List<String> images = [];
    if (data['imageUrls'] != null && data['imageUrls'] is List) {
      images = List<String>.from(
        data['imageUrls'].map((item) => item.toString()),
      );
    } else if (data['imageUrl'] != null &&
        data['imageUrl'].toString().isNotEmpty) {
      images = [data['imageUrl'].toString()];
    }

    final PageController cardImageController = PageController();
    int currentImageIndex = 0;

    return StatefulBuilder(
      builder: (context, setCardState) {
        return Container(
          margin: const EdgeInsets.only(bottom: 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 250,
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                      child: images.isNotEmpty
                          ? PageView.builder(
                              controller: cardImageController,
                              onPageChanged: (index) {
                                setCardState(() => currentImageIndex = index);
                              },
                              itemCount: images.length,
                              itemBuilder: (context, i) => Image.network(
                                images[i],
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Container(
                              color: Colors.grey[100],
                              child: const Center(
                                child: Icon(Icons.image_not_supported),
                              ),
                            ),
                    ),
                    Positioned(
                      top: 12,
                      right: 12,
                      child: GestureDetector(
                        onTap: () async {
                          await FirebaseFirestore.instance
                              .collection('products')
                              .doc(docId)
                              .delete();
                        },
                        child: CircleAvatar(
                          backgroundColor: Colors.white.withOpacity(0.9),
                          radius: 18,
                          child: const Icon(
                            Icons.delete_outline,
                            color: Colors.redAccent,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: primaryGold,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          data['category']?.toUpperCase() ?? "NEW",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    if (images.length > 1)
                      Positioned(
                        bottom: 12,
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(images.length, (index) {
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              height: 6,
                              width: currentImageIndex == index ? 18 : 6,
                              decoration: BoxDecoration(
                                color: currentImageIndex == index
                                    ? Colors.white
                                    : Colors.white54,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            );
                          }),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['title'] ?? "Product Name",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "LKR ${data['price']}",
                      style: TextStyle(
                        color: priceColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: accentCloud,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Product details",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            data['description'] ?? "No description available.",
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 13,
                              height: 1.4,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD4E157).withOpacity(0.3),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              IconButton(
                                tooltip: 'Decrease stock',
                                onPressed: stock > 0
                                    ? () => _adjustProductStock(docId, -1)
                                    : null,
                                icon: const Icon(Icons.remove, size: 16),
                                visualDensity: VisualDensity.compact,
                                constraints: const BoxConstraints.tightFor(
                                  width: 36,
                                  height: 36,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                child: Text(
                                  '$stock',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              IconButton(
                                tooltip: 'Increase stock',
                                onPressed: () => _adjustProductStock(docId, 1),
                                icon: const Icon(Icons.add, size: 16),
                                visualDensity: VisualDensity.compact,
                                constraints: const BoxConstraints.tightFor(
                                  width: 36,
                                  height: 36,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: primaryGold,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            "Inventory",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildShopTab() {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('products')
          .where('sellerId', isEqualTo: uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? [];
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length + (docs.isEmpty ? 2 : 1),
          itemBuilder: (context, index) {
            if (index == 0) return _buildProfileHeader();
            if (docs.isEmpty) {
              return SizedBox(
                height: 220,
                child: _emptyState(
                  Icons.storefront,
                  'Your shop is currently empty.',
                ),
              );
            }

            final productIndex = index - 1;
            final data = docs[productIndex].data() as Map<String, dynamic>;
            return _buildProductCard(data, docs[productIndex].id);
          },
        );
      },
    );
  }

  Widget _buildArticleTab() {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('articles')
          .where('sellerId', isEqualTo: uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Could not load articles: ${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final docs = snapshot.data?.docs.toList() ?? [];
        docs.sort((first, second) {
          final firstCreatedAt =
              (first.data() as Map<String, dynamic>)['createdAt'];
          final secondCreatedAt =
              (second.data() as Map<String, dynamic>)['createdAt'];
          final firstDate = firstCreatedAt is Timestamp
              ? firstCreatedAt.toDate()
              : DateTime.fromMillisecondsSinceEpoch(0);
          final secondDate = secondCreatedAt is Timestamp
              ? secondCreatedAt.toDate()
              : DateTime.fromMillisecondsSinceEpoch(0);
          return secondDate.compareTo(firstDate);
        });
        if (docs.isEmpty) {
          return _emptyState(
            Icons.note_alt_outlined,
            "No articles published yet",
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            return Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: (data['fileUrl'] != null && data['fileUrl'] != "")
                      ? Image.network(
                          data['fileUrl'],
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          color: Colors.grey[200],
                          width: 50,
                          height: 50,
                          child: const Icon(Icons.image),
                        ),
                ),
                title: Text(
                  data['title'] ?? "Untitled",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => WriteArticlePage(
                        doctorId: uid,
                        doctorName: fullName,
                        ownerType: 'seller',
                        ownerId: uid,
                        articleId: docs[index].id,
                        initialData: data,
                      ),
                    ),
                  );
                },
                trailing: IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.redAccent,
                  ),
                  onPressed: () async {
                    await FirebaseFirestore.instance
                        .collection('articles')
                        .doc(docs[index].id)
                        .delete();
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFab() {
    bool isShop = _tabController.index == 0;
    return FloatingActionButton.extended(
      onPressed: () {
        if (isShop) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddProductPage(
                doctorId: FirebaseAuth.instance.currentUser!.uid,
                sellerId: FirebaseAuth.instance.currentUser!.uid,
                ownerType: 'seller',
                ownerName: fullName,
                ownerImage: profileImage,
              ),
            ),
          );
        } else if (_tabController.index == 1) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => WriteArticlePage(
                doctorId: FirebaseAuth.instance.currentUser!.uid,
                doctorName: fullName,
                ownerType: 'seller',
                ownerId: FirebaseAuth.instance.currentUser!.uid,
              ),
            ),
          );
        }
      },
      backgroundColor: primaryGold,
      icon: Icon(
        isShop ? Icons.add_shopping_cart : Icons.edit_note,
        color: Colors.white,
      ),
      label: Text(
        isShop ? "Add Medicine" : "Write Article",
        style: const TextStyle(color: Colors.white),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!hasProfile && FirebaseAuth.instance.currentUser == null) {
      return const Scaffold(body: Center(child: Text("Please sign in first")));
    }

    return Scaffold(
      backgroundColor: accentCloud,
      appBar: AppBar(
        title: const Text(
          "Seller Dashboard",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        elevation: 0,
        centerTitle: true,
        backgroundColor: primaryGold,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.center,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: "My Shop", icon: Icon(Icons.storefront)),
            Tab(text: "Articles", icon: Icon(Icons.article)),
            Tab(text: "Orders", icon: Icon(Icons.shopping_bag_outlined)),
            Tab(text: "Messages", icon: Icon(Icons.chat_bubble_outline)),
            Tab(text: "My Appointments", icon: Icon(Icons.event_note_outlined)),
            Tab(text: "My Orders", icon: Icon(Icons.local_shipping_outlined)),
          ],
        ),
      ),
      body: hasProfile
          ? TabBarView(
              controller: _tabController,
              children: [
                _buildShopTab(),
                _buildArticleTab(),
                OrdersTab(
                  ownerId: FirebaseAuth.instance.currentUser?.uid ?? '',
                  accentColor: primaryGold,
                ),
                ChatInboxPage(
                  userId: FirebaseAuth.instance.currentUser?.uid ?? '',
                  accentColor: primaryGold,
                ),
                _buildMyAppointmentsTab(),
                const BuyerOrdersTab(),
              ],
            )
          : Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.person_add_alt,
                      size: 80,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "Complete your seller profile",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "Add your profile picture, business info, and contact details so customers and buyers can recognize you.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final refreshed = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SellerProfilePage(
                              sellerId: FirebaseAuth.instance.currentUser!.uid,
                            ),
                          ),
                        );
                        if (refreshed == true) {
                          _loadSellerData();
                        }
                      },
                      icon: const Icon(Icons.edit),
                      label: const Text("Create Seller Profile"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryGold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
      floatingActionButton: hasProfile && _tabController.index < 2
          ? _buildFab()
          : null,
    );
  }
}
