import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../screens/exercises_screen.dart';
import '../screens/progress_screen.dart';
import '../screens/strength_screen.dart';
import '../screens/training_screen.dart';
import '../state/active_screen_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import 'app_tab_bar.dart';
import 'toast_overlay.dart';

/// Root shell: the 3 tabs stay mounted simultaneously via [IndexedStack]
/// (matches the original's always-mounted `.screen` sections, just
/// cross-faded via CSS) so switching tabs never loses scroll/local state.
///
/// The nav bar floats over the content (margin + rounded pill + shadow)
/// rather than docking flush to the screen edge — screens add their own
/// bottom padding (see [kFloatingNavClearance]) so content never sits
/// underneath it.
class AppShell extends StatelessWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context) {
    final active = context.watch<ActiveScreenProvider>().index;
    final colors = Theme.of(context).extension<AppColors>()!;
    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(
            index: active,
            children: const [
              TrainingScreen(),
              StrengthScreen(),
              ProgressScreen(),
              ExercisesScreen(),
            ],
          ),
          const ToastOverlay(),
          Positioned(
            left: 20,
            right: 20,
            bottom: 16,
            child: SafeArea(
              top: false,
              child: Container(
                decoration: BoxDecoration(
                  color: colors.card,
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                  border: Border.all(color: colors.line),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.16),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: const AppTabBar(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bottom padding every scrollable screen needs so its last item clears the
/// floating nav bar — one shared constant instead of a magic number guessed
/// independently in each screen's `ListView` padding.
const double kFloatingNavClearance = 96;
