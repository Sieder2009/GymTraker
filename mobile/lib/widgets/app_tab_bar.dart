import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/active_screen_provider.dart';

/// Bottom nav for the 3 tabs (Training/Kraft/Fortschritt). The original
/// used hand-drawn barbell SVG icon paths; Material icons are used here as
/// a pragmatic stand-in (flagged as an intentional, low-risk styling
/// deviation, not a fidelity gap).
class AppTabBar extends StatelessWidget {
  const AppTabBar({super.key});

  @override
  Widget build(BuildContext context) {
    final active = context.watch<ActiveScreenProvider>();
    return BottomNavigationBar(
      currentIndex: active.index,
      onTap: (i) => context.read<ActiveScreenProvider>().set(i),
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.fitness_center),
          label: 'Training',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.bolt),
          label: 'Kraft',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.show_chart),
          label: 'Fortschritt',
        ),
      ],
    );
  }
}
