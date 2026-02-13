# ⚙️ Configuration & Troubleshooting Guide

## 🔧 Cloudinary Setup (Step-by-Step)

### 1. Create Free Cloudinary Account
```
URL: https://cloudinary.com/users/register/free
```

### 2. Get Your Cloud Name
1. After login, go to Dashboard
2. Copy "Cloud Name" from the top
3. Example: `dl2rjsx9h`

### 3. Create Upload Preset
1. Go to **Settings** (gear icon)
2. Go to **Upload** tab
3. Scroll to "Upload presets" section
4. Click **"Add upload preset"**
5. Settings:
   - **Name**: `ayurvedic_articles` (or your choice)
   - **Unsigned**: YES (Important! For client-side upload)
   - **Folder**: `ayurvedic/articles` (optional)
   - Click **Save**
6. Copy the preset name exactly

### 4. Update Your Code
File: `lib/services/cloudinary_service.dart`

```dart
class CloudinaryService {
  static const String cloudinaryCloudName = "dl2rjsx9h";  // ← Your cloud name
  static const String cloudinaryUploadPreset = "ayurvedic_articles";  // ← Your preset
  // Rest of the code...
}
```

**Example with different values:**
```dart
static const String cloudinaryCloudName = "mycloud123";
static const String cloudinaryUploadPreset = "my_upload_preset";
```

---

## 🔐 Firebase Security Rules

### Firestore Rules (Secure but Functional)
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Allow doctors to read/write their own data
    match /doctors/{docId} {
      allow read: if true;
      allow write: if request.auth.uid == docId;
    }
    
    // Allow patients to read/write their own data
    match /patients/{patientId} {
      allow read: if request.auth.uid == patientId;
      allow write: if request.auth.uid == patientId;
    }
    
    // Anyone can read articles
    match /articles/{articleId} {
      allow read: if true;
      allow write: if request.auth.uid == resource.data.doctorId;
    }
    
    // Users can read/write their own appointments
    match /appointments/{appointmentId} {
      allow read: if request.auth.uid == resource.data.doctorId 
                     || request.auth.uid == resource.data.patientId;
      allow create: if request.auth != null;
      allow update: if request.auth.uid == resource.data.doctorId;
    }
  }
}
```

---

## 📦 Dependencies Required

Ensure your `pubspec.yaml` has:

```yaml
dependencies:
  flutter:
    sdk: flutter
  cloud_firestore: ^6.1.1
  firebase_auth: ^6.1.3
  firebase_core: ^4.3.0
  image_picker: ^0.8.7+5
  http: ^1.1.0  # Important for Cloudinary!
  url_launcher: ^6.1.10
```

Run: `flutter pub get`

---

## 🔍 Debugging Guide

### Check Cloudinary Upload Success

**In CloudinaryService.dart**, uncomment for debugging:
```dart
print('Cloudinary upload response: $responseBody');
print('Image URL: $imageUrl');
```

### Check Firestore Data

1. Go to Firebase Console
2. Select your project
3. Go to **Firestore Database**
4. Check these collections exist:
   - `doctors`
   - `patients`
   - `articles`
   - `appointments`

### View Uploaded Images

1. Go to Cloudinary Dashboard
2. Click **Media Library**
3. Should see uploaded images in `ayurvedic/articles` folder

---

## 🚨 Common Issues & Solutions

### Issue: "Image upload failed. Check Cloudinary config"

**Solution:**
```
✓ Check Cloud Name is correct (no spaces, exact case)
✓ Check Upload Preset name matches exactly
✓ Ensure Upload Preset is set to "Unsigned" = YES
✓ Check internet connection
✓ Try with a smaller image (<5MB)
```

**Test with cURL:**
```bash
curl -X POST \
  -F "file=@/path/to/image.jpg" \
  -F "upload_preset=YOUR_PRESET" \
  "https://api.cloudinary.com/v1_1/YOUR_CLOUD_NAME/image/upload"
```

---

### Issue: "Appointments not appearing"

**Check:**
1. Firestore has `appointments` collection
2. `doctorId` matches exactly (case-sensitive)
3. `patientId` matches current user's UID
4. Refresh the page (pull down)

**Debug Code:**
```dart
// Add to appointments tab to verify data
print('Doctor ID: $doctorId');
print('Appointments: ${snapshot.data!.docs.length}');
```

---

### Issue: "Status not updating in real-time"

**Solution:**
- Pull down to refresh (iOS) or swipe down (Android)
- StreamBuilder should auto-update via Firestore listeners
- Check Firestore rules allow updates

**Verify Update:**
```dart
onPressed: () async {
  await doc.reference.update({"status": "approved"});
  print('Appointment updated to approved');
}
```

---

### Issue: "Patient name shows as null"

**Fix in add_article.dart:**
```dart
// Make sure to fetch from Firestore
final patientDoc = await FirebaseFirestore.instance
    .collection('patients')
    .doc(user.uid)
    .get();

