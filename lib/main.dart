import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/upload_screen.dart';
import 'screens/sort_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/report_summary_screen.dart';
import 'viewmodels/app_viewmodel.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AppViewModel(),
      child: MaterialApp(
        title: 'Сборочный Лист',
        theme: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: const Color(0xFF1C1C1E),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF1C1C1E),
            elevation: 0,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4A4A4D),
              foregroundColor: Colors.white,
              textStyle: const TextStyle(fontSize: 16),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => const UploadScreen(),
          '/sort': (context) => const SortScreen(),
          '/settings': (context) => const SettingsScreen(),
          '/summary': (context) => const ReportSummaryScreen(),
        },
      ),
    );
  }
}
