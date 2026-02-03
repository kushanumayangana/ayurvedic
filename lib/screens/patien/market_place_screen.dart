import 'package:flutter/material.dart';

// --- Colors (Same as Home Screen for consistency) ---
const Color kPrimaryGreen = Color(0xFF0E4D28);
const Color kLightGreenBg = Color(0xFFE6F0EA);
const Color kAccentGreen = Color(0xFF2E7D32);
const Color kGreyText = Color(0xFF757575);
const Color kCardBg = Colors.white;

class MarketPlaceScreen extends StatefulWidget {
  const MarketPlaceScreen({super.key});

  @override
  State<MarketPlaceScreen> createState() => _MarketPlaceScreenState();
}

class _MarketPlaceScreenState extends State<MarketPlaceScreen> {
  int _selectedIndex = 1; // "Shop" is selected by default

  final List<Map<String, String>> products = [
    {"name": "Ashwagandha", "tag": "Immunity Booster", "price": "\$12.99"},
    {"name": "Ashwagandha", "tag": "Immunity Booster", "price": "\$12.99"},
    {"name": "Ashwagandha", "tag": "Immunity Booster", "price": "\$12.99"},
    {"name": "Ashwagandha", "tag": "Immunity Booster", "price": "\$12.99"},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // 1. Header Section (Green Background + Search)
          _buildHeader(),

          // 2. Filter Chips Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15),
            child: Row(
              children: [
                _buildFilterChip("Category", isSelected: true),
                const SizedBox(width: 10),
                _buildFilterChip("Price range", isSelected: false),
                const SizedBox(width: 10),
                _buildFilterChip("Verified", isSelected: false),
              ],
            ),
          ),

          // 3. Product Grid
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: GridView.builder(
                padding: const EdgeInsets.only(bottom: 20),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, // 2 items per row
                  childAspectRatio: 0.75, // Adjust height/width ratio of cards
                  crossAxisSpacing: 15,
                  mainAxisSpacing: 15,
                ),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  return _buildProductCard(
                    products[index]["name"]!,
                    products[index]["tag"]!,
                    products[index]["price"]!,
                  );
                },
              ),
            ),
          ),
        ],
      ),

      // 4. Bottom Navigation Bar
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() => _selectedIndex = index);
          // Add navigation logic here if needed (e.g., Navigator.push...)
        },
        selectedItemColor: kPrimaryGreen,
        unselectedItemColor: Colors.black54,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.storefront), label: "Shop"),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month),
            label: "Appointment",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }

  // --- Widgets ---

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        20,
        50,
        20,
        25,
      ), // Adjust top padding for Safe Area
      decoration: const BoxDecoration(
        color: kLightGreenBg,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          // Title Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Icon(Icons.arrow_back, color: Colors.black87),
              const Text(
                "Market place",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              // Icon resembling the scan/calendar icon in the image
              Container(
                padding: const EdgeInsets.all(8),
                child: const Icon(Icons.qr_code_scanner, color: Colors.black87),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Search Bar
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.white), // Optional border
            ),
            child: const TextField(
              decoration: InputDecoration(
                hintText: "Search oils,herbs,teas",
                hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  vertical: 14,
                ), // Center text vertically
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, {required bool isSelected}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? kPrimaryGreen : Colors.grey[300],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildProductCard(String name, String tag, String price) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Placeholder
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(15),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Details
          Text(
            name,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(tag, style: TextStyle(color: Colors.grey[500], fontSize: 10)),
          const SizedBox(height: 8),
          Text(
            price,
            style: const TextStyle(
              color: kAccentGreen,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
