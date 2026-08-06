import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'services/storage_service.dart';
import 'state/active_screen_provider.dart';
import 'state/big_lifts_provider.dart';
import 'state/programs_provider.dart';
import 'state/theme_provider.dart';
import 'state/toast_provider.dart';
import 'state/train_state_provider.dart';
import 'theme/app_theme.dart';
import 'widgets/app_shell.dart';

/// Root widget: one [MultiProvider] above one [MaterialApp]/[Navigator] —
/// every pushed overlay route stays a descendant of this provider tree, so
/// it can read/watch the same app-wide state as the 3 tab screens.
class IronpeakApp extends StatelessWidget {
  const IronpeakApp({super.key, required this.storage});

  final StorageService storage;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider(storage)),
        ChangeNotifierProvider(create: (_) => ProgramsProvider(storage)),
        ChangeNotifierProvider(create: (_) => TrainStateProvider(storage)),
        ChangeNotifierProvider(create: (_) => BigLiftsProvider(storage)),
        ChangeNotifierProvider(create: (_) => ActiveScreenProvider()),
        ChangeNotifierProvider(create: (_) => ToastProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, theme, _) {
          return MaterialApp(
            title: 'Ironpeak Fitness',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: theme.isDark ? ThemeMode.dark : ThemeMode.light,
            home: const AppShell(),
          );
        },
      ),
    );
  }
}
