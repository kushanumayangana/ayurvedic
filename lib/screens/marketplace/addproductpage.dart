import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';

class AddProductPage extends StatefulWidget {
  final String doctorId;
  const AddProductPage({super.key, required this.doctorId});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _formKey = GlobalKey<FormState>();
  final Color primaryGreen = const Color(0xFF24615E);
  
  final String cloudName = "dcbyjbtbc"; 
  final String uploadPreset = "ayurveda_products"; 

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _stockController = TextEditingController();

  String _selectedCategory = 'Oils';
  
  // Updated to handle multiple images
  final List<XFile> _selectedImages = []; 
  final List<Uint8List> _displayBytes = []; 
  
  bool _isLoading = false;

  final List<String> _categories = [
    'Oils', 'Tablets', 'Magazines', 'Herbal Teas', 
    'Powders (Churna)', 'Syrups', 'Wellness'
  ];

  Future<void> _pickImages() async {
    if (_selectedImages.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Maximum 5 images allowed"))
      );
      return;
    }

    final ImagePicker picker = ImagePicker();
    // Use pickMultiImage for a better user experience
    final List<XFile> images = await picker.pickMultiImage(imageQuality: 70);
    
    if (images.isNotEmpty) {
      for (var image in images) {
        if (_selectedImages.length < 5) {
          final bytes = await image.readAsBytes();
          setState(() {
            _selectedImages.add(image);
            _displayBytes.add(bytes);
          });
        }
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
      _displayBytes.removeAt(index);
    });
  }

  // Uploads all images and returns a list of URLs
  Future<List<String>> _uploadAllImages() async {
    List<String> imageUrls = [];

    for (int i = 0; i < _selectedImages.length; i++) {
      final url = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');
      final request = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = uploadPreset
        ..fields['folder'] = 'products';

      if (kIsWeb) {
        request.files.add(http.MultipartFile.fromBytes(
          'file',
          _displayBytes[i],
          filename: _selectedImages[i].name,
        ));
      } else {
        request.files.add(await http.MultipartFile.fromPath(
          'file', 
          _selectedImages[i].path
        ));
      }

      final response = await request.send();
      if (response.statusCode == 200) {
        final responseData = await response.stream.toBytes();
        final responseString = String.fromCharCodes(responseData);
        final jsonMap = jsonDecode(responseString);
        imageUrls.add(jsonMap['secure_url']);
      }
    }
    return imageUrls;
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate() || _selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields and upload at least one image")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Upload All Images
      List<String> imageUrls = await _uploadAllImages();

      if (imageUrls.isEmpty) {
        throw Exception("Failed to upload images.");
      }

      // 2. Save Data to Firestore
      await FirebaseFirestore.instance.collection('products').add({
        'title': _titleController.text.trim(),
        'price': double.tryParse(_priceController.text) ?? 0.0,
        'description': _descController.text.trim(),
        'stock': int.tryParse(_stockController.text) ?? 0,
        'category': _selectedCategory,
        'imageUrls': imageUrls, // Now storing a List/Array
        'imageUrl': imageUrls[0], // Keep for backward compatibility with single-image views
        'doctorId': widget.doctorId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      Navigator.pop(context); 
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Product Listed Successfully! 🌿"))
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"))
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add New Product", 
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: primaryGreen,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading 
        ? Center(child: CircularProgressIndicator(color: primaryGreen))
        : SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Product Images (Max 5)", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  
                  // Horizontal Image Picker List
                  SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _displayBytes.length + 1,
                      itemBuilder: (context, index) {
                        if (index == _displayBytes.length) {
                          return GestureDetector(
                            onTap: _pickImages,
                            child: Container(
                              width: 100,
                              margin: const EdgeInsets.only(right: 10),
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: Icon(Icons.add_a_photo, color: primaryGreen),
                            ),
                          );
                        }
                        return Stack(
                          children: [
                            Container(
                              width: 100,
                              margin: const EdgeInsets.only(right: 10),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(15),
                                image: DecorationImage(
                                  image: MemoryImage(_displayBytes[index]),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Positioned(
                              top: 5, right: 15,
                              child: GestureDetector(
                                onTap: () => _removeImage(index),
                                child: const CircleAvatar(
                                  radius: 12,
                                  backgroundColor: Colors.red,
                                  child: Icon(Icons.close, size: 15, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 25),

                  const Text("Category", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: _inputDecoration("Select Category"),
                    items: _categories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
                    onChanged: (val) => setState(() => _selectedCategory = val!),
                  ),
                  const SizedBox(height: 20),

                  const Text("Product Name", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _titleController,
                    decoration: _inputDecoration("e.g. Traditional Brahmi Oil"),
                    validator: (val) => val!.isEmpty ? "Enter title" : null,
                  ),
                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Price (LKR)", style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _priceController,
                              keyboardType: TextInputType.number,
                              decoration: _inputDecoration("Amount"),
                              validator: (val) => val!.isEmpty ? "Required" : null,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Available Stock", style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _stockController,
                              keyboardType: TextInputType.number,
                              decoration: _inputDecoration("Qty"),
                              validator: (val) => val!.isEmpty ? "Required" : null,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  const Text("Description / Benefits", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _descController,
                    maxLines: 4,
                    decoration: _inputDecoration("Describe ingredients..."),
                    validator: (val) => val!.isEmpty ? "Enter description" : null,
                  ),
                  const SizedBox(height: 30),

                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _saveProduct,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryGreen,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      child: const Text("Publish to Marketplace", 
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: primaryGreen)),
    );
  }
}