import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'firebase_emulator_config.dart';
import 'firebase_options.dart';

import 'screens/role_select_screen.dart';
import 'services/app_navigation_state.dart';
import 'widgets/app_navigation_shell.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    if (useFirebaseEmulators) {
      await FirebaseAuth.instance.useAuthEmulator(firebaseEmulatorHost, 9099);
      FirebaseFirestore.instance.useFirestoreEmulator(
        firebaseEmulatorHost,
        8086,
      );
      FirebaseStorage.instance.useStorageEmulator(firebaseEmulatorHost, 9199);
      FirebaseFunctions.instanceFor(
        region: 'us-central1',
      ).useFunctionsEmulator(firebaseEmulatorHost, 5001);
    }
    runApp(const MyApp());
  } catch (error) {
    runApp(FirebaseInitFailureApp(error: error));
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: appNavigatorKey,
      scaffoldMessengerKey: appScaffoldMessengerKey,
      debugShowCheckedModeBanner: false,
      title: 'AyurVedaCare',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const RoleSelectScreen(),
      builder: (context, child) => Overlay(
        initialEntries: [
          OverlayEntry(
            builder: (_) => AppNavigationShell(
              navigatorKey: appNavigatorKey,
              child: child ?? const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }
}

class FirebaseInitFailureApp extends StatelessWidget {
  final Object error;

  const FirebaseInitFailureApp({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(child: Text('Firebase initialization failed: $error')),
      ),
    );
  }
}
