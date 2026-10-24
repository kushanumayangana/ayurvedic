import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart'; // Added for modern dialogs
import 'package:cloud_firestore/cloud_firestore.dart';

import '../doctor/articles/write_article_page.dart';
import '../doctor/doctor_profile.dart';
import '../marketplace/addproductpage.dart';
import '../marketplace/buyer_orders_tab.dart';
import '../marketplace/chat_pages.dart';
import '../marketplace/orders_tab.dart';

class DoctorDashboardPage extends StatefulWidget {
  final String doctorId;
  const DoctorDashboardPage({super.key, required this.doctorId});

  @override
  State<DoctorDashboardPage> createState() => _DoctorDashboardPageState();
}

class _DoctorDashboardPageState extends State<DoctorDashboardPage>
    with SingleTickerProviderStateMixin {
  final Color primaryGreen = const Color(0xFF24615E);
  final Color accentCloud = const Color(0xFFF1F5F9);
  final Color priceColor = const Color(0xFFE57373);

  late TabController _tabController;
  String _doctorName = "Doctor";
  String _profileImageUrl = "";

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
    _fetchDoctorData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchDoctorData() async {
    final doc = await FirebaseFirestore.instance
        .collection('doctors')
        .doc(widget.doctorId)
        .get();
    if (doc.exists) {
      setState(() {
        _doctorName = doc.data()?['fullName'] ?? "Doctor";
        _profileImageUrl = doc.data()?['profileImage'] ?? "";
      });
    }
  }

  Future<void> _updateStatus(String docId, String status) async {
    try {
      await FirebaseFirestore.instance
          .collection('appointments')
          .doc(docId)
          .update({'status': status});

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Appointment $status ✅"),
          behavior: SnackBarBehavior.floating,
          backgroundColor: status == 'approved'
              ? Colors.green
              : Colors.redAccent,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Update failed: $e")));
    }
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update stock: $error')),
      );
    }
  }

  // --- MODERN DELETE FUNCTION WITH CONFIRMATION ---
  Future<void> _deleteDocument(String collection, String docId) async {
    // Show modern confirmation dialog
    bool confirm =
        await showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text("Confirm Delete"),
            content: const Text(
              "Are you sure you want to delete this item? This action cannot be undone.",
            ),
            actions: [
              CupertinoDialogAction(
                child: const Text("Cancel"),
                onPressed: () => Navigator.pop(context, false),
              ),
              CupertinoDialogAction(
                isDestructiveAction: true,
                child: const Text("Delete"),
                onPressed: () => Navigator.pop(context, true),
              ),
            ],
          ),
        ) ??
        false;

    if (confirm) {
      try {
        await FirebaseFirestore.instance
            .collection(collection)
            .doc(docId)
            .delete();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Deleted successfully ✅"),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.black87,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Delete failed: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.doctorId.isEmpty) {
      return const Scaffold(
        body: Center(child: Text("Error: No Doctor ID provided.")),
      );
    }

    return Scaffold(
      backgroundColor: accentCloud,
      appBar: AppBar(
        title: const Text(
          "Doctor Dashboard",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        elevation: 0,
        centerTitle: true,
        backgroundColor: primaryGreen,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.center,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: "Appointments", icon: Icon(Icons.calendar_today)),
            Tab(text: "Articles", icon: Icon(Icons.article)),
            Tab(text: "My Shop", icon: Icon(Icons.storefront)),
            Tab(text: "Orders", icon: Icon(Icons.shopping_bag_outlined)),
            Tab(text: "My Orders", icon: Icon(Icons.local_shipping_outlined)),
            Tab(text: "Messages", icon: Icon(Icons.chat_bubble_outline)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAppointmentTab(),
          _buildArticleTab(),
          _buildShopTab(),
          OrdersTab(ownerId: widget.doctorId, accentColor: primaryGreen),
          const BuyerOrdersTab(),
          ChatInboxPage(userId: widget.doctorId, accentColor: primaryGreen),
        ],
      ),
      floatingActionButton: _tabController.index >= 3 ? null : _buildFab(),
    );
  }

  Widget _buildFab() {
    bool isShop = _tabController.index == 2;
    return FloatingActionButton.extended(
      onPressed: () {
        if (isShop) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddProductPage(
                doctorId: widget.doctorId,
                ownerType: 'doctor',
                ownerName: _doctorName,
                ownerImage: _profileImageUrl,
              ),
            ),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => WriteArticlePage(
                doctorId: widget.doctorId,
                doctorName: _doctorName,
              ),
            ),
          );
        }
      },
      backgroundColor: primaryGreen,
      icon: Icon(
        isShop ? Icons.add_shopping_cart : Icons.edit_note,
        color: Colors.white,
      ),
      label: Text(
        isShop ? "Add Product" : "Write Article",
        style: const TextStyle(color: Colors.white),
      ),
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
            backgroundColor: primaryGreen.withOpacity(0.1),
            backgroundImage: _profileImageUrl.isNotEmpty
                ? NetworkImage(_profileImageUrl)
                : null,
            child: _profileImageUrl.isEmpty
                ? Icon(Icons.person, color: primaryGreen, size: 30)
                : null,
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Welcome, $_doctorName",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const Text(
                  "Manage your profile and schedule",
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DoctorProfilePage(doctorId: widget.doctorId),
                ),
              ).then((_) => _fetchDoctorData());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryGreen,
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

  Widget _buildAppointmentTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('appointments')
          .where('doctorId', isEqualTo: widget.doctorId)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data?.docs ?? [];
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) return _buildProfileHeader();
            final data = docs[index - 1].data() as Map<String, dynamic>;
            return _buildAppointmentCard(
              data,
              docs[index - 1].id,
              data['status'] ?? 'pending',
            );
          },
        );
      },
    );
  }

  Widget _buildAppointmentCard(
    Map<String, dynamic> data,
    String docId,
    String status,
  ) {
    final rawRole = (data['requesterRole'] ?? data['requesterType'] ?? '')
        .toString();
    final requesterId =
        (data['requesterId'] ?? data['patientId'] ?? data['buyerId'] ?? '')
            .toString();
    final isSellerRequester = rawRole == 'seller';

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              future: requesterId.isNotEmpty
                  ? (() async {
                      final sellerDoc = await FirebaseFirestore.instance
                          .collection('sellers')
                          .doc(requesterId)
                          .get();
                      if (sellerDoc.exists) {
                        return sellerDoc;
                      }
                      return FirebaseFirestore.instance
                          .collection('patients')
                          .doc(requesterId)
                          .get();
                    })()
                  : null,
              builder: (context, requesterSnapshot) {
                String requesterName =
                    data['requesterName']?.toString() ??
                    data['patientName']?.toString() ??
                    (isSellerRequester ? 'Seller' : 'Patient');
                String requesterImage =
                    data['requesterImage']?.toString() ??
                    data['patientImage']?.toString() ??
                    '';
                String requesterPhone =
                    data['requesterPhone']?.toString() ??
                    data['patientPhone']?.toString() ??
                    '';
                String requesterEmail =
                    data['requesterEmail']?.toString() ??
                    data['patientEmail']?.toString() ??
                    '';
                String requesterSubtitle = isSellerRequester
                    ? [data['businessName'], requesterPhone, requesterEmail]
                          .map((value) => value?.toString().trim() ?? '')
                          .where((value) => value.isNotEmpty)
                          .join(' • ')
                    : 'Age: ${data['patientAge']?.toString() ?? '-'}';

                if (requesterSnapshot.hasData &&
                    requesterSnapshot.data != null &&
                    requesterSnapshot.data!.exists) {
                  final profile =
                      requesterSnapshot.data!.data() ?? <String, dynamic>{};
                  final resolvedIsSeller =
                      rawRole == 'seller' ||
                      (profile['businessName']?.toString().trim().isNotEmpty ==
                              true ||
                          profile['ownerName']?.toString().trim().isNotEmpty ==
                              true);
                  final profileNameFields = resolvedIsSeller
                      ? [
                          profile['fullName'],
                          profile['ownerName'],
                          profile['businessName'],
                        ]
                      : [profile['name'], profile['fullName']];
                  requesterName = profileNameFields
                      .map((value) => value?.toString().trim() ?? '')
                      .firstWhere(
                        (value) => value.isNotEmpty,
                        orElse: () => requesterName,
                      );

                  requesterImage =
                      (resolvedIsSeller
                              ? profile['profileImage'] ??
                                    profile['image'] ??
                                    profile['imageUrl']
                              : profile['image'] ??
                                    profile['profileImage'] ??
                                    profile['imageUrl'])
                          ?.toString() ??
                      requesterImage;
                  requesterPhone =
                      (profile['phone'] ?? profile['mobile'] ?? requesterPhone)
                          .toString();
                  requesterEmail =
                      (profile['email'] ?? profile['mail'] ?? requesterEmail)
                          .toString();

                  requesterSubtitle = resolvedIsSeller
                      ? [
                              profile['businessName'],
                              requesterPhone,
                              requesterEmail,
                            ]
                            .map((value) => value?.toString().trim() ?? '')
                            .where((value) => value.isNotEmpty)
                            .join(' • ')
                      : 'Age: ${profile['age']?.toString() ?? data['patientAge']?.toString() ?? '-'}';
                }

                return Row(
                  children: [
                    Tooltip(
                      message: 'View requester profile',
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => _showRequesterDetails(
                          data,
                          isSellerRequester: isSellerRequester,
                          requesterId: requesterId,
                        ),
                        child: CircleAvatar(
                          radius: 25,
                          backgroundColor: primaryGreen.withOpacity(0.1),
                          backgroundImage: requesterImage.isNotEmpty
                              ? NetworkImage(requesterImage)
                              : null,
                          child: requesterImage.isEmpty
                              ? Icon(Icons.person, color: primaryGreen)
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            requesterName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          if (requesterSubtitle.isNotEmpty)
                            Text(
                              requesterSubtitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ),
                    _buildStatusBadge(status),
                  ],
                );
              },
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildInfoRow(
                  Icons.calendar_today,
                  "Date",
                  data['date'] ?? '-',
                ),
                const SizedBox(height: 8),
                _buildInfoRow(Icons.access_time, "Time", data['time'] ?? '-'),
                const SizedBox(height: 8),
                _buildInfoRow(
                  Icons.notes,
                  "Reason",
                  data['reason'] ?? 'No description',
                ),
              ],
            ),
          ),
          if (status == 'pending')
            Padding(
              padding: const EdgeInsets.only(bottom: 12, right: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _buildActionButton(
                    "Reject",
                    Colors.redAccent,
                    () => _updateStatus(docId, 'rejected'),
                  ),
                  const SizedBox(width: 8),
                  _buildActionButton(
                    "Approve",
                    Colors.green,
                    () => _updateStatus(docId, 'approved'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _showRequesterDetails(
    Map<String, dynamic> appointment, {
    required bool isSellerRequester,
    String requesterId = '',
  }) async {
    final resolvedRequesterId =
        (requesterId.isNotEmpty
                ? requesterId
                : appointment['requesterId'] ??
                      appointment['patientId'] ??
                      appointment['buyerId'] ??
                      '')
            .toString();
    final resolvedRole =
        (appointment['requesterRole'] ?? appointment['requesterType'] ?? '')
            .toString();
    final effectiveIsSellerRequester =
        isSellerRequester || (resolvedRole == 'seller');
    var profile = <String, dynamic>{};

    if (resolvedRequesterId.isNotEmpty) {
      try {
        final sellerSnapshot = await FirebaseFirestore.instance
            .collection('sellers')
            .doc(resolvedRequesterId)
            .get();
        if (sellerSnapshot.exists) {
          profile = sellerSnapshot.data() ?? <String, dynamic>{};
        } else {
          final patientSnapshot = await FirebaseFirestore.instance
              .collection('patients')
              .doc(resolvedRequesterId)
              .get();
          if (patientSnapshot.exists) {
            profile = patientSnapshot.data() ?? <String, dynamic>{};
          }
        }
      } catch (_) {
        // Keep the requester details already stored with the appointment.
      }
    }

    if (!mounted) return;

    String firstValue(Iterable<dynamic> values) {
      for (final value in values) {
        final text = value?.toString().trim() ?? '';
        if (text.isNotEmpty) return text;
      }
      return 'Not provided';
    }

    final name = effectiveIsSellerRequester
        ? firstValue([
            profile['fullName'],
            profile['ownerName'],
            profile['businessName'],
            appointment['requesterName'],
            appointment['patientName'],
          ])
        : firstValue([
            profile['name'],
            profile['fullName'],
            profile['username'],
            appointment['requesterName'],
            appointment['patientName'],
          ]);
    final image = firstValue([
      if (effectiveIsSellerRequester) ...[
        profile['profileImage'],
        profile['image'],
        profile['imageUrl'],
      ] else ...[
        profile['image'],
        profile['profileImage'],
        profile['imageUrl'],
      ],
      appointment['requesterImage'],
      appointment['patientImage'],
    ]);
    final email = firstValue([
      profile['email'],
      profile['mail'],
      appointment['requesterEmail'],
      appointment['patientEmail'],
    ]);
    final phone = firstValue([
      profile['phone'],
      profile['mobile'],
      appointment['requesterPhone'],
      appointment['patientPhone'],
    ]);

    final details = effectiveIsSellerRequester
        ? <(IconData, String, String)>[
            (
              Icons.storefront_outlined,
              'Business',
              firstValue([profile['businessName']]),
            ),
            (
              Icons.category_outlined,
              'Seller type',
              firstValue([profile['sellerType']]),
            ),
            (Icons.phone_outlined, 'Phone', phone),
            (
              Icons.chat_outlined,
              'WhatsApp',
              firstValue([profile['whatsapp']]),
            ),
            (Icons.email_outlined, 'Email', email),
            (
              Icons.location_on_outlined,
              'Address',
              firstValue([profile['shopAddress']]),
            ),
          ]
        : <(IconData, String, String)>[
            (
              Icons.cake_outlined,
              'Age',
              firstValue([profile['age'], appointment['patientAge']]),
            ),
            (Icons.phone_outlined, 'Phone', phone),
            (Icons.email_outlined, 'Email', email),
          ];

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: CircleAvatar(
                  radius: 42,
                  backgroundColor: primaryGreen.withOpacity(0.1),
                  backgroundImage: image != 'Not provided'
                      ? NetworkImage(image)
                      : null,
                  child: image == 'Not provided'
                      ? Icon(Icons.person, color: primaryGreen, size: 38)
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
                  textAlign: TextAlign.center,
                ),
              ),
              Center(
                child: Text(
                  effectiveIsSellerRequester ? 'Seller' : 'Patient',
                  style: const TextStyle(color: Colors.black54),
                ),
              ),
              const SizedBox(height: 20),
              ...details.map(
                (detail) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _requesterDetailRow(detail.$1, detail.$2, detail.$3),
                ),
              ),
              if (effectiveIsSellerRequester &&
                  (profile['description']?.toString().trim().isNotEmpty ??
                      false)) ...[
                const Divider(height: 8),
                const SizedBox(height: 10),
                Text(
                  profile['description'].toString(),
                  style: const TextStyle(color: Colors.black87, height: 1.4),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _requesterDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: primaryGreen),
        const SizedBox(width: 12),
        SizedBox(width: 82, child: Text(label)),
        Expanded(child: Text(value, softWrap: true)),
      ],
    );
  }

  Widget _buildArticleTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('articles')
          .where('doctorId', isEqualTo: widget.doctorId)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty)
          return _emptyState(
            Icons.note_alt_outlined,
            "No articles published yet",
          );

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
                        doctorId: widget.doctorId,
                        doctorName: _doctorName,
                        ownerType: 'doctor',
                        ownerId: widget.doctorId,
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
                  onPressed: () => _deleteDocument('articles', docs[index].id),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildShopTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('products')
          .where('doctorId', isEqualTo: widget.doctorId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty)
          return _emptyState(Icons.storefront, "Your shop is currently empty.");

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            return _buildProductCard(data, docs[index].id);
          },
        );
      },
    );
  }

  Widget _buildProductCard(Map<String, dynamic> data, String docId) {
    List<String> images = [];
    final stock = int.tryParse(data['stock']?.toString() ?? '') ?? 0;
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
                                setCardState(() {
                                  currentImageIndex = index;
                                });
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
                        onTap: () => _deleteDocument('products', docId),
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
                          color: primaryGreen,
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
                        _buildBeautyStockCounter(
                          stock,
                          onDecrease: stock > 0
                              ? () => _adjustProductStock(docId, -1)
                              : null,
                          onIncrease: () => _adjustProductStock(docId, 1),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: primaryGreen,
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

  Widget _buildBeautyStockCounter(
    int stock, {
    required VoidCallback? onDecrease,
    required VoidCallback onIncrease,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFD4E157).withOpacity(0.3),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Decrease stock',
            onPressed: onDecrease,
            icon: const Icon(Icons.remove, size: 16),
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints.tightFor(width: 36, height: 36),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              "$stock",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          IconButton(
            tooltip: 'Increase stock',
            onPressed: onIncrease,
            icon: const Icon(Icons.add, size: 16),
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints.tightFor(width: 36, height: 36),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: primaryGreen),
        const SizedBox(width: 10),
        Text("$label: $value"),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = status == 'approved'
        ? Colors.green
        : (status == 'rejected' ? Colors.red : Colors.orange);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildActionButton(String label, Color color, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(label),
    );
  }

  Widget _emptyState(IconData icon, String text) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 60, color: Colors.grey[300]),
          Text(text, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
