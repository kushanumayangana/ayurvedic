class DoctorModel {
  String uid;
  String fullName;
  String nic;
  String email;

  String regNo;
  String specialization;
  String clinicAddress;

  // Uploaded documents
  String licenseUrl;
  String nicFrontUrl;
  String nicBackUrl;

  // Verification flags
  bool emailVerified;
  bool makesMedicine;

  /// pending | approved | rejected
  String status;

  /// optional admin note (useful if rejected)
  String? adminNote;

  DateTime createdAt;
  DateTime? approvedAt;

  DoctorModel({
    required this.uid,
    required this.fullName,
    required this.nic,
    required this.email,
    required this.regNo,
    required this.specialization,
    required this.clinicAddress,
    required this.licenseUrl,
    required this.nicFrontUrl,
    required this.nicBackUrl,
    required this.emailVerified,
    required this.makesMedicine,
    required this.status,
    this.adminNote,
    DateTime? createdAt,
    this.approvedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Convert to Firestore map
  Map<String, dynamic> toMap() {
    return {
      "uid": uid,
      "fullName": fullName,
      "nic": nic,
      "email": email,
      "regNo": regNo,
      "specialization": specialization,
      "clinicAddress": clinicAddress,

      "licenseUrl": licenseUrl,
      "nicFrontUrl": nicFrontUrl,
      "nicBackUrl": nicBackUrl,

      "emailVerified": emailVerified,
      "makesMedicine": makesMedicine,

      "status": status, // pending / approved / rejected
      "adminNote": adminNote,

      "role": "doctor",
      "createdAt": createdAt,
      "approvedAt": approvedAt,
    };
  }

  /// Create model from Firestore
  factory DoctorModel.fromMap(Map<String, dynamic> map) {
    return DoctorModel(
      uid: map["uid"],
      fullName: map["fullName"],
      nic: map["nic"],
      email: map["email"],
      regNo: map["regNo"],
      specialization: map["specialization"],
      clinicAddress: map["clinicAddress"],
      licenseUrl: map["licenseUrl"],
      nicFrontUrl: map["nicFrontUrl"],
      nicBackUrl: map["nicBackUrl"],
      emailVerified: map["emailVerified"] ?? false,
      makesMedicine: map["makesMedicine"] ?? false,
      status: map["status"] ?? "pending",
      adminNote: map["adminNote"],
      createdAt: map["createdAt"]?.toDate(),
      approvedAt: map["approvedAt"]?.toDate(),
    );
  }
}
