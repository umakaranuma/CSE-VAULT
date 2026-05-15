import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'theme/app_colors.dart';
import 'providers/portfolio_provider.dart';
import 'models/models.dart';
import 'screens/main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Initialize Hive ──
  await Hive.initFlutter();
  Hive.registerAdapter(TransactionAdapter());
  Hive.registerAdapter(PriceLogAdapter());
  Hive.registerAdapter(StockAdapter());
  await Hive.openBox<Stock>('stocks');

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PortfolioProvider()..loadFromHive()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CSE Portfolio',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.bg,
        textTheme: GoogleFonts.plusJakartaSansTextTheme(
          ThemeData.dark().textTheme,
        ).apply(
          bodyColor: AppColors.text,
          displayColor: AppColors.text,
        ),
        colorScheme: const ColorScheme.dark(
          primary: AppColors.em,
          secondary: AppColors.blue,
          background: AppColors.bg,
          surface: AppColors.s1,
        ),
      ),
      home: const MainScreen(),
    );
  }
}
