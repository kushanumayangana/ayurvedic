import 'package:flutter/material.dart';

// --- Colors ---
const Color kPrimaryGreen = Color(0xFF0E4D28); // Dark Green for Buttons
const Color kPriceRed = Color(0xFFFF5252); // Red/Orange for Price
const Color kLimeGreen = Color(0xFFDCE775); // Light Green for Quantity Selector
const Color kGreyText = Color(0xFF757575);
const Color kBgColor = Color(0xFFF9FAFB); // Very light grey background

class ProductDetailsScreen extends StatefulWidget {
  const ProductDetailsScreen({super.key});

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  int _quantity = 1;

  void _incrementQty() => setState(() => _quantity++);
  void _decrementQty() {
    if (_quantity > 1) setState(() => _quantity--);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Product details",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),

                  // 1. Product Image
                  Center(
                    child: Container(
                      height: 250,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        // Placeholder for the Neem Face Wash Image
                        image: const DecorationImage(
                          image: AssetImage(
                            'assets/product_placeholder.png',
                          ), // Replace with your asset
                          fit: BoxFit.contain,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            blurRadius: 15,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      // Fallback content if no image asset exists yet
                      child: const Center(
                        child: Icon(Icons.image, size: 80, color: Colors.grey),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // 2. Product Title
                  const Text(
                    "Neem Face Wash",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),

                  const SizedBox(height: 10),

                  // 3. Price
                  const Text(
                    "\$4.5",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: kPriceRed,
                    ),
                  ),

                  const SizedBox(height: 30),

                  // 4. Product Details Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: const [
                            Text(
                              "Product details",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Icon(Icons.keyboard_arrow_up, color: Colors.black),
                          ],
                        ),
                        const SizedBox(height: 15),
                        const Text(
                          "A clinically tested, soap-free formulation made with the unique combination of neem and turmeric. This pimple expert gently removes impurities, and helps clear pimples.",
                          style: TextStyle(
                            color: kGreyText,
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30), // Bottom spacer
                ],
              ),
            ),
          ),

          // 5. Bottom Action Bar (Sticky)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            decoration: const BoxDecoration(color: Colors.transparent),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Quantity Selector
                Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: kLimeGreen,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: _decrementQty,
                        icon: const Icon(
                          Icons.remove,
                          color: Colors.black87,
                          size: 18,
                        ),
                      ),
                      Text(
                        "$_quantity",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      IconButton(
                        onPressed: _incrementQty,
                        icon: const Icon(
                          Icons.add,
                          color: Colors.black87,
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 20),

                // Order Button
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        // Handle Order Logic
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimaryGreen,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        "Order by", // "Order by" matches the specific UI mock provided
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
