# ⚡ Quick Reference Card

## 🚀 Get Started in 3 Steps

### Step 1: Cloudinary Setup (5 minutes)
```
1. Sign up: https://cloudinary.com/
2. Copy Cloud Name from Dashboard
3. Settings → Upload → Add Preset (name: ayurvedic_articles)
4. Update lib/services/cloudinary_service.dart with your values
```

### Step 2: Run the App
```bash
flutter pub get
flutter run -d chrome  # or -d android, -d ios
```

### Step 3: Test
```
Doctor: Create article with image
Patient: See article in home → Book appointment
Doctor: Approve appointment → Patient sees update
```

---

## 📍 Key File Locations

| File | Purpose | What to Change |
|------|---------|-----------------|
| `lib/services/cloudinary_service.dart` | Image upload | Cloud name & preset |
| `lib/screens/dashboard/doctor.dart` | Doctor dashboard | Add features here |
| `lib/screens/dashboard/patient.dart` | Patient dashboard | Modify UI here |
| `lib/screens/patien/article_detail.dart` | Article page | NEW file |
| `lib/screens/home/home.dart` | Home feed | Shows articles & doctors |

---

## 🔑 Important Constants

```dart
// Cloudinary
Cloud Name: (from your dashboard)
Upload Preset: ayurvedic_articles  // Must be unsigned!

// Colors
Primary Green: #24615E
Secondary Green: #1B4332
Light BG: #F9FBFB

// Firebase Collections
doctors
patients
articles
appointments
```

---

## 📝 API Reference

### Upload Image to Cloudinary
```dart
String? imageUrl = await CloudinaryService.uploadImageFromFile(file);
// Returns: "https://res.cloudinary.com/..." or null
```

### Save Article
```dart
await FirebaseFirestore.instance.collection('articles').add({
  "title": title,
  "content": content,
  "image": imageUrl,  // From Cloudinary
  "doctorId": doctorId,
  "doctorName": doctorName,
  "specialization": specialization,
  "createdAt": Timestamp.now(),
});
```

### Book Appointment
```dart
await FirebaseFirestore.instance.collection("appointments").add({
  "doctorId": doctorId,
  "doctorName": doctorName,
  "patientId": patientId,
  "patientName": patientName,
  "date": "2024-02-15",  // YYYY-MM-DD
  "time": "02:30 PM",
  "reason": reason,
  "status": "pending",
  "createdAt": FieldValue.serverTimestamp(),
});
```

### Update Appointment Status
```dart
await appointmentDoc.update({"status": "approved"});  // or "rejected"
```

---

## 🎨 UI Components

### Status Badge Colors
```
Pending  → Orange  (⏳)
Approved → Green   (✅)
Rejected → Red     (❌)
```

### Article Card
- 16:9 image with rounded corners
- Title (bold)
- Content preview (2-3 lines)
- Doctor name + specialization
- Publication date

### Appointment Card
- Doctor avatar + status icon
- Doctor name + status badge
- Date, Time, Reason
- Status message + action button

---

## 🔍 Debug Checklist

- [ ] Cloudinary values set correctly in code
- [ ] No spelling errors in cloud name or preset
- [ ] Upload preset is "Unsigned" in Cloudinary dashboard
- [ ] `http` package is in pubspec.yaml
- [ ] Firestore collections exist with correct names
- [ ] Firebase rules allow read/write
- [ ] Images show Cloudinary URLs (not Firebase Storage)
- [ ] Real-time updates work (pull to refresh)

---

## 🆘 Quick Fixes

**Images not uploading?**
```dart
// Add to CloudinaryService for debug
print('Uploading to: $uploadUrl');
print('Cloud Name: $cloudinaryCloudName');
print('Preset: $cloudinaryUploadPreset');
```

**Appointments not showing?**
```dart
// Add to appointmentsTab for debug
print('Doctor ID: $doctorId');
print('Found ${docs.length} appointments');
```

**Status not updating?**
```dart
// Try manual refresh
setState(() {});
// Or pull down on mobile to trigger StreamBuilder
```

---

## 📊 Data Models

### Doctor
```dart
{
  'fullName': 'Dr. Name',
  'specialization': 'Ayurveda',
  'createdAt': Timestamp
}
```

### Patient
```dart
{
  'username': 'patient_name',
  'email': 'patient@email.com',
  'role': 'patient',
  'createdAt': Timestamp
}
```

### Article
```dart
{
  'title': 'Article Title',
  'content': 'Article content...',
  'image': 'https://res.cloudinary.com/...',  // IMPORTANT: Cloudinary URL!
  'doctorId': 'doctor_uid',
  'doctorName': 'Dr. Name',
  'specialization': 'Specialization',
  'createdAt': Timestamp
}
```

### Appointment
```dart
{
  'doctorId': 'doctor_uid',
  'doctorName': 'Dr. Name',
  'patientId': 'patient_uid',
  'patientName': 'Patient Name',
  'date': '2024-02-15',  // YYYY-MM-DD format!
  'time': '02:30 PM',
  'reason': 'Appointment reason',
  'status': 'pending|approved|rejected',
  'createdAt': Timestamp
}
```

---

## 🔐 Security Rules Template

```javascript
// Allow doctors to manage articles
match /articles/{articleId} {
  allow read: if true;
  allow write: if request.auth.uid == resource.data.doctorId;
}

// Allow users to create appointments
match /appointments/{appointmentId} {
  allow create: if request.auth != null;
  allow read: if request.auth.uid == resource.data.doctorId 
                 || request.auth.uid == resource.data.patientId;
  allow update: if request.auth.uid == resource.data.doctorId;
}
```

---

## 🚀 Deployment Checklist

- [ ] Set Cloudinary cloud name
- [ ] Set Cloudinary upload preset
- [ ] Update Firebase config if changing projects
- [ ] Set proper Firestore security rules
- [ ] Test on both iOS and Android
- [ ] Test on web browser
- [ ] Verify Cloudinary storage quota
- [ ] Add error logging for production
- [ ] Test image upload with different formats (JPG, PNG)
- [ ] Test with slow network (throttle in DevTools)

---

## 📞 Need Help?

1. **Check SETUP_GUIDE.md** for detailed instructions
2. **Check CONFIGURATION_GUIDE.md** for troubleshooting
3. **Check console logs** in browser DevTools (web) or logcat (mobile)
4. **Check Firestore** for document structure
5. **Check Cloudinary** Media Library for uploaded images

---

## ✨ What You Get

✅ Doctor can create articles with images  
✅ Articles display beautifully in home feed  
✅ Patients can read full articles  
✅ Patients can book appointments  
✅ Doctors can approve/reject appointments  
✅ Real-time status updates  
✅ Modern UI with proper error handling  
✅ Fast image loading via Cloudinary  
✅ Responsive design for all devices  

---

**Ready? Update cloudinary_service.dart and run the app! 🚀**
