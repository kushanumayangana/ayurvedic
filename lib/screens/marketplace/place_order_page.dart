import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class PlaceOrderPage extends StatefulWidget {
  final String productId;
  final Map<String, dynamic> product;

  const PlaceOrderPage({
    super.key,
    required this.productId,
    required this.product,
  });

  @override
  State<PlaceOrderPage> createState() => _PlaceOrderPageState();
}

class _PlaceOrderPageState extends State<PlaceOrderPage> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();

  String _buyerName = 'Loading profile...';
  String _buyerRole = 'user';
  String _buyerImage = '';
  Map<String, dynamic> _buyerProfile = {};
  int _quantity = 1;
  bool _loadingProfile = true;
  bool _submitting = false;

  int get _stock =>
      int.tryParse(widget.product['stock']?.toString() ?? '') ?? 0;
  double get _price =>
      double.tryParse(widget.product['price']?.toString() ?? '') ?? 0;
  Color get _accent => widget.product['ownerType'] == 'seller'
      ? const Color(0xFFC59D3F)
      : const Color(0xFF24615E);

  @override
  void initState() {
    super.initState();
    _loadBuyerProfile();
  }

  @override
  void dispose() {
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadBuyerProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) setState(() => _loadingProfile = false);
      return;
    }

    var name = user.displayName?.trim().isNotEmpty == true
        ? user.displayName!.trim()
        : user.email?.split('@').first ?? 'Customer';
    var role = 'user';
    var image = '';
    var phone = '';
    var profileData = <String, dynamic>{};

    for (final collection in ['sellers', 'doctors', 'patients']) {
      try {
        final snapshot = await FirebaseFirestore.instance
            .collection(collection)
            .doc(user.uid)
            .get();
        if (!snapshot.exists) continue;
        final data = snapshot.data() ?? <String, dynamic>{};
        profileData = data;
        final candidateName =
            [
                  data['fullName'],
                  data['name'],
                  data['ownerName'],
                  data['businessName'],
                ]
                .map((value) => value?.toString().trim() ?? '')
                .firstWhere((value) => value.isNotEmpty, orElse: () => '');
        if (candidateName.isNotEmpty) name = candidateName;
        role = collection == 'patients'
            ? 'patient'
            : collection.substring(0, collection.length - 1);
        image =
            (data['profileImage'] ?? data['image'] ?? data['imageUrl'] ?? '')
                .toString();
        phone = (data['phone'] ?? '').toString();
        break;
      } catch (_) {
        continue;
      }
    }

    if (!mounted) return;
    setState(() {
      _buyerName = name;
      _buyerRole = role;
      _buyerImage = image;
      _buyerProfile = Map<String, dynamic>.from(profileData);
      _phoneController.text = phone;
      _loadingProfile = false;
    });
  }

  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate()) return;
    final buyer = FirebaseAuth.instance.currentUser;
    if (buyer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in before placing an order')),
      );
      return;
    }
    if (widget.productId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This listing cannot be ordered right now'),
        ),
      );
      return;
    }

    setState(() => _submitting = true);
    final productRef = FirebaseFirestore.instance
        .collection('products')
        .doc(widget.productId);
    final orderRef = FirebaseFirestore.instance.collection('orders').doc();

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final productSnapshot = await transaction.get(productRef);
        if (!productSnapshot.exists)
          throw StateError('This product is no longer available');

        final product = productSnapshot.data() ?? <String, dynamic>{};
        final stock = int.tryParse(product['stock']?.toString() ?? '') ?? 0;
        if (stock < _quantity)
          throw StateError('There is not enough stock for this quantity');

        final sellerId = (product['sellerId'] ?? '').toString();
        final doctorId = (product['doctorId'] ?? '').toString();
        final ownerType =
            product['ownerType'] == 'seller' || sellerId.isNotEmpty
            ? 'seller'
            : 'doctor';
        final ownerId = ownerType == 'seller' ? sellerId : doctorId;
        if (ownerId.isEmpty)
          throw StateError('The product owner is unavailable');
        if (ownerId == buyer.uid)
          throw StateError('You cannot order your own product');

        final latestPrice =
            double.tryParse(product['price']?.toString() ?? '') ?? _price;
        final orderCount = (product['orderCount'] as num?)?.toInt() ?? 0;
        transaction.update(productRef, {
          'orderCount': orderCount + 1,
          'lastOrderId': orderRef.id,
        });
        transaction.set(orderRef, {
          'buyerId': buyer.uid,
          'buyerName': _buyerName,
          'buyerRole': _buyerRole,
          'buyerEmail': buyer.email ?? '',
          'buyerPhone': _phoneController.text.trim(),
          'buyerImage': _buyerImage,
          'deliveryAddress': _addressController.text.trim(),
          'ownerId': ownerId,
          'ownerType': ownerType,
          'ownerName': product['ownerName'] ?? 'Marketplace vendor',
          'ownerImage': product['ownerImage'] ?? '',
          'sellerId': sellerId,
          'doctorId': doctorId,
          'buyerProfile': _buyerProfile,
          'productId': widget.productId,
          'productTitle': product['title'] ?? 'Product',
          'productCategory': product['category'] ?? 'General',
          'productImage': product['imageUrl'] ?? '',
          'unitPrice': latestPrice,
          'quantity': _quantity,
          'total': latestPrice * _quantity,
          'status': 'pending',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Order placed. The vendor will update its delivery status.',
          ),
        ),
      );
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not place order: $error')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.product['title']?.toString() ?? 'Product';
    final image = widget.product['imageUrl']?.toString() ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F6),
      appBar: AppBar(
        title: const Text('Place order'),
        backgroundColor: _accent,
        foregroundColor: Colors.white,
      ),
      body: _loadingProfile
          ? Center(child: CircularProgressIndicator(color: _accent))
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: image.isEmpty
                              ? Container(
                                  width: 76,
                                  height: 76,
                                  color: Colors.grey.shade100,
                                  child: const Icon(Icons.medication_outlined),
                                )
                              : Image.network(
                                  image,
                                  width: 76,
                                  height: 76,
                                  fit: BoxFit.cover,
                                ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 17,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'LKR ${_price.toStringAsFixed(2)} each',
                                style: TextStyle(
                                  color: _accent,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$_stock available',
                                style: const TextStyle(
                                  color: Colors.black54,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Quantity',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      IconButton.filledTonal(
                        onPressed: _quantity > 1
                            ? () => setState(() => _quantity--)
                            : null,
                        icon: const Icon(Icons.remove),
                      ),
                      SizedBox(
                        width: 56,
                        child: Center(
                          child: Text(
                            '$_quantity',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      IconButton.filledTonal(
                        onPressed: _quantity < _stock
                            ? () => setState(() => _quantity++)
                            : null,
                        icon: const Icon(Icons.add),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Delivery details',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    initialValue: _buyerName,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Recipient',
                      prefixIcon: Icon(Icons.person_outline),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Phone number',
                      prefixIcon: Icon(Icons.phone_outlined),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Enter a phone number for delivery'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _addressController,
                    minLines: 2,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Delivery address',
                      alignLabelWithHint: true,
                      prefixIcon: Icon(Icons.location_on_outlined),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Enter a delivery address'
                        : null,
                  ),
                  const SizedBox(height: 22),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Order total',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        Text(
                          'LKR ${(_price * _quantity).toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: _accent,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed: _submitting || _stock < 1 ? null : _placeOrder,
                      icon: _submitting
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.lock_outline),
                      label: Text(
                        _stock < 1 ? 'Out of stock' : 'Confirm order',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _accent,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
