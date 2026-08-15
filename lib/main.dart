import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'screens/splash_screen.dart';

void main() {
  // Binding must be initialized before accessing platform channels
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const DelhiveryApp());
}

class DelhiveryApp extends StatelessWidget {
  const DelhiveryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DELHIVERY',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const SplashScreen(),
    );
  }
}
