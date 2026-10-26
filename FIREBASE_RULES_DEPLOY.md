# Deploying Firestore rules and granting admin claim

1) Ensure you have the Firebase CLI installed and you're logged in:

```powershell
npm install -g firebase-tools
firebase login
```

2) From the project root (where `firestore.rules` was added), deploy only the rules:

```powershell
firebase deploy --only firestore:rules
```

3) If you have multiple Firebase projects, first select the correct project:

```powershell
firebase use --add
# then re-run the deploy command
```

4) Granting an `admin` custom claim (run from a secure environment using Admin SDK):

Node.js example (run on server or cloud function environment):

```js
const admin = require('firebase-admin');
admin.initializeApp({ credential: admin.credential.applicationDefault() });
await admin.auth().setCustomUserClaims('ADMIN_USER_UID', { admin: true });
console.log('Admin claim set');
```

Note: After setting custom claims, the client must refresh its ID token (sign out/in or call `getIdToken(true)`).

5) Test the rule change using the Firestore Rules Simulator in the Firebase Console before deploying to production.

Feedback documents are readable by their owner using the document ID, including
before a feedback document has been created. Admins can read the feedback
collection for the inbox.

Patient access requirements:

- Patient registration sends a Firebase Auth email-verification link, and patient
  sign-in is blocked until that address is verified.
- The rules require a verified email for appointment and marketplace order
  creation, and only the patient can create or update their own profile.
- Email verification confirms control of an email address; it does not verify a
  person's legal identity or medical/patient status.
