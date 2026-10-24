import 'package:flutter/material.dart';

final ValueNotifier<bool> appNavigationEnabled = ValueNotifier<bool>(false);
final GlobalKey<ScaffoldMessengerState> appScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();
