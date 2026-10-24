import 'package:flutter/foundation.dart';

const bool useFirebaseEmulators =
    kDebugMode && bool.fromEnvironment('USE_FIREBASE_EMULATORS');
const String firebaseEmulatorHost = String.fromEnvironment(
  'FIREBASE_EMULATOR_HOST',
  defaultValue: '127.0.0.1',
);
