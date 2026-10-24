import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../screens/dashboard/admin.dart';
import '../screens/dashboard/doctor.dart';
import '../screens/marketplace/app_feedback_page.dart';
import '../screens/dashboard/patient.dart';
import '../screens/dashboard/seller.dart';
import '../screens/home/home.dart';
import '../screens/role_select_screen.dart';
import '../services/app_navigation_state.dart';

class AppNavigationShell extends StatefulWidget {
  final Widget child;
  final GlobalKey<NavigatorState> navigatorKey;

  const AppNavigationShell({
    super.key,
    required this.child,
    required this.navigatorKey,
  });

  @override
  State<AppNavigationShell> createState() => _AppNavigationShellState();
}

class _AppNavigationShellState extends State<AppNavigationShell> {
  StreamSubscription<User?>? _authSubscription;
  String? _userId;
  String? _role;
  bool _visible = true;
  int _selectedIndex = 0;
  bool _navigationEnabled = appNavigationEnabled.value;

  @override
  void initState() {
    super.initState();
    appNavigationEnabled.addListener(_onNavigationStateChanged);
    if (Firebase.apps.isNotEmpty) {
      _authSubscription = FirebaseAuth.instance.authStateChanges().listen(
        _onAuthChanged,
      );
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    appNavigationEnabled.removeListener(_onNavigationStateChanged);
    super.dispose();
  }

  void _onNavigationStateChanged() {
    if (_navigationEnabled == appNavigationEnabled.value || !mounted) return;
    setState(() => _navigationEnabled = appNavigationEnabled.value);
  }

  Future<void> _onAuthChanged(User? user) async {
    if (!mounted) return;
    if (user == null) {
      appNavigationEnabled.value = false;
      setState(() {
        _userId = null;
        _role = null;
      });
      return;
    }

    setState(() {
      _userId = user.uid;
      _role = null;
      _visible = true;
      _selectedIndex = 0;
    });
    try {
      final role = await _resolveRole(user.uid);
      if (!mounted || _userId != user.uid) return;
      setState(() => _role = role);
    } catch (error) {
      debugPrint('Could not resolve signed-in user role: $error');
    }
  }

  Future<String> _resolveRole(String userId) async {
    final token = await FirebaseAuth.instance.currentUser?.getIdTokenResult();
    if (token?.claims?['admin'] == true) return 'admin';

    final userDocument = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get();
    final storedRole = userDocument.data()?['role']?.toString().toLowerCase();

    for (final role in ['doctor', 'seller', 'patient']) {
      final document = await FirebaseFirestore.instance
          .collection('${role}s')
          .doc(userId)
          .get();
      if (document.exists) return role;
    }
    final sellerByUid = await FirebaseFirestore.instance
        .collection('sellers')
        .where('uid', isEqualTo: userId)
        .limit(1)
        .get();
    if (sellerByUid.docs.isNotEmpty) return 'seller';
    return storedRole == 'seller' || storedRole == 'doctor'
        ? storedRole!
        : 'patient';
  }

  void _onScroll(UserScrollNotification notification) {
    if (notification.metrics.axis != Axis.vertical ||
        notification.direction == ScrollDirection.idle) {
      return;
    }
    final shouldShow = notification.direction == ScrollDirection.forward;
    if (shouldShow != _visible && mounted) {
      setState(() => _visible = shouldShow);
    }
  }

  Color get _accentColor =>
      _role == 'seller' ? const Color(0xFFC59D3F) : const Color(0xFF24615E);

  void _openHome({int section = 0}) {
    final role = _role;
    if (role == null) return;
    setState(() => _selectedIndex = section);
    widget.navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (_) => HomePage(role: role, initialSection: section),
      ),
      (route) => false,
    );
  }

  void _openDashboard() {
    final role = _role;
    final userId = _userId;
    if (role == null || userId == null) return;
    appNavigationEnabled.value = true;
    setState(() => _selectedIndex = 3);
    final Widget dashboard = switch (role) {
      'doctor' => DoctorDashboardPage(doctorId: userId),
      'seller' => const SellerDashboard(),
      'admin' => const AdminDashboard(),
      _ => const PatientDashboardPage(),
    };
    widget.navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => dashboard),
      (route) => false,
    );
  }

  Future<void> _showMore() async {
    final overlayContext = widget.navigatorKey.currentState?.overlay?.context;
    if (overlayContext == null) return;
    await showModalBottomSheet<void>(
      context: overlayContext,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.rate_review_outlined),
              title: const Text('App feedback & review'),
              onTap: () {
                Navigator.pop(sheetContext);
                final role = _role;
                if (role == null) return;
                setState(() => _selectedIndex = 4);
                widget.navigatorKey.currentState?.push(
                  MaterialPageRoute<void>(
                    builder: (_) => AppFeedbackPage(role: role),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Log out'),
              onTap: () {
                Navigator.pop(sheetContext);
                _logout();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _logout() async {
    try {
      appNavigationEnabled.value = false;
      await FirebaseAuth.instance.signOut();
      widget.navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const RoleSelectScreen()),
        (route) => false,
      );
    } catch (error) {
      if (!mounted) return;
      appScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text('Could not log out: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    final showBar =
        _navigationEnabled && _userId != null && _role != null && !keyboardOpen;

    return NotificationListener<UserScrollNotification>(
      onNotification: (notification) {
        _onScroll(notification);
        return false;
      },
      child: Column(
        children: [
          Expanded(child: widget.child),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: showBar && _visible
                ? SafeArea(
                    top: false,
                    child: Material(
                      color: Colors.white,
                      elevation: 12,
                      child: NavigationBar(
                        height: 70,
                        backgroundColor: Colors.white,
                        indicatorColor: _accentColor.withValues(alpha: 0.12),
                        selectedIndex: _selectedIndex,
                        onDestinationSelected: (index) {
                          switch (index) {
                            case 0:
                              _openHome();
                              break;
                            case 1:
                              _openHome(section: 1);
                              break;
                            case 2:
                              _openHome(section: 2);
                              break;
                            case 3:
                              _openDashboard();
                              break;
                            case 4:
                              _showMore();
                              break;
                          }
                        },
                        destinations: const [
                          NavigationDestination(
                            icon: Icon(Icons.home_outlined),
                            selectedIcon: Icon(Icons.home),
                            label: 'Home',
                          ),
                          NavigationDestination(
                            icon: Icon(Icons.storefront_outlined),
                            selectedIcon: Icon(Icons.storefront),
                            label: 'Shop',
                          ),
                          NavigationDestination(
                            icon: Icon(Icons.calendar_month_outlined),
                            selectedIcon: Icon(Icons.calendar_month),
                            label: 'Booking',
                          ),
                          NavigationDestination(
                            icon: Icon(Icons.dashboard_outlined),
                            selectedIcon: Icon(Icons.dashboard),
                            label: 'Dashboard',
                          ),
                          NavigationDestination(
                            icon: Icon(Icons.more_horiz),
                            label: 'More',
                          ),
                        ],
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
