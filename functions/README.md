# Admin login testing and deployment

The admin login screen has both secret-name and secret-key fields. The secret
name is prefilled with `uwuict`. In local Firebase Emulator testing, the key
`00000` is accepted and prefilled. This test key is accepted only by the
Functions Emulator and is rejected by deployed functions. The Flutter emulator
mode also routes Auth, Firestore, Functions, and Storage to local emulators, so
test sign-ins and data do not access production Firebase.

## Local testing

From the project root, start the emulators:

```powershell
firebase emulators:start --only auth,functions,firestore,storage --project demo-ayurvedic
```

In another terminal, run the Flutter app with emulator mode enabled:

```powershell
flutter run --dart-define=USE_FIREBASE_EMULATORS=true --dart-define=FIREBASE_EMULATOR_HOST=127.0.0.1
```

For an Android emulator, use `10.0.2.2` as the host instead of `127.0.0.1`.
This mode is debug-build-only; do not use the emulator define in a release
build.

## Production deployment

The deployed function requires a private key of at least 32 UTF-8 bytes, stored
in Firebase Secret Manager. The key is not stored in the app or repository.
The function limits repeated failed attempts by source IP.

1. Select the Firebase project with `firebase use`.
2. Generate a private key locally with:

   ```powershell
   node -p "require('node:crypto').randomBytes(32).toString('base64url')"
   ```

3. Run `firebase functions:secrets:set ADMIN_LOGIN_SECRET` and enter the
   generated value at the secure prompt. Do not commit or share the key.
4. Deploy the function and its supporting rules:

   ```powershell
   firebase deploy --only functions:adminLogin,firestore:rules
   ```

Cloud Functions deployment requires a Firebase project with billing enabled.
