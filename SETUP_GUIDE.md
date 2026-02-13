# Ayurvedic App - Setup & Configuration Guide

## 🚀 Feature Overview

This app now includes:
- ✅ Doctor Dashboard (Articles + Appointments)
- ✅ Patient Dashboard (Appointments & Articles)
- ✅ Cloudinary Image Upload (Modern & Reliable)
- ✅ Article Creation with Images
- ✅ Appointment Booking & Status Management
- ✅ Real-time Status Updates

---

## 📋 STEP 1: Cloudinary Setup

### 1.1 Get Your Cloudinary Credentials

1. Go to https://cloudinary.com/
2. Click "Sign Up" and create a FREE account
3. In your Dashboard, copy:
   - **Cloud Name** (e.g., `dl2rjsx9h`)
   - Create an **Upload Preset**:
     - Go to Settings → Upload
     - Create new unsigned preset (e.g., `ayurvedic_articles`)
     - Copy the preset name

### 1.2 Update `cloudinary_service.dart`

Open [lib/services/cloudinary_service.dart](lib/services/cloudinary_service.dart):

```dart
static const String cloudinaryCloudName = "YOUR_CLOUD_NAME";      // Replace with your cloud name
static const String cloudinaryUploadPreset = "YOUR_UPLOAD_PRESET"; // Replace with your preset
```

**Example:**
```dart
static const String cloudinaryCloudName = "dl2rjsx9h";
static const String cloudinaryUploadPreset = "ayurvedic_articles";
```

---

## 📱 STEP 2: Features Implementation

### Doctor Dashboard

#### Article Creation
- Navigate to "Write Article" tab
- Fill in:
  - **Title**: Article heading
  - **Content**: Article body (supports long text)
  - **Image**: Upload from gallery (auto-uploads to Cloudinary)
- Click "Publish Article" → Image uploads automatically
- View all articles in "My Articles" tab

#### Appointment Management
- View all appointments from patients
- Status options:
  - ⏳ **Pending**: Waiting for response
  - ✅ **Approved**: Appointment confirmed
  - ❌ **Rejected**: Not available

### Patient Dashboard

#### View Status
- See all booked appointments
- Status badges show:
  - Orange: Pending (waiting for doctor)
  - Green: Approved (ready to join)
  - Red: Rejected (try booking again)

#### Book Appointment
1. Go to Home → Find doctor in "Doctor Channeling"
2. Click "Book" button
3. Select date, time, and reason
4. Submit → Doctor receives request

#### Read Articles
- Browse all articles from doctors
- Click article to see full details
- View author, specialization, and date

---

## 🔧 STEP 3: Firestore Collections

Ensure these Firestore collections exist:

### `doctors`
```json
{
  "doctorId": {
    "fullName": "Dr. Name",
    "specialization": "Ayurveda",
    "createdAt": timestamp
  }
}
```

### `patients`
```json
{
  "patientId": {
    "username": "patient_name",
    "email": "patient@email.com",
    "role": "patient",
    "createdAt": timestamp
  }
}
```

### `articles`
```json
{
  "articleId": {
    "title": "Article Title",
    "content": "Article content...",
    "image": "https://cloudinary-url.jpg",
    "doctorId": "doctor_uid",
    "doctorName": "Dr. Name",
    "specialization": "Specialization",
    "createdAt": timestamp
  }
}
```

### `appointments`
```json
{
  "appointmentId": {
    "doctorId": "doctor_uid",
    "doctorName": "Dr. Name",
    "patientId": "patient_uid",
    "patientName": "Patient Name",
    "date": "2024-02-15",
    "time": "02:30 PM",
    "reason": "Appointment reason...",
    "status": "pending|approved|rejected",
    "createdAt": timestamp
  }
}
```

---

## 📤 Upload Flow

### How Image Upload Works

```
1. Doctor selects image from gallery
   ↓
2. Image sent to Cloudinary (not Firebase Storage)
   ↓
3. Cloudinary returns secure URL
   ↓
4. URL saved in Firestore articles collection
   ↓
5. Patient sees image when viewing article
```

