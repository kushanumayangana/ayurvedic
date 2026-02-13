import 'package:cloud_firestore/cloud_firestore.dart';
import '../screens/doctor/doctor_model.dart';

class DoctorService {
  static final _db = FirebaseFirestore.instance;

  static Future<void> submitDoctor(DoctorModel doctor) async {
    await _db.collection('doctors').doc(doctor.uid).set(doctor.toMap());
  }

  static Future<String> getDoctorStatus(String uid) async {
    final doc = await _db.collection('doctors').doc(uid).get();
    return doc.exists ? doc['status'] : 'not_found';
  }

  static Future<void> approveDoctor(String uid) async {
    await _db.collection('doctors').doc(uid).update({
      'status': 'approved',
    });
  }
}
