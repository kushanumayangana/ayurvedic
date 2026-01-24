import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:firebase_storage/firebase_storage.dart';

class FirebaseStorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Upload file (File for mobile, Uint8List for web)
  Future<String> uploadFile({
    required dynamic file,
    required String path, // e.g., "doctors/nicFront.jpg"
  }) async {
    Reference ref = _storage.ref().child(path);

    UploadTask uploadTask;

    if (kIsWeb) {
      // Web
      uploadTask = ref.putData(file);
    } else {
      // Mobile
      uploadTask = ref.putFile(file);
    }

    TaskSnapshot snapshot = await uploadTask;
    String downloadUrl = await snapshot.ref.getDownloadURL();
    return downloadUrl;
  }
}
