import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Screens
import '../doctor/appointment/book_appointment.dart';
import '../doctor/doctor_profile.dart';
import '../doctor/articles/article_detail.dart';
import '../marketplace/product_detail_page.dart';
import '../seller/seller_profile.dart';
import '../../services/app_navigation_state.dart';

// Dashboard imports with prefixes
import '../dashboard/doctor.dart' as doctor;
import '../dashboard/patient.dart' as patient;
import '../dashboard/admin.dart' as admin;
import '../dashboard/seller.dart' as seller;

class HomePage extends StatefulWidget {
  final String role;
  final int initialSection;

  const HomePage({super.key, required this.role, this.initialSection = 0});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool get isSeller => widget.role.toLowerCase() == 'seller';
  Color get primaryGreen =>
      isSeller ? const Color(0xFFC59D3F) : const Color(0xFF24615E);
  Color get secondaryGreen =>
      isSeller ? const Color(0xFF6F5520) : const Color(0xFF1B4332);
  Color get lightBg =>
      isSeller ? const Color(0xFFFFF8E7) : const Color(0xFFF9FBFB);

  final ScrollController _homeScrollController = ScrollController();
  final GlobalKey _bookingSectionKey = GlobalKey();
  final GlobalKey _shopSectionKey = GlobalKey();
  final user = FirebaseAuth.instance.currentUser;
  String sellerName = 'Seller';

  late final Stream<QuerySnapshot<Map<String, dynamic>>> _doctorsStream;
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _productsStream;
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _articlesStream;
  final Map<String, Future<String>> _ownerImageFutures = {};

  String doctorSearch = "";
  String productSearch = "";
  String articleSearch = "";

  Future<String> _ownerProfileImage({
    required String ownerId,
    required bool isSeller,
    required String fallbackImage,
  }) {
    if (ownerId.isEmpty) return Future.value(fallbackImage);

    final collection = isSeller ? 'sellers' : 'doctors';
    return _ownerImageFutures.putIfAbsent('$collection:$ownerId', () async {
      try {
        final snapshot = await FirebaseFirestore.instance
            .collection(collection)
            .doc(ownerId)
            .get();
        final profile = snapshot.data() ?? <String, dynamic>{};
        return [
              profile['profileImage'],
              profile['image'],
              profile['imageUrl'],
              profile['profilePic'],
              profile['photoUrl'],
              fallbackImage,
            ]
            .map((value) => value?.toString().trim() ?? '')
            .firstWhere((value) => value.isNotEmpty, orElse: () => '');
      } catch (_) {
        return fallbackImage;
      }
    });
  }