final patientName = patientDoc.data()?['username'] ?? "Patient";
```

---

## 🧪 Testing Scenarios

### Scenario 1: Create Article with Image
```
1. Login as Doctor
2. Go to Doctor Dashboard → Write Article
3. Enter:
   - Title: "Benefits of Herbal Medicine"
   - Content: "Detailed information about..."
   - Image: Select from gallery
4. Click "Publish Article"
5. Expected: Green success message + article appears in "My Articles"
6. Verify: Image loaded from Cloudinary (not Firebase Storage)
```

### Scenario 2: Patient Books Appointment
```
1. Login as Patient
2. Go to Home → Find Doctor → Click "Book"
3. Enter:
   - Date: Tomorrow
   - Time: 02:30 PM
   - Reason: "Consultation"
4. Click "Request Appointment"
5. Expected: Green success message + navigate back
6. Doctor should see appointment in pending list
```

### Scenario 3: Doctor Approves Appointment
```
1. Login as Doctor
2. Go to Doctor Dashboard → Appointments
3. Find pending appointment
4. Click popup menu → "✅ Approve"
5. Expected: Status changes to "Approved" immediately
6. Patient Dashboard should show "Approved" with green badge
```

---

## 📊 Database Validation

### Verify Doctor Document
```javascript
// In Firestore Console, check:
doctors/[doctorId] {
  fullName: "Dr. Name" ✓
  specialization: "Ayurveda" ✓
  createdAt: timestamp ✓
}
```

### Verify Article Document
```javascript
articles/[articleId] {
  title: "Article Title" ✓
  content: "Article content..." ✓
  image: "https://res.cloudinary.com/..." ✓  // Must be Cloudinary URL!
  doctorId: "doctor_uid" ✓
  doctorName: "Dr. Name" ✓
  specialization: "Specialization" ✓
  createdAt: timestamp ✓
}
```

### Verify Appointment Document
```javascript
appointments/[appointmentId] {
  doctorId: "doctor_uid" ✓
  doctorName: "Dr. Name" ✓
  patientId: "patient_uid" ✓
  patientName: "Patient Name" ✓
  date: "2024-02-15" ✓  // YYYY-MM-DD format!
  time: "02:30 PM" ✓
  reason: "Reason for appointment" ✓
  status: "pending" | "approved" | "rejected" ✓
  createdAt: timestamp ✓
}
```

---

## 📱 Platform-Specific Notes

### Android
- Image picker requires `READ_EXTERNAL_STORAGE` permission
- Check `android/app/build.gradle` for minSdkVersion >= 21
- Test on both physical device and emulator

### iOS
- Image picker requires photo library access
- Check `ios/Runner/Info.plist` for `NSPhotoLibraryUsageDescription`
- Test on both physical device and simulator

### Web
- Image upload uses `readAsBytes()` which works on web
- Test in Chrome/Firefox (not all browsers support all features)
- Use `kIsWeb` to differentiate web vs mobile code

---

## 🔄 Data Flow Diagram

```
Doctor Create Article
  ↓
Image → Cloudinary API
  ↓
Get Secure URL back
  ↓
Save to Firestore (with Cloudinary URL)
  ↓
↓
Patient Home Page
  ↓
Firestore → articles collection
  ↓
Display with Image from Cloudinary
  ↓
Click Article → ArticleDetailPage
  ↓
  ↓
Patient Book Appointment
  ↓
POST to Firestore → appointments
  ↓
↓
Doctor Dashboard
  ↓
StreamBuilder → appointments collection
  ↓
Display pending appointments
  ↓
Click Approve/Reject
  ↓
Update status in Firestore
  ↓
↓
Patient Dashboard
  ↓
StreamBuilder → appointments (patientId filter)
  ↓
Display with updated status
  ↓
Show "Join Now" if approved
  ↓
```

---

## 🎯 Performance Tips

1. **Image Optimization**
   - Cloudinary auto-optimizes: ✓
   - Use 16:9 aspect ratio recommended
   - Max file size: 5MB (before compression)

2. **Firestore Queries**
   - Use `.orderBy()` for pagination
   - Filter with `.where()` efficiently
   - Limit results: `.limit(10)`

3. **App Performance**
   - Use `const` where possible
   - Cache doctor data if needed
   - Clear old images from Cloudinary periodically

---

## 📞 Support Resources

- **Cloudinary Docs**: https://cloudinary.com/documentation
- **Firebase Docs**: https://firebase.google.com/docs
- **Flutter Docs**: https://flutter.dev/docs
- **Image Picker**: https://pub.dev/packages/image_picker

---

✅ **Configuration Complete! Your app is ready to use.**