### Why Cloudinary?
- ✅ Faster image loading
- ✅ Automatic optimization
- ✅ Less Firebase Storage quota usage
- ✅ Better performance on mobile
- ✅ FREE tier supports 25GB storage

---

## 🎯 Key Functions

### Doctor Service
```dart
// Publish article
FirebaseFirestore.instance.collection('articles').add({
  "title": titleCtrl.text.trim(),
  "content": contentCtrl.text.trim(),
  "image": imageUrl, // From Cloudinary
  "doctorId": doctorId,
  "doctorName": doctor['fullName'],
  "createdAt": Timestamp.now(),
});

// Update appointment status
doc.reference.update({"status": "approved"}); // or "rejected"
```

### Patient Service
```dart
// Book appointment
FirebaseFirestore.instance.collection("appointments").add({
  "doctorId": widget.doctorId,
  "doctorName": widget.doctorName,
  "patientId": user.uid,
  "patientName": patientName,
  "date": "2024-02-15",
  "time": "02:30 PM",
  "reason": _reasonController.text.trim(),
  "status": "pending",
  "createdAt": FieldValue.serverTimestamp(),
});
```

---

## ✅ Testing Checklist

- [ ] Set Cloudinary cloud name and upload preset
- [ ] Doctor can create and publish articles
- [ ] Articles show images from Cloudinary
- [ ] Patient can see articles in home feed
- [ ] Patient can click article to view details
- [ ] Patient can book appointment
- [ ] Doctor receives appointment requests
- [ ] Doctor can approve/reject appointments
- [ ] Patient sees status change in dashboard
- [ ] Approved shows "Join Now" button
- [ ] Rejected shows "Try Again" button

---

## 🐛 Troubleshooting

### Images Not Uploading
- ✓ Check Cloudinary cloud name and preset are correct
- ✓ Ensure upload preset is "unsigned"
- ✓ Check internet connection
- ✓ Verify pubspec.yaml has `http: ^1.1.0`

### Appointments Not Showing
- ✓ Check `patientId` and `doctorId` are correct
- ✓ Verify Firestore collection name is `appointments`
- ✓ Check Firebase permissions allow read/write

### Status Not Updating
- ✓ Try pulling down to refresh
- ✓ Check Firestore rules allow updates
- ✓ Verify you're updating correct appointment document

---

## 📊 Database Rules (Firestore Security)

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

---

## 🎨 UI/UX Improvements Made

1. **Article Creation**: Modern card design with preview
2. **Appointments**: Status badges with color coding
3. **Patient Dashboard**: Detailed appointment cards with date/time
4. **Error Handling**: User-friendly error messages
5. **Loading States**: Spinner feedback during upload
6. **Image Fallback**: Graceful handling of failed image loads

---

## 📚 Files Modified

- `lib/screens/dashboard/doctor.dart` - Enhanced article creation & appointments
- `lib/screens/dashboard/patient.dart` - Better appointment status display
- `lib/screens/doctor/article/add_article.dart` - Improved booking flow
- `lib/screens/home/home.dart` - Clickable articles
- `lib/services/cloudinary_service.dart` - NEW: Cloudinary integration
- `lib/screens/patien/article_detail.dart` - NEW: Article detail page

---

## 💡 Pro Tips

1. **Article Images**: Use 16:9 aspect ratio (recommended)
2. **Content**: Keep article content concise for better UX
3. **Appointments**: Set availability hours in doctor profile
4. **Testing**: Test on both mobile and web platforms
5. **Performance**: Clear old articles periodically to save storage

---

## 🚀 Next Steps (Optional Enhancements)

- [ ] Add video consultation link in approved appointments
- [ ] Email notifications for appointment status
- [ ] Rating system for appointments
- [ ] Doctor availability calendar
- [ ] Search by doctor specialization
- [ ] Appointment history archive
- [ ] Push notifications for new articles

---

**Questions? Debug Mode**: Check browser console (web) or Android logcat (mobile) for detailed errors.