  @override
  void initState() {
    super.initState();
    appNavigationEnabled.value = true;
    _doctorsStream = FirebaseFirestore.instance
        .collection('doctors')
        .snapshots();
    _productsStream = FirebaseFirestore.instance
        .collection('products')
        .snapshots();
    _articlesStream = FirebaseFirestore.instance
        .collection('articles')
        .orderBy('createdAt', descending: true)
        .snapshots();
    if (isSeller) _loadSellerName();
    if (widget.initialSection > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToSection(widget.initialSection);
      });
    }
  }

  @override
  void dispose() {
    _homeScrollController.dispose();
    super.dispose();
  }

  void _scrollToSection(int section) {
    final targetContext = switch (section) {
      1 => _shopSectionKey.currentContext,
      2 => _bookingSectionKey.currentContext,
      _ => null,
    };
    if (targetContext == null) return;
    Scrollable.ensureVisible(
      targetContext,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeInOutCubic,
      alignment: 0.04,
    );
  }

  Future<void> _loadSellerName() async {
    final uid = user?.uid;
    if (uid == null) return;

    final sellerDoc = await FirebaseFirestore.instance
        .collection('sellers')
        .doc(uid)
        .get();
    final data = sellerDoc.data() ?? <String, dynamic>{};
    final profileName =
        [data['fullName'], data['ownerName'], data['businessName']]
            .map((value) => value?.toString().trim() ?? '')
            .firstWhere((value) => value.isNotEmpty, orElse: () => 'Seller');

    if (!mounted) return;
    setState(() => sellerName = profileName);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightBg,
      body: RefreshIndicator(
        onRefresh: () async => setState(() {}),
        child: SingleChildScrollView(
          controller: _homeScrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              _buildHeader(),
              const SizedBox(height: 25),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- DOCTOR SECTION ---
                    KeyedSubtree(
                      key: _bookingSectionKey,
                      child: _sectionTitle("Doctor Channeling"),
                    ),
                    const SizedBox(height: 15),
                    _searchBox(
                      "Search doctors...",
                      (value) => setState(() => doctorSearch = value),
                    ),
                    const SizedBox(height: 15),
                    SizedBox(height: 180, child: _doctorList()),

                    const SizedBox(height: 35),

                    // --- MARKETPLACE SECTION (NEW) ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        KeyedSubtree(
                          key: _shopSectionKey,
                          child: _sectionTitle("Market Place"),
                        ),
                        Text(
                          "View All",
                          style: TextStyle(color: primaryGreen, fontSize: 12),
                        ),
                      ],
                    ),
                    const Text(
                      "Popular Medicines",
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                    const SizedBox(height: 15),
                    _searchBox(
                      "Search products...",
                      (value) => setState(() => productSearch = value),
                    ),
                    const SizedBox(height: 15),
                    SizedBox(height: 220, child: _marketPlaceList()),

                    const SizedBox(height: 35),

                    // --- LEARN HUB SECTION ---
                    _sectionTitle("Learn Hub"),
                    const SizedBox(height: 15),
                    _searchBox(
                      "Search articles...",
                      (value) => setState(() => articleSearch = value),
                    ),
                    const SizedBox(height: 15),
                    _articleList(),
                    const SizedBox(height: 50),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================= DYNAMIC HEADER =================
  Widget _buildHeader() {
    // Determine the name to display based on the role
    String displayName;
    if (widget.role.toLowerCase() == 'doctor') {
      displayName = "Doctor";
    } else if (widget.role.toLowerCase() == 'admin') {
      displayName = "Admin";
    } else if (isSeller) {
      displayName = sellerName;
    } else {
      // Use the user's name from Firebase if it exists, otherwise 'User'
      displayName = user?.displayName ?? 'User';
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(25, 60, 25, 40),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isSeller
              ? const [Color(0xFFF5E7BF), Color(0xFFE8D39C)]
              : const [Color(0xFFE8F1E9), Color(0xFFD2E7D6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "AyurvedaCare",
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                // UPDATED: Dynamic Greeting based on Role
                Text(
                  "Hello, $displayName",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: secondaryGreen,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  "How are you feeling today?",
                  style: TextStyle(
                    color: isSeller
                        ? const Color(0xFF8A6B2B)
                        : const Color(0xFF6A9175),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _openDashboard,
            icon: Icon(Icons.dashboard, color: primaryGreen),
          ),
        ],
      ),
    );
  }

  // ================= MARKETPLACE LIST =================
  Widget _marketPlaceList() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _productsStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final query = productSearch.trim().toLowerCase();
        final products = snapshot.data!.docs.where((doc) {
          if (query.isEmpty) return true;
          final data = doc.data();
          return [data['title'], data['category'], data['description']].any(
            (value) => value?.toString().toLowerCase().contains(query) ?? false,
          );
        }).toList();

        if (products.isEmpty) {
          return Center(
            child: Text(
              query.isEmpty ? "No products available" : "No matching products",
            ),
          );
        }

        return ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: products.length,
          itemBuilder: (context, index) {
            final data = products[index].data();
            final sellerId = data['sellerId']?.toString() ?? '';
            final isSeller =
                sellerId.isNotEmpty || data['ownerType'] == 'seller';
            final ownerId = isSeller
                ? sellerId
                : data['doctorId']?.toString() ?? '';
            return _productCard(
              data['title'] ?? "Product",
              data['category'] ?? "General",
              data['price']?.toString() ?? "0",
              data['imageUrl'] ??
                  (data['imageUrls'] != null ? data['imageUrls'][0] : ""),
              orderCount: data['orderCount']?.toString() ?? '0',
              ownerId: ownerId,
              isSeller: isSeller,
              ownerImage: data['ownerImage']?.toString() ?? '',
              onOwnerTap: ownerId.isEmpty
                  ? null
                  : () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => isSeller
                            ? SellerProfilePage(sellerId: ownerId)
                            : DoctorProfilePage(doctorId: ownerId),
                      ),
                    ),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProductDetailPage(
                    product: data,
                    productId: products[index].id,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _productCard(
    String title,
    String category,
    String price,
    String image, {
    String orderCount = '0',
    String ownerId = '',
    bool isSeller = false,
    String ownerImage = '',
    VoidCallback? onOwnerTap,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 15),
        decoration: _cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                      image: image.isNotEmpty
                          ? DecorationImage(
                              image: NetworkImage(image),
                              fit: BoxFit.cover,
                            )
                          : null,
                      color: Colors.grey.shade100,
                    ),
                    child: image.isEmpty
                        ? const Center(child: Icon(Icons.medication))
                        : null,
                  ),
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: primaryGreen.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        category.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  if (onOwnerTap != null)
                    Positioned(
                      top: 7,
                      right: 7,
                      child: Material(
                        color: Colors.white,
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: onOwnerTap,
                          child: FutureBuilder<String>(
                            future: _ownerProfileImage(
                              ownerId: ownerId,
                              isSeller: isSeller,
                              fallbackImage: ownerImage,
                            ),
                            builder: (context, snapshot) {
                              final image = snapshot.data ?? ownerImage;
                              return CircleAvatar(
                                radius: 19,
                                backgroundColor: Colors.white,
                                backgroundImage: image.isNotEmpty
                                    ? NetworkImage(image)
                                    : null,
                                child: image.isEmpty
                                    ? const Icon(
                                        Icons.person_outline,
                                        color: Color(0xFF24615E),
                                        size: 20,
                                      )
                                    : null,
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: _titleStyle().copyWith(fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(category, style: _subStyle()),
                  const SizedBox(height: 5),
                  Text(
                    "LKR $price",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: primaryGreen,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.shopping_bag_outlined,
                        size: 13,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$orderCount orders',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _doctorList() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _doctorsStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());

        final filteredDocs = snapshot.data!.docs.where((doc) {
          final data = doc.data();
          return data['fullName'].toString().toLowerCase().contains(
            doctorSearch.toLowerCase(),
          );
        }).toList();

        if (filteredDocs.isEmpty)
          return const Center(child: Text("No doctors found"));

        return ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: filteredDocs.length,
          itemBuilder: (context, index) {
            final data = filteredDocs[index].data();
            return _doctorCard(
              filteredDocs[index].id,
              data['fullName'] ?? "Doctor",
              data['specialization'] ?? "Specialist",
              data['profileImage'],
            );
          },
        );
      },
    );
  }

  Widget _doctorCard(String id, String name, String spec, String? image) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => DoctorProfilePage(doctorId: id)),
      ),
      child: Container(
        width: 290,
        margin: const EdgeInsets.only(right: 15),
        padding: const EdgeInsets.all(15),
        decoration: _cardDecoration(),
        child: Row(
          children: [
            CircleAvatar(
              radius: 35,
              backgroundImage: (image != null && image.isNotEmpty)
                  ? NetworkImage(image)
                  : null,
              backgroundColor: Colors.grey.shade200,
              child: (image == null || image.isEmpty)
                  ? const Icon(Icons.person)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: _titleStyle()),
                  Text(spec, style: _subStyle()),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _tag("Available"),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BookAppointmentPage(
                              doctorId: id,
                              doctorName: name,
                            ),
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryGreen,
                        ),
                        child: const Text(
                          "Book",
                          style: TextStyle(fontSize: 11, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _articleList() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _articlesStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());

        final filtered = snapshot.data!.docs.where((doc) {
          final data = doc.data();
          return data['title'].toString().toLowerCase().contains(
            articleSearch.toLowerCase(),
          );
        }).toList();

        if (filtered.isEmpty)
          return const Center(child: Text("No articles found"));

        return ListView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final docId = filtered[index].id;
            final data = filtered[index].data();
            final String? doctorPic = data['doctorImage'];

            return Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        ArticleDetailPage(articleId: docId, data: data),
                  ),
                ),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: _cardDecoration(),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 8,
                    ),
                    leading: CircleAvatar(
                      radius: 25,
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage:
                          (doctorPic != null && doctorPic.isNotEmpty)
                          ? NetworkImage(doctorPic)
                          : null,
                      child: (doctorPic == null || doctorPic.isEmpty)
                          ? const Icon(Icons.person, color: Colors.grey)
                          : null,
                    ),
                    title: Text(
                      data['title'] ?? "Article",
                      style: _titleStyle().copyWith(fontSize: 18),
                    ),
                    subtitle: Text(
                      "By ${data['author'] ?? 'Unknown'}",
                      style: _subStyle(),
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ================= HELPERS & BOTTOM NAV =================
  Widget _sectionTitle(String title) => Text(
    title,
    style: TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.bold,
      color: primaryGreen,
    ),
  );

  Widget _searchBox(String hint, Function(String) onChanged) {
    return TextField(
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _tag(String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: isSeller ? const Color(0xFFFFF1CC) : Colors.green.shade50,
      borderRadius: BorderRadius.circular(5),
    ),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 10,
        color: isSeller ? const Color(0xFF8A6B2B) : Colors.green,
      ),
    ),
  );

  BoxDecoration _cardDecoration() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(20),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.03),
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
    ],
  );

  TextStyle _titleStyle() => TextStyle(
    fontWeight: FontWeight.bold,
    color: secondaryGreen,
    fontSize: 16,
  );
  TextStyle _subStyle() => const TextStyle(fontSize: 12, color: Colors.grey);

  void _openDashboard() {
    final roleName = widget.role.toLowerCase();
    Widget page;
    switch (roleName) {
      case 'doctor':
        page = doctor.DoctorDashboardPage(doctorId: user?.uid ?? '');
        break;
      case 'admin':
        page = admin.AdminDashboard();
        break;
      case 'seller':
        page = seller.SellerDashboard();
        break;
      default:
        page = patient.PatientDashboardPage();
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }
}
