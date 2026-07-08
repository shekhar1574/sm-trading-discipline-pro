import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'presentation/providers/dashboard_provider.dart';
import 'presentation/providers/journal_provider.dart';
import 'presentation/screens/dashboard_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SMTradingDisciplineApp());
}

class SMTradingDisciplineApp extends StatelessWidget {
  const SMTradingDisciplineApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => JournalProvider()),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.dark,
        home: const DashboardScreen(),
      ),
    );
  }
}
