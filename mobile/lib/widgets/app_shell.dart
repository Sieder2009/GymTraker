import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../screens/progress_screen.dart';
import '../screens/strength_screen.dart';
import '../screens/training_screen.dart';
import '../state/active_screen_provider.dart';
import 'app_tab_bar.dart';
import 'toast_overlay.dart';

/// Root shell: the 3 tabs stay mounted simultaneously via [IndexedStack]
/// (matches the original's always-mounted `.screen` sections, just
/// cross-faded via CSS) so switching tabs never loses scroll/local state.
class AppShell extends StatelessWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context) {
    final active = context.watch<ActiveScreenProvider>().index;
    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(
            index: active,
            children: const [
              TrainingScreen(),
              StrengthScreen(),
              ProgressScreen(),
            ],
          ),
          const ToastOverlay(),
        ],
      ),
      bottomNavigationBar: const AppTabBar(),
    );
  }
}
